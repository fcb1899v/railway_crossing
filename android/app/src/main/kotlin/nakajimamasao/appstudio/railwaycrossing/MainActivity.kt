package nakajimamasao.appstudio.railwaycrossing

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val settingsChannel = "railway_crossing/settings"
    private val playGamesPackage = "com.google.android.play.games"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, settingsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openPlayGames" -> {
                        result.success(openPlayGames())
                    }
                    "openSystemSettings" -> {
                        result.success(openSystemSettings())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Opens the Play Games app when installed; otherwise Play Store page, then Settings.
    private fun openPlayGames(): Boolean {
        try {
            val launchIntent = packageManager.getLaunchIntentForPackage(playGamesPackage)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launchIntent)
                return true
            }
        } catch (_: Exception) {
            // Fall through to Play Store / Settings.
        }

        try {
            val marketIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("market://details?id=$playGamesPackage"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(marketIntent)
            return true
        } catch (_: Exception) {
            // Fall through to system Settings.
        }

        return openSystemSettings()
    }

    private fun openSystemSettings(): Boolean {
        return try {
            startActivity(
                Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        // Avoid deprecated Window.setStatusBarColor/setNavigationBarColor on API 35+.
        // Edge-to-edge with transparent bars is default on Android 15 when targeting SDK 35.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && Build.VERSION.SDK_INT < 35) {
            @Suppress("DEPRECATION")
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            @Suppress("DEPRECATION")
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
        }
    }
}