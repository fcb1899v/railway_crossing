// Ticket sync: tickets + ad-free expiration in SharedPreferences + Firestore, keyed by
// Game Center / Play Games PlayerID. Lookup: player doc -> device doc -> new; writes to both.

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'common_extension.dart';
import 'common_function.dart';
import 'constant.dart';

/// SharedPreferences keys for ticket sync.
const ticketPlayerIdKey = 'ticketPlayerId';
const ticketSyncPromptHiddenKey = 'ticketSyncPromptHidden';
const ticketDeviceIdKey = 'ticketDeviceId';
const ticketUpdatedAtMsKey = 'ticketUpdatedAtMs';
const ticketCloudCheckedKey = 'ticketCloudChecked';
const ticketSyncPendingKey = 'ticketSyncPendingAfterSettings';
const ticketGamesSignInAttemptDateKey = 'ticketGamesSignInAttemptDate';
const ticketSyncPromptShownDateKey = 'ticketSyncPromptShownDate';

const _ticketCollection = 'tickets';
const _settingsChannel = MethodChannel('railway_crossing/settings');

class TicketSnapshot {
  final int tickets;
  final int expiration;
  final int lastClaimed;
  final bool isGamesSignedIn;

  const TicketSnapshot({
    required this.tickets,
    required this.expiration,
    required this.lastClaimed,
    required this.isGamesSignedIn,
  });
}

/// Outcome of [TicketManager.ensureGamesSignedInOncePerDay].
class GamesSignInOutcome {
  final String? playerId;
  final bool signInWasAttempted;

  const GamesSignInOutcome({
    required this.playerId,
    required this.signInWasAttempted,
  });

  bool get isSignedIn => playerId != null;
}

/// Result of a Firestore get: [ok] means the request finished; [data] null means missing.
class _DocRead {
  final bool ok;
  final Map<String, dynamic>? data;

  const _DocRead.success(this.data) : ok = true;
  const _DocRead.failure() : ok = false, data = null;
}

/// Chosen tickets / expiration / lastClaimed / updatedAtMs after local-vs-cloud resolve.
class _ResolvedTickets {
  final int tickets;
  final int expiration;
  final int lastClaimed;
  final int updatedAtMs;

  const _ResolvedTickets({
    required this.tickets,
    required this.expiration,
    required this.lastClaimed,
    required this.updatedAtMs,
  });
}

class TicketManager {
  TicketManager();

  final _firestore = FirebaseFirestore.instance;

  // Platform label used in Firestore document IDs.
  String get _platformTag =>
      (Platform.isIOS || Platform.isMacOS) ? 'ios' : 'android';

  // Returns a cached, Firestore-safe device ID for provisional progress docs.
  Future<String> stableDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(ticketDeviceIdKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final raw = await _readPlatformDeviceId();
    final sanitized = _sanitizeDocId(raw);
    await prefs.setString(ticketDeviceIdKey, sanitized);
    return sanitized;
  }

  // Reads a best-effort native device identifier (Vendor ID / build fingerprint).
  Future<String> _readPlatformDeviceId() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final id = '${info.fingerprint}_${info.id}';
        if (id.trim().isNotEmpty) return id;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final info = await plugin.iosInfo;
        final id = info.identifierForVendor;
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (e) {
      'Failed to read device id: $e'.debugPrint();
    }
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Sanitizes a raw ID so it can be used as a Firestore document ID.
  String _sanitizeDocId(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (cleaned.isEmpty) {
      return 'unknown';
    }
    return cleaned.length > 120 ? cleaned.substring(0, 120) : cleaned;
  }

  // Builds the provisional device-scoped Firestore document ID.
  String deviceDocId(String deviceId) =>
      'device_${_platformTag}_$deviceId';

  // Builds the Game Center / Play Games player-scoped Firestore document ID.
  String playerDocId(String playerId) =>
      'player_${_platformTag}_${_sanitizeDocId(playerId)}';

  // Local calendar day as yyyyMMdd for once-per-day games sign-in.
  int _todayLocalIntDate() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  Future<bool> _alreadyAttemptedGamesSignInToday() async {
    final prefs = await SharedPreferences.getInstance();
    return ticketGamesSignInAttemptDateKey.getSharedPrefInt(prefs, 0) ==
        _todayLocalIntDate();
  }

  Future<void> _markGamesSignInAttemptedToday() async {
    final prefs = await SharedPreferences.getInstance();
    ticketGamesSignInAttemptDateKey.setSharedPrefInt(
      prefs,
      _todayLocalIntDate(),
    );
  }

