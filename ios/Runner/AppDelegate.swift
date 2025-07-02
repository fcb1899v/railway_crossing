import UIKit
import Flutter
import AVFoundation
//import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    // Start event
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
//    let controller = window?.rootViewController as! FlutterViewController
//    let methodChannel = FlutterMethodChannel(
//        name: "nakajimamasao.appstudio.railwaycrossing/storefront", // Dartと同一の名前にする
//        binaryMessenger: controller.binaryMessenger
//    )
//    // GeneratedPluginRegistrant.register(with: self)呼び出し後でも可
      GeneratedPluginRegistrant.register(with: self)
//    methodChannel.setMethodCallHandler { (call, result) in
//        if call.method == "getStorefrontCountryCode" {
//            if #available(iOS 13.0, *) {
//                if let storefront = SKPaymentQueue.default().storefront {
//                    result(storefront.countryCode)
//                } else {
//                    result(nil)
//                }
//            } else {
//                result(nil)
//            }
//        } else {
//            result(FlutterMethodNotImplemented)
//        }
//    }
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Before background event
    override func applicationWillResignActive(_ application: UIApplication) {
      super.applicationWillResignActive(application)
      deactivateAudioSession()
    }

    // After background event
    override func applicationDidEnterBackground(_ application: UIApplication) {
      super.applicationDidEnterBackground(application)
      deactivateAudioSession()
    }

    private func deactivateAudioSession() {
      do {
        // AVAudioSession deactivated
        try AVAudioSession.sharedInstance().setActive(false)
        print("Audio session deactivated by AppDelegate.")
      } catch {
        print("Failed to deactivate audio session: \(error)")
      }
    }

}
