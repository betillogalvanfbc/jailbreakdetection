//
//  JailbreakDetectorApp.swift
//  JailbreakDetector
//
//  iOS Security Testing Tool
//  OWASP MSTG-RESILIENCE-1 Compliance
//

import SwiftUI

@main
struct JailbreakDetectorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .persistentJailbreakProtection() // ✅ Overlay aparece CADA VEZ que se abre la app
        }
    }
}
