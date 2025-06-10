import Cocoa
import ApplicationServices

enum ZoomAudioStatus {
    case muted
    case unmuted
    case unknown
}

enum ZoomVideoStatus {
    case on
    case off
    case unknown
}

func muteZoom() {
    if getAudioStatus() != .muted {
        print("Muting Zoom Audio")
        if let muteMenuItem = findZoomMenuItem(title: "Mute audio") {
            AXUIElementPerformAction(muteMenuItem, kAXPressAction as CFString)
        }
    }
}

func unmuteZoom() {
    if getAudioStatus() != .unmuted {
        print("Unmuting Zoom Audio")
        if let muteMenuItem = findZoomMenuItem(title: "Unmute audio") {
            AXUIElementPerformAction(muteMenuItem, kAXPressAction as CFString)
        }
    }
}

func turnOffZoomVideo() {
    // TODO:  GET VIDEO STATUS
    //if getAudioStatus() != .unmuted {
    print("Stopping Zoom Video")
        if let muteMenuItem = findZoomMenuItem(title: "Stop video") {
            AXUIElementPerformAction(muteMenuItem, kAXPressAction as CFString)
        }
    //}
}

func turnOnZoomVideo() {
    // TODO:  GET VIDEO STATUS
    //if getAudioStatus() != .unmuted {
    print("Starting Zoom Video")
        if let muteMenuItem = findZoomMenuItem(title: "Start video") {
            AXUIElementPerformAction(muteMenuItem, kAXPressAction as CFString)
        }
    //}
}

func endMeetingForAll() {
    print("Attempting to End Meeting for All")
    
    guard getZoomApp() != nil else {
        print("Could not find Zoom app running")
        return
    }
    
    // Zoom only shows the confirmation dialog if the Zoom meeting window is active.  So raise it.
    // If the meeting window isn't active—if it's instead the Zoom controls window—the meeting can't be closed either.
    guard activateZoomMeetingWindow() else {
        print("Could not activate Zoom meeting window")
        return
    }
    
    var windowTitle = getFocusedWindowTitle()
    print("Window Title after I think I activated is \(String(describing: windowTitle))")
    
    // If this fails, no exceptions are thrown.  The close menu just doesn't do anything.  Weird, but true.
    if let closeMenuItem = findZoomMenuItem(title: "Close") {
        let result = AXUIElementPerformAction(closeMenuItem, kAXPressAction as CFString)
        if result != .success {
            print("Failed to perform Close action: \(result)")
        }
    } else {
        print("Failed to find the Close menu item!")
    }
    
    windowTitle = getFocusedWindowTitle()
    print("Window Title after I think I hit close is \(String(describing: windowTitle))")

    // Probably closing the window, then finding the right button?
    // TODO:  Try a few times, faster, and stop trying once found.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        print("POOF")
        windowTitle = getFocusedWindowTitle()
        print("Window Title at POOF close is \(String(describing: windowTitle))")
        if let zoomAppElement = getZoomAppElement(),
           let targetButton = findEndMeetingForAllButton(zoomApp: zoomAppElement) {
            
            print("FOUND IT!")
            clickAXButton(in: targetButton)
        } else {
            print("Couldn't find button :(")
        }
    }
}

fileprivate func findMeetingWindowByName(_ windowList: [AXUIElement]) -> AXUIElement? {
    for window in windowList {
        print ("Window Title: \(String(describing: window.title))")
        if let title = window.title, title.localizedCaseInsensitiveContains("Zoom Meeting") {
            return window
        }
    }
    
    return nil
}

fileprivate func findMeetingWindowByChildRole(_ windowList: [AXUIElement]) -> AXUIElement? {
    for window in windowList {
        if let children = window.children {
            for child in children {
                if let role = child.role, role.localizedStandardContains("AXTabGroup") {
                    print("FOUND IT in \(String(describing: window.title))")
                    return window
                }
            }
        }
    }
    
    return nil
}

func activateZoomMeetingWindow() -> Bool {
    guard let zoomApp = getZoomApp() else {
        print("Could not find Zoom app running")
        return false
    }
    
    // Zoom only shows the confirmation dialog if the Zoom meeting window is active.  So raise it.
    zoomApp.activate()

    guard let zoomAppElement = getZoomAppElement() else {
        print("Could not get Zoom App Element")
        return false
    }
    
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(zoomAppElement, kAXWindowsAttribute as CFString, &value)
    guard result == .success, let windowList = value as? [AXUIElement] else {
        print("Failed to get windows")
        return false
    }
    
    var meetingWindow = findMeetingWindowByName(windowList)
    
    // If the window isn't found, search again for one containing an AXTabGroup role — right now the meeting window is the only one that does
    if meetingWindow == nil {
        print("Could not find window by name")
        meetingWindow = findMeetingWindowByChildRole(windowList)
    }
    
    // Bring the meeting window to the foreground
    guard let windowToActivate = meetingWindow else {
        return false
    }
    
    AXUIElementPerformAction(windowToActivate, kAXRaiseAction as CFString)
    AXUIElementSetAttributeValue(zoomAppElement, kAXFocusedWindowAttribute as CFString, windowToActivate)
    print("Meeting window should have been raised")
    // TODO:  Might need to add some pauses!
    
    return true
}

func getAudioStatus() -> ZoomAudioStatus {
    if let _ = findZoomMenuItem(title: "Unmute audio") {
        return .muted
    } else if let _ = findZoomMenuItem(title: "Mute audio") {
        return .unmuted
    } else {
        return .unknown
    }
}

