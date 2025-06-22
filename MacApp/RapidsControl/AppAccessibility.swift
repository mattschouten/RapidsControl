//
//  AppAccessibility.swift
//  RapidsControl
//
//  Created by Matt Schouten on 6/22/25.
//

import Cocoa

private var visitedElements: Set<AXUIElement> = []

func getAttribute(_ element: AXUIElement, _ attribute: String) throws -> AnyObject? {
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
    if result == .success {
        return value
    } else {
        throw NSError(domain: "AXError", code: Int(result.rawValue), userInfo: nil)
    }
}

func clickUIElement(in uiElement: AXUIElement) -> Bool {
    let title = uiElement.title
    print("Clicking button \(String(describing: title))")
    
    let result = AXUIElementPerformAction(uiElement, kAXPressAction as CFString)
    if result != .success {
        print("Error clicking UI element: \(result)")
    }
    
    return result == .success
}

private func findAXElement(in root: AXUIElement, matching condition: (AXUIElement) -> Bool, maxDepth: Int, freshSearch: Bool) -> AXUIElement? {
    if condition(root) { return root }
    
    guard maxDepth > 0 else {
        printMenuItemRecursive(root, indent: 0)
        return nil
    }
  
    // If this is a brand new search, clear our list of visited elements
    if freshSearch {
        visitedElements = []
    }
    
    guard let children = root.children else { return nil }
    
    for child in children {
        // If we've already seen this element, return.  Cycles can occur.  We don't need to re-search it.
        if visitedElements.contains(child) {
            print("I've already seen this element! \(child)")
            return nil
        }
        
        visitedElements.insert(child)

        if let match = findAXElement(in: child, matching: condition, maxDepth: maxDepth - 1, freshSearch: false) {
            return match
        }
    }
    
    return nil
}

func findAXButton(withTitle title: String, in appElement: AXUIElement) -> AXUIElement? {
    return findAXElement(
        in: appElement,
        matching: { element in
            guard let role = element.role, role == kAXButtonRole as String else { return false }
            return element.title == title
        },
        maxDepth: 55,
        freshSearch: true
    )
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

func findMenuItemRecursive(element: AXUIElement, titleToFind: String) -> AXUIElement? {
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
