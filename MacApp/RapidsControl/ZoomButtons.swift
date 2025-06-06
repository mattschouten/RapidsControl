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
    
    // Zoom only shows the confirmation dialog if the Zoom window is active.  So raise it.
    if let zoomApp = getZoomApp() {
        zoomApp.activate()
    }
    // If this fails, no exceptions are thrown.  The close menu just doesn't do anything.  Weird, but true.
    if let closeMenuItem = findZoomMenuItem(title: "Close") {
        let result = AXUIElementPerformAction(closeMenuItem, kAXPressAction as CFString)
        if result != .success {
            print("Failed to perform Close action: \(result)")
        }
    }

    // Probably closing the window, then finding the right button?
    // TODO:  Try a few times, faster, and stop trying once found.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        print("POOF")
        if let zoomAppElement = getZoomAppElement(),
           let targetButton = findEndMeetingForAllButton(zoomApp: zoomAppElement) {
            
            print("FOUND IT!")
            clickAXButton(in: targetButton)
        } else {
            print("Couldn't find button :(")
        }
    }
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
    } else if let _ = findZoomMenuItem(title: "Start Video") {
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
    
    guard maxDepth > 0 else { return nil }
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
        printMenuItemRecursive(zoomApp, indent: 0)
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
