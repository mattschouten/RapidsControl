//
//  RapidsControlApp.swift
//  RapidsControl
//
//  Created by Matt Schouten on 5/1/25.
//

import ArgumentParser
import SwiftUI

struct RapidsControlApp: App {
    let server: UDSZoomServer = UDSZoomServer()
    
    init() {
        requestAccessibilityPermissions()
        server.start()
    }
   
    func handleShutdown() {
        server.stop()
    }
    
    var body: some Scene {
        MenuBarExtra("Rapids Control App",
                     systemImage: "water.waves.and.arrow.trianglehead.up")
        {
            RapidsMenuView()
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in handleShutdown() }
        }
    }
}

func requestAccessibilityPermissions() {
    if !AXIsProcessTrusted() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