func getVideoStatus() -> ZoomVideoStatus {
    if let _ = findZoomMenuItem(title: "Stop video") {
        return .on
    } else if let _ = findZoomMenuItem(title: "Start video") {
        return .off
    } else {
        return .unknown
    }
}

func getAttribute(_ element: AXUIElement, _ attribute: String) throws -> AnyObject? {
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
    if result == .success {
        return value
    } else {
        throw NSError(domain: "AXError", code: Int(result.rawValue), userInfo: nil)
    }
}

private func clickAXButton(in button: AXUIElement) -> Bool {
    let title = button.title
    print("Clicking button \(String(describing: title))")
    
    let result = AXUIElementPerformAction(button, kAXPressAction as CFString)
    return result == .success
}

private func findAXElement(in root: AXUIElement, matching condition: (AXUIElement) -> Bool, maxDepth: Int) -> AXUIElement? {
    if condition(root) { return root }
    
    guard maxDepth > 0 else {
        printMenuItemRecursive(root, indent: 0)
        return nil
    }
    guard let children = root.children else { return nil }
    
    for child in children {
        if let match = findAXElement(in: child, matching: condition, maxDepth: maxDepth - 1) {
            return match
        }
    }
    
    return nil
}

private func findEndMeetingForAllButton(zoomApp: AXUIElement) -> AXUIElement? {
    return findAXButton(withTitle: "End meeting for all", in: zoomApp)
}

private func findAXButton(withTitle title: String, in appElement: AXUIElement) -> AXUIElement? {
    return findAXElement(
        in: appElement,
        matching: { element in
            guard let role = element.role, role == kAXButtonRole as String else { return false }
            return element.title == title
        },
        maxDepth: 15
    )
}

func getZoomApp() -> NSRunningApplication? {
    let zoomBundleId = "us.zoom.xos"

    return NSRunningApplication.runningApplications(withBundleIdentifier: zoomBundleId).first
}

func getZoomAppElement() -> AXUIElement? {
    guard let runningApp = getZoomApp() else {
        print("Zoom is not running")
        return nil
    }

    return AXUIElementCreateApplication(runningApp.processIdentifier)
}

// Gets the title of the focused window.
// Written as debug to understand how fast activating windows works.
func getFocusedWindowTitle() -> String? {
    let systemWideElement = AXUIElementCreateSystemWide()
    
    var focusedApp: CFTypeRef?
    let appResult = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &focusedApp)
    guard appResult == .success,
          let appElement = focusedApp else {
        return nil
    }
    
    var focusedWindow: CFTypeRef?
    let windowResult = AXUIElementCopyAttributeValue(appElement as! AXUIElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
    guard windowResult == .success,
          let windowElement = focusedWindow else {
        return nil
    }
    
    var titleValue: CFTypeRef?
    let titleResult = AXUIElementCopyAttributeValue(windowElement as! AXUIElement, kAXTitleAttribute as CFString, &titleValue)
    if titleResult == .success,
       let title = titleValue as? String {
            return title
    }
    
    return nil
}
    

// The Zoom menu bar is the most reliable way to get and set mute status.
// The buttons in the window are removed from the "DOM tree" equivalent when they are hidden
// when the application is inactive.
func findZoomMenuItem(title: String) -> AXUIElement? {
    guard let zoomApp = getZoomAppElement() else {
        print("Could not get Zoom app")
        return nil
    }

    var menuBarValue: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(zoomApp, kAXMenuBarAttribute as CFString, &menuBarValue)
    guard result == .success else {
        print("Could not get menu bar")
        // printMenuItemRecursive(zoomApp, indent: 0)
        return nil
    }
    
    let menuBar = menuBarValue as! AXUIElement
    
    return findMenuItemRecursive(element: menuBar, titleToFind: title)
}

private func findMenuItemRecursive(element: AXUIElement, titleToFind: String) -> AXUIElement? {
    var titleValue: CFTypeRef?
    if AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue) == .success,
       let title = titleValue as? String {
        if title == titleToFind {
            return element
        }
    }

    var childrenValues: CFTypeRef?
    if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValues) == .success,
       let children = childrenValues as? [AXUIElement] {
        for child in children {
            if let found = findMenuItemRecursive(element: child, titleToFind: titleToFind) {
                return found
            }
        }
    }

    return nil
}

private func printMenuItemRecursive(_ element: AXUIElement, indent: Int) {
    guard indent < 25 else {
        print("Indent too high.  Clearly something is wrong.")
        return
    }
    let indentStr = String(repeating: "  ", count: indent)

    var titleValue: CFTypeRef?
    let titleResult = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
    let title = (titleResult == .success ? (titleValue as? String ?? "<no title>") : "<no title>")

    print("\(indentStr)- \(title)")

    var childrenValue: CFTypeRef?
    let childrenResult = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)

    if childrenResult == .success, let childrenArray = childrenValue as? [AnyObject] {
        for child in childrenArray {
            printMenuItemRecursive(child as! AXUIElement, indent: indent + 1)
        }
    }
}

extension AXUIElement {
    var title: String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(self, kAXTitleAttribute as CFString, &value)
        return result == .success ? value as? String : nil
    }
    
    var role: String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(self, kAXRoleAttribute as CFString, &value)
        return result == .success ? value as? String : nil
    }
    
    var children: [AXUIElement]? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(self, kAXChildrenAttribute as CFString, &value)
        return result == .success ? value as? [AXUIElement] : nil
    }
}
