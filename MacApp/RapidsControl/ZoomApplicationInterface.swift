//
//  ZoomApplicationInterface.swift
//  RapidsControl
//
//  Created by Matt Schouten on 6/22/25.
//

import AppKit

private let oneSecondInNanoseconds: UInt64 = 1_000_000_000
private let oneTenthOfASecondInNanoseconds: UInt64 = 100_000_000 //  0.1 * 1_000_000_000 nanoseconds

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

@MainActor
func endMeetingForAllAction() async {
    print("Attempting to End Meeting for All")
    
    guard await activateZoomApp(timeout: 0.5) == true else {
        print("CANNOT END - Could not find Zoom app running")
        return
    }
    
    // Zoom only shows the confirmation dialog if the Zoom meeting window is active.  So raise it.
    // If the meeting window isn't active—if it's instead the Zoom controls window—the meeting can't be closed either.
    guard await activateZoomMeetingWindow(timeout: 0.5) else {
        print("Could not activate Zoom meeting window")
        return
    }
    
    await clickClose(timeout: 0.3);
}

@MainActor
fileprivate func activateZoomApp(timeout: TimeInterval) async -> Bool {
    let maximumNanosecondsBeforeTimeout: UInt64 = UInt64(timeout * Double(oneSecondInNanoseconds))
    let justForABlink: UInt64 = 100
    var nanosecondsElapsed: UInt64 = 0
    
    guard let zoomApp = getZoomApp() else {
        return false
    }
    
    // App activation in MacOS is clumsy and unreliable
    // So we use a multi-layered approach to activating Zoom.
    // 1. NSRunningApplication.activate (a couple attempts)
    // 2. Try Open-ing the app
    // 2. Use AppleScript as a fallback
    // After each step, we try to verify the app has been raised to move things along faster.
    // We'll try to activate the specific window (kAXRaiseAction) separately—in testing, it does not
    // raise the entire application, just the window.
    
    zoomApp.activate(options: [.activateIgnoringOtherApps, .activateIgnoringOtherApps])
    try? await Task.sleep(nanoseconds: justForABlink)
    nanosecondsElapsed += justForABlink

    repeat {
        print("Attempting to activate Zoom...")
        
        // .activateIgnoringOtherApps was deprecated and claims to not do anything, but activation seems to work
        // better when that option is included.
        zoomApp.activate(options: [.activateIgnoringOtherApps, .activateIgnoringOtherApps])
        await sleepAndCheckActive(nanosToSleep: justForABlink, totalNanos: &nanosecondsElapsed, contextMessage: "Activate Call")

        var isFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == zoomApp.processIdentifier
        if let bundleUrl = zoomApp.bundleURL, !isFrontmost {
            activateZoomWithOpen(bundleUrl: bundleUrl)
        }
        await sleepAndCheckActive(nanosToSleep: justForABlink, totalNanos: &nanosecondsElapsed, contextMessage: "Open Call")
        
        isFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == zoomApp.processIdentifier
        if let bundleId = zoomApp.bundleIdentifier, !isFrontmost {
            activateZoomWithApplescript(bundleIdentifier: bundleId)
        }
        await sleepAndCheckActive(nanosToSleep: justForABlink, totalNanos: &nanosecondsElapsed, contextMessage: "Applescript Activation")
        
        print("After attempting to activate...App active? \(zoomApp.isActive)")
        try? await Task.sleep(nanoseconds: oneTenthOfASecondInNanoseconds)
        nanosecondsElapsed += oneTenthOfASecondInNanoseconds
    } while (!zoomAppIsActive() && nanosecondsElapsed < maximumNanosecondsBeforeTimeout)
    
    return zoomAppIsActive()
}

fileprivate func sleepAndCheckActive(nanosToSleep: UInt64, totalNanos: inout UInt64, contextMessage: String) async {
    try? await Task.sleep(nanoseconds: nanosToSleep)
    totalNanos += nanosToSleep
    
    if !zoomAppIsActive() {
        print("Zoom not active:  \(contextMessage)")
    }
}

fileprivate func activateZoomWithOpen(bundleUrl: URL) {
    NSWorkspace.shared.openApplication(at: bundleUrl, configuration: NSWorkspace.OpenConfiguration())
}

fileprivate func activateZoomWithApplescript(bundleIdentifier: String) {
    let script = """
        tell application id "\(bundleIdentifier)" to activate
    """
    
    var error: NSDictionary?
    if let appleScript = NSAppleScript(source: script) {
        appleScript.executeAndReturnError(&error)
    }
    
    print("Applescript result: \(String(describing: error))")
}

