import Cocoa
import FlutterMacOS

struct EnableWindowButtonArguments: Codable {
  let enabled: Bool
  let buttonType: String
}

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  var controller : FlutterViewController!;
  var MENU_CHANNEL : FlutterMethodChannel!;
  var TITLEBAR_BUTTON_CHANNEL : FlutterMethodChannel!;

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  @IBAction func showCheckForUpdatesDialog(_ sender: NSMenuItem){
    MENU_CHANNEL.invokeMethod("showCheckForUpdatesDialog", arguments: nil)
  }

  @IBAction func showLicenseDialog(_ sender: NSMenuItem){
    MENU_CHANNEL.invokeMethod("showLicenseDialog", arguments: nil)
  }

  private func enableWindowButton(styleMask: NSWindow.StyleMask, enabled: Bool) {
    if enabled {
      mainFlutterWindow.styleMask.insert(styleMask)
    } else {
      mainFlutterWindow.styleMask.remove(styleMask)
    }
  }

  private func methodCallback(_ method: FlutterMethodCall, _ result: FlutterResult) {
    switch (method.method) {
    case "enableWindowButton":
      if let jsonString = method.arguments as? String,
         let jsonData = jsonString.data(using: .utf8),
         let args = try? JSONDecoder().decode(EnableWindowButtonArguments.self, from: jsonData) {
        var styleMask: NSWindow.StyleMask

        switch args.buttonType {
        case "closable":
          styleMask = .closable
        case "resizable":
          styleMask = .resizable
        case "miniaturizable":
          styleMask = .miniaturizable
        default:
          return
        }

        self.enableWindowButton(styleMask: styleMask, enabled: args.enabled)
      }
      return
    default:
      return
    }
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    controller = mainFlutterWindow.contentViewController as? FlutterViewController
    MENU_CHANNEL = FlutterMethodChannel(
      name: "net.kk_systems.spoonCastConverter.menu",
      binaryMessenger: controller.engine.binaryMessenger
    )
    TITLEBAR_BUTTON_CHANNEL = FlutterMethodChannel(
      name: "net.kk_systems.spoonCastConverter.titlebar_button_lib",
      binaryMessenger: controller.engine.binaryMessenger
    )
    TITLEBAR_BUTTON_CHANNEL.setMethodCallHandler(methodCallback)
    return super.applicationDidFinishLaunching(notification)
  }
}
