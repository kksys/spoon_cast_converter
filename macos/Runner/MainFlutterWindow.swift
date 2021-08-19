import Cocoa
import FlutterMacOS

//class CustomViewController: FlutterViewController {
//  override func mouseDown(with event: NSEvent) {
//    print("mouseDown")
//    super.mouseDown(with: event)
//    self.view.window?.performDrag(with: event)
//  }
//}

class MainFlutterWindow: NSWindow {
  var customToolbar: NSToolbar = NSToolbar()

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    customToolbar.sizeMode = .regular

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    super.awakeFromNib()
  }
  
  override func layoutIfNeeded() {
    super.layoutIfNeeded()
    
    if isFullScreen {
      self.toolbar = nil
    } else if self.toolbar == nil {
      self.toolbar = customToolbar
    }
  }
  
  private var isFullScreen: Bool {
    get {
      return self.styleMask.contains(.fullScreen)
    }
  }
}