fileprivate func zoomAppIsActive() -> Bool {
    guard let zoomApp = getZoomApp(),
          NSWorkspace.shared.frontmostApplication?.processIdentifier == zoomApp.processIdentifier else {
        return false
    }
    
    guard let zoomAppElement = getZoomAppElement() else {
        return false
    }
    
    var focusedWindow: AnyObject?
    let result = AXUIElementCopyAttributeValue(zoomAppElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
    
    return result == .success && focusedWindow != nil
}

fileprivate func meetingWindowIsFocused() -> Bool {
    let windowTitle = getFocusedWindowTitle()
    return windowTitle == "Zoom Meeting"
}

// Assumes Zoom is active.  If Zoom is not, this will fail.
fileprivate func clickClose(timeout: TimeInterval) async -> Bool {
    let maximumNanosecondsBeforeTimeout: UInt64 = UInt64(timeout * Double(oneSecondInNanoseconds))
    var nanosecondsElapsed: UInt64 = 0
    
    var windowTitle = getFocusedWindowTitle()
    print("Window Title at start of clickClose() is \(String(describing: windowTitle))")
    
    // If this fails, no exceptions are thrown.  The close menu just doesn't do anything.  Weird, but true.
    if let closeMenuItem = findZoomMenuItem(title: "Close") {
        let result = clickUIElement(in: closeMenuItem)
        if !result {
            print("Failed to perform Close action: \(result)")
        }
    } else {
        print("Failed to find the Close menu item!")
    }
    // TODO:  Some cleanup is possible here.  Should add a check for whether Close did something.
    
    windowTitle = getFocusedWindowTitle()
    print("Window Title after I think I hit close is \(String(describing: windowTitle))")

    // TODO:  Try a few times, faster, and stop trying once found.
    repeat {
        print("POOF")
        windowTitle = getFocusedWindowTitle()
        print("Window Title at POOF close is \(String(describing: windowTitle))")
        if let zoomAppElement = getZoomAppElement(),
           let targetButton = findEndMeetingForAllButton(zoomApp: zoomAppElement) {
            
            print("FOUND IT!")
            clickUIElement(in: targetButton)
        } else {
            print("Couldn't find button :(")
        }
        
        try? await Task.sleep(nanoseconds: oneTenthOfASecondInNanoseconds)
        nanosecondsElapsed += oneTenthOfASecondInNanoseconds
    } while (!zoomAppIsActive() && nanosecondsElapsed < maximumNanosecondsBeforeTimeout)
    
    return zoomAppIsActive();
    // TODO:  Maybe should be a different function?
}

fileprivate func zoomMeetingEnded() -> Bool {
    // TODO:  I can probably make this better.
    let windowTitle = getFocusedWindowTitle()
    return windowTitle == "Zoom Meeting"
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

@MainActor
func activateZoomMeetingWindow(timeout: TimeInterval) async -> Bool {
    // Zoom only shows the confirmation dialog if the Zoom meeting window is active.  So raise it.
    print("Activating Zoom Meeting Window...")
    
    guard zoomAppIsActive() else {
        print("Zoom app is not active.  Giving up.")
        return false
    }
    
    print("Is main thread? \(Thread.isMainThread)")
    
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
    
    guard let windowToActivate = meetingWindow else {
        return false
    }
    
    let maximumNanosecondsBeforeTimeout: UInt64 = UInt64(timeout * Double(oneSecondInNanoseconds))
    var nanosecondsElapsed: UInt64 = 0
    
    repeat {
        // Bring the meeting window to the foreground
        AXUIElementPerformAction(windowToActivate, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(zoomAppElement, kAXFocusedWindowAttribute as CFString, windowToActivate)
        print("Requested to activate and focus meeting window!")

        try? await Task.sleep(nanoseconds: oneTenthOfASecondInNanoseconds)
        nanosecondsElapsed += oneTenthOfASecondInNanoseconds
    }
    while (!meetingWindowIsFocused() && nanosecondsElapsed < maximumNanosecondsBeforeTimeout)

    
    return meetingWindowIsFocused()
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

private func findEndMeetingForAllButton(zoomApp: AXUIElement) -> AXUIElement? {
    return findAXButton(withTitle: "End meeting for all", in: zoomApp)
}


// The Zoom menu bar is the most reliable way to get and set mute status.
// The buttons in the window are removed from the "DOM tree" equivalent when they are hidden
// when the application is inactive.
func findZoomMenuItem(title: String) -> AXUIElement? {
    guard let zoomApp = getZoomAppElement() else {
        print("Could not get Zoom app")
        return nil
    }

    // TODO:  Make this a "Get Menu Bar" method
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

