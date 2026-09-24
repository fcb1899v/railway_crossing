# railway_crossing_flutter (LETS CROSSING)

App-specific implementation notes only — things easy to miss even after reading the code.
Cross-app conventions are maintained separately and out of scope here.
Setup: `README.md`.
AI photo generation details: `functions/README.md`.

## App-specific notes

- **Do not remove `resolutionStrategy.force` in `android/app/build.gradle` without checking first.**
  It forces `androidx.datastore:*` to `1.2.1` (`android/app/build.gradle:103-116`).
  `shared_preferences` resolves datastore to `1.1.7` whether or not this force is present, and ELF-level analysis of the datastore native library found no reproducible defect at that version.
  Keep the force unless the dependency graph changes, or re-verify at the ELF level before removing it — do not remove it on the assumption the original 16KB-page-size risk was confirmed.

- **Ticket sync pairs a MethodChannel named `railway_crossing/settings` between Dart (`lib/ticket_manager.dart`) and Kotlin (`android/.../MainActivity.kt`).**
  The name is a duplicated literal string on each side, not shared from one constant.
  Changing it on only one side makes the "open Play Games settings" button fail silently and fall through to the next fallback (Play Store → system settings).

- **Ticket balance is written to Firestore only while signed in to Game Center / Play Games.**
  While signed out, it works local-only (`SharedPreferences`) and never writes to Firestore (`pushProgress` / `pullAndMerge` in `ticket_manager.dart`).
  It writes the same value to two documents, `player_{platform}_{playerId}` and `device_{platform}_{deviceId}`.
  On read, player takes priority with a device fallback, and whichever has the newer `updatedAtMs` wins.
  Preserve this dual-document layout and the `updatedAtMs` reconciliation when touching this sync path.
