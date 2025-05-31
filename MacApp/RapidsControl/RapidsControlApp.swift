//
//  RapidsControlApp.swift
//  RapidsControl
//
//  Created by Matt Schouten on 5/1/25.
//

import ArgumentParser
import SwiftUI

struct RapidsControlApp: App {
    let controller = RapidsController()
    let server: UDSZoomServer = UDSZoomServer()
    
    init() {
        requestAccessibilityPermissions()
        controller.startServer()
    }
   
    func handleShutdown() {
        controller.stopServer()
    }
    
    var body: some Scene {
        MenuBarExtra("Rapids Control App",
                     systemImage: "water.waves.and.arrow.trianglehead.up")
        {
            RapidsMenuView()
                .environmentObject(controller)
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

