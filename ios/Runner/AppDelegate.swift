import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    GMSServices.provideAPIKey("AIzaSyAS30iPsbnEuwVMRiJMoqu_gfVROqvUabw") // <-- Add this line

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
