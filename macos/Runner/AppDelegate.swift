import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  var controller : FlutterViewController!;
  var MENU_CHANNEL : FlutterMethodChannel!;

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  @IBAction func showCheckForUpdatesDialog(_ sender: NSMenuItem){
    MENU_CHANNEL.invokeMethod("showCheckForUpdatesDialog", arguments: nil)
  }

  @IBAction func showLicenseDialog(_ sender: NSMenuItem){
    MENU_CHANNEL.invokeMethod("showLicenseDialog", arguments: nil)
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    controller = mainFlutterWindow.contentViewController as? FlutterViewController
    MENU_CHANNEL = FlutterMethodChannel(
      name: "net.kk_systems.spoonCastConverter.menu",
      binaryMessenger: controller.engine.binaryMessenger
    )
  }
}