  Future<bool> _alreadyShownSyncPromptToday() async {
    final prefs = await SharedPreferences.getInstance();
    return ticketSyncPromptShownDateKey.getSharedPrefInt(prefs, 0) ==
        _todayLocalIntDate();
  }

  Future<void> _markSyncPromptShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    ticketSyncPromptShownDateKey.setSharedPrefInt(
      prefs,
      _todayLocalIntDate(),
    );
  }

  Future<void> _clearCachedPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ticketPlayerIdKey);
  }

  // Reads the current Game Center / Play Games session (never shows sign-in UI).
  // Call on launch, resume, pull, and before push (purchase / spend / daily claim).
  Future<String?> resolveGamePlayerId() async {
    try {
      final signedIn =
          await GameAuth.isSignedIn.timeout(gamesSignInTimeout);
      if (!signedIn) {
        'Games services not signed in'.debugPrint();
        await _clearCachedPlayerId();
        return null;
      }
      final playerId =
          await Player.getPlayerID().timeout(gamesSignInTimeout);
      if (playerId == null || playerId.isEmpty) {
        'Games services player id empty'.debugPrint();
        await _clearCachedPlayerId();
        return null;
      }
      'Games services player id ready (length=${playerId.length})'.debugPrint();
      final prefs = await SharedPreferences.getInstance();
      ticketPlayerIdKey.setSharedPrefString(prefs, playerId);
      return playerId;
    } on TimeoutException catch (e) {
      'Games services player id timed out: $e'.debugPrint();
      return null;
    } catch (e) {
      'Games services player id failed: $e'.debugPrint();
      return null;
    }
  }

  // Cached Play Games / Game Center player ID from SharedPreferences.
  Future<String?> cachedGamePlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString(ticketPlayerIdKey);
    if (playerId == null || playerId.isEmpty) return null;
    return playerId;
  }

  /// Requests Game Center / Play Games sign-in UI at most once per local day, then
  /// always re-checks the current session (no UI). Call from homepage launch / resume only.
  Future<GamesSignInOutcome> ensureGamesSignedInOncePerDay() async {
    var signInWasAttempted = false;
    try {
      if (!await _alreadyAttemptedGamesSignInToday()) {
        'Games services sign-in attempt (once per day)'.debugPrint();
        signInWasAttempted = true;
        await GameAuth.signIn().timeout(gamesSignInTimeout);
        await _markGamesSignInAttemptedToday();
      }
    } on TimeoutException catch (e) {
      'Games services sign-in timed out: $e'.debugPrint();
      await _markGamesSignInAttemptedToday();
    } catch (e) {
      'Games services sign-in failed: $e'.debugPrint();
      await _markGamesSignInAttemptedToday();
    }
    final playerId = await resolveGamePlayerId();
    return GamesSignInOutcome(
      playerId: playerId,
      signInWasAttempted: signInWasAttempted,
    );
  }

  // Whether the user chose not to see the restore sync prompt again.
  Future<bool> isSyncPromptHidden() async {
    final prefs = await SharedPreferences.getInstance();
    return ticketSyncPromptHiddenKey.getSharedPrefBool(prefs, false);
  }

  // Persists the "do not show again" flag for the restore sync prompt.
  Future<void> setSyncPromptHidden(bool hidden) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ticketSyncPromptHiddenKey, hidden);
    'ticketSyncPromptHidden: $hidden'.debugPrint();
  }

  // Whether we should re-pull after the user returns from OS games settings.
  Future<bool> isSyncPending() async {
    final prefs = await SharedPreferences.getInstance();
    return ticketSyncPendingKey.getSharedPrefBool(prefs, false);
  }

  // Marks that sync should be retried when the app resumes from settings.
  Future<void> setSyncPending(bool pending) async {
    final prefs = await SharedPreferences.getInstance();
    ticketSyncPendingKey.setSharedPrefBool(prefs, pending);
  }

  /// URLs that open Settings > Game Center when possible; Settings home as fallback.
  /// iOS schemes are case-sensitive here, so they are launched as raw strings.
  List<String> get _systemSettingsHomeUrls => (Platform.isIOS || Platform.isMacOS)
      ? [
          'App-prefs:root=GAMECENTER',
          'App-Prefs:root=GAMECENTER',
          'prefs:root=GAMECENTER',
          'App-prefs:GAMECENTER',
          'App-Prefs:GAMECENTER',
          'App-prefs:',
          'App-Prefs:',
          'prefs:',
        ]
      : const [];

  // Opens Play Games (Android) or Game Center settings (iOS).
  Future<bool> openGamesAccountSettings() async {
    if (Platform.isAndroid) {
      try {
        final opened =
            await _settingsChannel.invokeMethod<bool>('openPlayGames');
        if (opened == true) return true;
      } catch (e) {
        'Android Play Games open failed: $e'.debugPrint();
      }
    }

    for (final url in _systemSettingsHomeUrls) {
      try {
        final launched = await UrlLauncherPlatform.instance.launchUrl(
          url,
          const LaunchOptions(mode: PreferredLaunchMode.externalApplication),
        );
        if (launched) return true;
      } catch (e) {
        'System settings URL failed ($url): $e'.debugPrint();
      }
    }
    'Failed to open games account settings'.debugPrint();
    return false;
  }

  // Whether Firestore ticket was successfully checked at least once on this install.
  Future<bool> isCloudChecked() async {
    final prefs = await SharedPreferences.getInstance();
    return ticketCloudCheckedKey.getSharedPrefBool(prefs, false);
  }

  // Marks that a Firestore ticket read completed successfully.
  Future<void> setCloudChecked(bool checked) async {
    final prefs = await SharedPreferences.getInstance();
    ticketCloudCheckedKey.setSharedPrefBool(prefs, checked);
  }

  // Loads local ticketUpdatedAtMs; 0 means not set yet.
  Future<int> _localUpdatedAtMs(SharedPreferences prefs) async {
    return ticketUpdatedAtMsKey.getSharedPrefInt(prefs, 0);
  }

  // Loads a ticket document; failure vs missing are distinguished.
  Future<_DocRead> _readDoc(String docId) async {
    try {
      final snap =
          await _firestore.collection(_ticketCollection).doc(docId).get();
      if (!snap.exists || snap.data() == null) {
        return const _DocRead.success(null);
      }
      return _DocRead.success(snap.data());
    } catch (e) {
      'Ticket doc read failed ($docId): $e'.debugPrint();
      return const _DocRead.failure();
    }
  }

  // Extracts ticket count from a ticket document (defaults to 0).
  int _ticketsFrom(Map<String, dynamic>? data) {
    final value = data?['tickets'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  // Extracts ad-free expiration from a ticket document (defaults to app default).
  int _expirationFrom(Map<String, dynamic>? data) {
    final value = data?['expiration'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return defaultIntDateTime;
  }

  // Extracts daily free-claim timestamp (defaults to app default).
  int _lastClaimedFrom(Map<String, dynamic>? data) {
    final value = data?['lastClaimed'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return defaultIntDateTime;
  }

  // Extracts client updatedAtMs from a ticket document (0 if missing).
  int _updatedAtMsFrom(Map<String, dynamic>? data) {
    final value = data?['updatedAtMs'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  // Writes tickets, expiration, lastClaimed, and updatedAtMs to one Firestore ticket document.
  Future<void> _writeDoc({
    required String docId,
    required int tickets,
    required int expiration,
    required int lastClaimed,
    required int updatedAtMs,
  }) async {
    await _firestore.collection(_ticketCollection).doc(docId).set({
      'tickets': tickets,
      'expiration': expiration,
      'lastClaimed': lastClaimed,
      'platform': _platformTag,
      'updatedAtMs': updatedAtMs,
    }, SetOptions(merge: true));
  }

  // Writes the same ticket data to device doc and player doc (when playerId exists).
  Future<void> _writeBoth({
    required String deviceId,
    required String? playerId,
    required int tickets,
    required int expiration,
    required int lastClaimed,
    required int updatedAtMs,
  }) async {
    await _writeDoc(
      docId: deviceDocId(deviceId),
      tickets: tickets,
      expiration: expiration,
      lastClaimed: lastClaimed,
      updatedAtMs: updatedAtMs,
    );
    if (playerId != null && playerId.isNotEmpty) {
      await _writeDoc(
        docId: playerDocId(playerId),
        tickets: tickets,
        expiration: expiration,
        lastClaimed: lastClaimed,
        updatedAtMs: updatedAtMs,
      );
    }
  }

  // Chooses local vs cloud tickets using cloudChecked + updatedAtMs.
  // lastClaimed always takes the later timestamp, since the daily free claim is monotonic.
  _ResolvedTickets _resolveTickets({
    required bool cloudChecked,
    required int localTickets,
    required int localExpiration,
    required int localLastClaimed,
    required int localUpdatedAtMs,
    required Map<String, dynamic>? cloudData,
  }) {
    if (cloudData == null) {
      return _ResolvedTickets(
        tickets: localTickets,
        expiration: localExpiration,
        lastClaimed: localLastClaimed,
        updatedAtMs: localUpdatedAtMs,
      );
    }

    final cloudTickets = _ticketsFrom(cloudData);
    final cloudExpiration = _expirationFrom(cloudData);
    final cloudLastClaimed = _lastClaimedFrom(cloudData);
    final cloudUpdatedAtMs = _updatedAtMsFrom(cloudData);
    final mergedLastClaimed =
        localLastClaimed >= cloudLastClaimed ? localLastClaimed : cloudLastClaimed;

    // First successful cloud path: prefer cloud tickets; do not stamp "now".
    if (!cloudChecked || localUpdatedAtMs <= 0) {
      return _ResolvedTickets(
        tickets: cloudTickets,
        expiration: cloudExpiration,
        lastClaimed: mergedLastClaimed,
        updatedAtMs: cloudUpdatedAtMs,
      );
    }

    // After cloudChecked: newer updatedAtMs wins for tickets/expiration.
    if (localUpdatedAtMs >= cloudUpdatedAtMs) {
      return _ResolvedTickets(
        tickets: localTickets,
        expiration: localExpiration,
        lastClaimed: mergedLastClaimed,
        updatedAtMs: localUpdatedAtMs,
      );
    }
    return _ResolvedTickets(
      tickets: cloudTickets,
      expiration: cloudExpiration,
      lastClaimed: mergedLastClaimed,
      updatedAtMs: cloudUpdatedAtMs,
    );
  }

  // Pulls cloud tickets (player then device), merges by updatedAtMs, mirrors both docs.
  // Re-checks games session (no sign-in UI). Call [ensureGamesSignedInOncePerDay] for UI.
  Future<TicketSnapshot> pullAndMerge({
    required int localTickets,
    required int localExpiration,
    required int localLastClaimed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cloudChecked = await isCloudChecked();
    final localUpdatedAtMs = await _localUpdatedAtMs(prefs);

    try {
      await ensureFirebaseReady();
      final deviceId = await stableDeviceId();
      final playerId = await resolveGamePlayerId();

      Map<String, dynamic>? cloudData;
      var firestoreCheckCompleted = false;

      if (playerId != null) {
        final playerRead = await _readDoc(playerDocId(playerId));
        if (!playerRead.ok) {
          return TicketSnapshot(
            tickets: localTickets,
            expiration: localExpiration,
            lastClaimed: localLastClaimed,
            isGamesSignedIn: true,
          );
        }
        firestoreCheckCompleted = true;
        cloudData = playerRead.data;
      }

      if (cloudData == null) {
        final deviceRead = await _readDoc(deviceDocId(deviceId));
        if (!deviceRead.ok) {
          return TicketSnapshot(
            tickets: localTickets,
            expiration: localExpiration,
            lastClaimed: localLastClaimed,
            isGamesSignedIn: playerId != null,
          );
        }
        firestoreCheckCompleted = true;
        cloudData = deviceRead.data;
      }

      if (firestoreCheckCompleted) {
        await setCloudChecked(true);
      }

      final resolved = _resolveTickets(
        cloudChecked: cloudChecked,
        localTickets: localTickets,
        localExpiration: localExpiration,
        localLastClaimed: localLastClaimed,
        localUpdatedAtMs: localUpdatedAtMs,
        cloudData: cloudData,
      );

      // Prefer cloud/local resolved timestamp; only invent "now" when writing a first empty doc.
      var writeAtMs = resolved.updatedAtMs;
      if (writeAtMs <= 0) {
        writeAtMs = DateTime.now().millisecondsSinceEpoch;
      }

      'tickets'.setSharedPrefInt(prefs, resolved.tickets);
      'expiration'.setSharedPrefInt(prefs, resolved.expiration);
      'lastClaim'.setSharedPrefInt(prefs, resolved.lastClaimed);
      if (resolved.updatedAtMs > 0) {
        ticketUpdatedAtMsKey.setSharedPrefInt(prefs, resolved.updatedAtMs);
      } else if (cloudData != null) {
        // Restored/migrated from a doc without updatedAtMs: adopt write time once.
        ticketUpdatedAtMsKey.setSharedPrefInt(prefs, writeAtMs);
      }

      // Cloud mirror only while Play Games / Game Center is signed in.
      if (playerId != null) {
        await _writeBoth(
          deviceId: deviceId,
          playerId: playerId,
          tickets: resolved.tickets,
          expiration: resolved.expiration,
          lastClaimed: resolved.lastClaimed,
          updatedAtMs: writeAtMs,
        );
      } else {
        'Ticket cloud write skipped: games services not signed in'.debugPrint();
      }

      'Ticket pullAndMerge done tickets=${resolved.tickets} '
              'lastClaimed=${resolved.lastClaimed} '
              'player=${playerId != null} cloudChecked=$firestoreCheckCompleted'
          .debugPrint();

      return TicketSnapshot(
        tickets: resolved.tickets,
        expiration: resolved.expiration,
        lastClaimed: resolved.lastClaimed,
        isGamesSignedIn: playerId != null,
      );
    } catch (e) {
      'Ticket pullAndMerge failed; keeping local: $e'.debugPrint();
      final savedPlayerId =
          ticketPlayerIdKey.getSharedPrefString(prefs, '');
      return TicketSnapshot(
        tickets: localTickets,
        expiration: localExpiration,
        lastClaimed: localLastClaimed,
        isGamesSignedIn: savedPlayerId.isNotEmpty,
      );
    }
  }

  // Pushes local tickets/expiration/lastClaimed after purchase, spend, or daily claim.
  // Re-checks the games session first (no sign-in UI). Cloud write only when signed in.
  Future<void> pushProgress({
    required int tickets,
    required int expiration,
    required int lastClaimed,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      ticketUpdatedAtMsKey.setSharedPrefInt(prefs, updatedAtMs);
      'tickets'.setSharedPrefInt(prefs, tickets);
      'expiration'.setSharedPrefInt(prefs, expiration);
      'lastClaim'.setSharedPrefInt(prefs, lastClaimed);

      final playerId = await resolveGamePlayerId();
      if (playerId == null) {
        'Ticket push skipped: games services not signed in'.debugPrint();
        return;
      }

      await ensureFirebaseReady();
      final deviceId = await stableDeviceId();
      await _writeBoth(
        deviceId: deviceId,
        playerId: playerId,
        tickets: tickets,
        expiration: expiration,
        lastClaimed: lastClaimed,
        updatedAtMs: updatedAtMs,
      );
      'Ticket pushed tickets=$tickets lastClaimed=$lastClaimed '
              'updatedAtMs=$updatedAtMs'
          .debugPrint();
    } catch (e) {
      'Ticket push failed: $e'.debugPrint();
    }
  }

  // After returning from OS settings, pull again without UI feedback.
  Future<void> completePendingSyncIfNeeded({
    required Future<TicketSnapshot> Function() pull,
  }) async {
    if (!await isSyncPending()) return;
    await setSyncPending(false);
    await pull();
  }

  // Shows the restore prompt after today's Game Center / Play Games sign-in failed.
  // At most once per local day (also respects "do not show again").
  Future<void> showSyncPromptIfNeeded(BuildContext context) async {
    final hidden = await isSyncPromptHidden();
    if (hidden) return;
    if (await _alreadyShownSyncPromptToday()) return;
    // Both awaits precede the mounted check, so it still covers every gap up to showDialog.
    // Marking after the check would reopen one.
    await _markSyncPromptShownToday();
    if (!context.mounted) return;

    var doNotShowAgain = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.progressSyncTitle()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.progressSyncMessage(),
                    style: TextStyle(
                      fontSize: context.menuOtherSelectFontSize(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      setState(() => doNotShowAgain = !doNotShowAgain);
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: doNotShowAgain,
                          onChanged: (value) {
                            setState(() => doNotShowAgain = value ?? false);
                          },
                        ),
                        Expanded(
                          child: Text(
                            context.progressSyncDoNotShowAgain(),
                            style: TextStyle(
                              fontSize: context.menuOtherSelectFontSize(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                if (Platform.isIOS || Platform.isMacOS)
                  TextButton(
                    onPressed: () async {
                      // iOS: open Game Center settings. Android has no sync button.
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      final opened = await openGamesAccountSettings();
                      await setSyncPending(opened);
                    },
                    child: Text(
                      context.progressSyncOpenSettings(),
                      style: TextStyle(
                        fontSize: context.menuOtherSelectFontSize(),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () async {
                    // OK dismisses the alert; with checkbox, never show again.
                    if (doNotShowAgain) {
                      await setSyncPromptHidden(true);
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(
                    context.ok(),
                    style: TextStyle(
                      fontSize: context.menuOtherSelectFontSize(),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
