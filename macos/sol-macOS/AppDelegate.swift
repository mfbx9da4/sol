import Foundation
import Cocoa
import HotKey
import EventKit

let handledKeys: [UInt16] = [53, 126, 125, 36, 48]
let numberchars: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

  var mainWindow: Panel!
  var hotKey = HotKey(key: .space, modifiers: [.command])

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    hotKey.keyDownHandler = toggleWindow

    let jsCodeLocation: URL = RCTBundleURLProvider
        .sharedSettings()
        .jsBundleURL(forBundleRoot: "index", fallbackResource: "main")

    let rootView = RCTRootView(bundleURL: jsCodeLocation, moduleName: "sol", initialProperties: nil, launchOptions: nil)

    mainWindow = Panel(
      contentRect: NSRect(x: 0, y: 0, width: 750, height: 500),
      backing: .buffered, defer: false)

    let origin = CGPoint(x: 0, y: 0)
    let size = CGSize(width: 750, height: 500)
    let frame = NSRect(origin: origin, size: size)
    mainWindow.setFrame(frame, display: false)

    mainWindow.contentView!.addSubview(rootView)

    rootView.translatesAutoresizingMaskIntoConstraints = false
    rootView.topAnchor.constraint(equalTo: mainWindow.contentView!.topAnchor).isActive = true
    rootView.leadingAnchor.constraint(equalTo: mainWindow.contentView!.leadingAnchor).isActive = true
    rootView.trailingAnchor.constraint(equalTo: mainWindow.contentView!.trailingAnchor).isActive = true
    rootView.bottomAnchor.constraint(equalTo: mainWindow.contentView!.bottomAnchor).isActive = true

    NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
      let metaPressed = $0.modifierFlags.contains(.command)
      SolEmitter.sharedInstance.keyDown(key: $0.characters, keyCode: $0.keyCode, meta: metaPressed)

      if handledKeys.contains($0.keyCode) {
        return nil
      }

      if metaPressed && $0.characters != nil && numberchars.contains($0.characters!) {
        return nil
      }

      return $0
    }

    NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
      if $0.modifierFlags.contains(.command) {
        SolEmitter.sharedInstance.keyDown(key: "command", keyCode: 55, meta: true)
      } else {
        SolEmitter.sharedInstance.keyUp(key: "command", keyCode: 55, meta: false)
      }

      return $0
    }

    showWindow()
  }

  func toggleWindow() {
    if mainWindow != nil && mainWindow.isKeyWindow {
      hideWindow()
    } else {
      showWindow()
    }
  }

  func showWindow() {
    mainWindow.setIsVisible(false)
    mainWindow.center()

    mainWindow.makeKeyAndOrderFront(self)

    mainWindow.setIsVisible(true)

    SolEmitter.sharedInstance.onShow()

    NSCursor.setHiddenUntilMouseMoves(true)
  }

  func hideWindow() {
    mainWindow.orderOut(self)
    NSCursor.unhide()
    SolEmitter.sharedInstance.onHide()
  }

  func setGlobalShortcut(_ key: String) {
    self.hotKey.isPaused = true
    if key == "command" {
      self.hotKey = HotKey(key: .space, modifiers: [.command], keyDownHandler: toggleWindow)
    } else {
      self.hotKey = HotKey(key: .space, modifiers: [.option], keyDownHandler: toggleWindow)
    }
  }
}
