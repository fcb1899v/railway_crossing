import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_manager.dart';
import 'photo_manager.dart';
import 'common_extension.dart';
import 'common_function.dart';
import 'constant.dart';
import 'main.dart';

/// Photo Button Widget - Handles photo capture and display functionality
class PhotoButton extends HookConsumerWidget {
  const PhotoButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    /// ===== PROVIDER STATE MANAGEMENT =====
    // Watch provider states for reactive updates
    final countryNumber = ref.watch(countryProvider);
    final tickets = ref.watch(ticketsProvider);
    final currentDate = ref.watch(currentProvider);
    final lastClaimedDate = ref.watch(lastClaimedProvider);
    final isLoading = ref.watch(loadingProvider);

    /// ===== PHOTO STATE VARIABLES =====
    // Photo-related state variables for permission and lifecycle management
    final photoPermission = useState(PermissionStatus.denied);
    final lifecycle = useAppLifecycleState();

    /// ===== ANIMATION CONTROLLERS =====
    // Animation controllers for camera button blinking effect
    final blinkController = useAnimationController(
      duration: const Duration(milliseconds: 1000),
    );
    final blinkAnimation = useAnimation(
      Tween<double>(begin: 1.0, end: (tickets > 0 || !lastClaimedDate.isToday(currentDate)) ? 0.0: 1.0).animate(
        CurvedAnimation(
          parent: blinkController,
          curve: Curves.linear,
        ),
      ),
    );

    /// ===== MANAGER INITIALIZATION =====
    // Initialize managers and widgets for audio and photo functionality
    final audioManager = useMemoized(() => AudioManager());
    final photoManager = useMemoized(() => PhotoManager(
      context: context,
      currentDate: currentDate,
    ));
    final photo = PhotoWidget(
      context: context,
      countryNumber: countryNumber,
      tickets: tickets,
      currentDate: currentDate,
      lastClaimedDate: lastClaimedDate,
    );

    /// ===== APP LIFECYCLE MANAGEMENT =====
    // Handle app lifecycle changes (pause, resume) to stop audio
    useEffect(() {
      Future<void> handleLifecycleChange() async {
        if (!context.mounted) return;
        if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
          try {
            await audioManager.stopAll();
            blinkController.stop();
          } catch (e) {
            'Error handling stop for player: $e'.debugPrint();
          }
        }
      }
      handleLifecycleChange();
      return null;
    }, [lifecycle, context.mounted]);

    /// ===== PERMISSION INITIALIZATION =====
    // Initialize app with photo permissions
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        photoPermission.value = await photoManager.permitPhotoAccess();
        blinkController.repeat(reverse: true);
      });
      return null;
    }, const []);

    /// ===== PHOTO GENERATION METHODS =====
    // Get free photo (daily limit) - Uses daily free photo allocation
    Future<void> getFreePhoto() async {
      "getFreePhoto".debugPrint();
      try {
        final photoResult = await photoManager.getFreePhoto(countryNumber);
        ref.read(photoProvider.notifier).state = photoResult;
        if (photoResult.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final newCurrentDate = await getServerDateTime();
          'lastClaim'.setSharedPrefInt(prefs, newCurrentDate);
          ref.read(lastClaimedProvider.notifier).state = newCurrentDate;
          ref.read(currentProvider.notifier).state = newCurrentDate;
        } else {
          "Free photo error".debugPrint();
        }
      } catch (e) {
        "Free photo error: $e".debugPrint();
      }
    }

    // Get AI-generated photo (uses tickets) - Consumes one ticket per photo
    Future<void> getGenerativeAIPhoto() async {
      try {
        "getGenerativeAIPhoto".debugPrint();
        final aiPhoto = await photoManager.getGenerativeAIPhoto(countryNumber);
        "photoImage: $aiPhoto".debugPrint();
        if (aiPhoto.isNotEmpty) {
          ref.read(photoProvider.notifier).state = aiPhoto;
          final prefs = await SharedPreferences.getInstance();
          final newTickets = tickets - 1;
          ref.read(ticketsProvider.notifier).state = newTickets;
          'tickets'.setSharedPrefInt(prefs, newTickets);
        } else {
          "Generative AI photo error: empty result".debugPrint();
        }
      } catch (e) {
        "Generative AI photo error: $e".debugPrint();
      }
    }
    
    /// ===== CAMERA ACTION HANDLER =====
    // Handle camera button tap - Manages photo capture logic and permissions
    cameraAction() async {
      if (photoPermission.value != PermissionStatus.granted) {
        "Photo permission".debugPrint();
        photoPermission.value = await photoManager.permitPhotoAccess();
      } else {
        "Camera action".debugPrint();
        final newCurrentDate = await getServerDateTime();
        if (tickets > 0 || !lastClaimedDate.isToday(newCurrentDate)) {
          ref.read(loadingProvider.notifier).state = true;
          await audioManager.playEffectSound(cameraSound);
          try {
            if (!lastClaimedDate.isToday(newCurrentDate)) {
              await getFreePhoto();
            } else if (tickets > 0) {
              await getGenerativeAIPhoto();
            }
          } catch (e) {
            "Camera action error: $e".debugPrint();
          } finally {
            ref.read(loadingProvider.notifier).state = false;
            "isLoading: $isLoading".debugPrint();
          }
        }
      }
    }
    return photo.cameraButton(
      onTap: () => cameraAction(),
      animation: blinkAnimation,
    );
  }
}

/// Photo Widget - UI components for photo functionality
class PhotoWidget {

  /// ===== WIDGET PROPERTIES =====
  final BuildContext context;
  final int countryNumber;
  final int tickets;
  final int currentDate;
  final int lastClaimedDate;

  PhotoWidget({
    required this.context,
    required this.countryNumber,
    required this.tickets,
    required this.currentDate,
    required this.lastClaimedDate,
  });

  /// ===== CAMERA UI COMPONENTS =====
  /// Camera Button Widget - Floating action button for photo capture
  Widget cameraButton({
    required void Function() onTap,
    required double animation,
  }) => Container(
    alignment: Alignment.topRight,
    margin: EdgeInsets.symmetric(
      horizontal: context.fabSideMargin(),
      vertical: context.fabTopMargin(),
    ),
    child: GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: animation < 0.2 ? 0.0 : 1.0,
        child: cameraButtonImage(),
      ),
    ),
  );

  /// Camera Button Image with Icon and Text - Displays camera icon and remaining shots
  Widget cameraButtonImage() => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: context.fabSize(),
        height: context.fabSize(),
        decoration: BoxDecoration(
          color: transpBlackColor,
          shape: BoxShape.circle,
          border: Border.all(color: (lastClaimedDate.isToday(currentDate) && tickets == 0) ? grayColor: whiteColor,
            width: context.fabBorderWidth(),
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: context.cameraIconTopMargin(),
            bottom: context.cameraIconBottomMargin()
          ),
          child: Icon(Icons.camera_alt_outlined,
            color: (lastClaimedDate.isToday(currentDate) && tickets == 0) ? grayColor: whiteColor,
            size: context.cameraIconSize(),
          ),
        ),
      ),
      Container(
        margin: EdgeInsets.only(top: context.cameraTextTopMargin()),
        child: Text(context.photoShots(currentDate, lastClaimedDate, tickets),
          style: TextStyle(
            fontSize: context.cameraTextFontSize(),
            fontWeight: FontWeight.bold,
            color: (lastClaimedDate.isToday(currentDate) && tickets == 0) ? grayColor: whiteColor
          ),
        ),
      ),
    ]
  );
}