import AVFoundation
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    deactivateAudioSession()
  }

  override func sceneDidEnterBackground(_ scene: UIScene) {
    super.sceneDidEnterBackground(scene)
    deactivateAudioSession()
  }

  private func deactivateAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setActive(false)
      print("Audio session deactivated by SceneDelegate.")
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
  }
}
