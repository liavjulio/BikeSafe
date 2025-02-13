import UIKit
import Flutter
import GoogleMaps
import GoogleSignIn

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
        GMSServices.provideAPIKey(mapsApiKey)
    }

    if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}