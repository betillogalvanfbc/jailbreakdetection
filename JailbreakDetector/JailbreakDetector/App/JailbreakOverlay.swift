//
//  JailbreakOverlay.swift
//  Example: Full-screen jailbreak alert overlay
//
//  Copy this file to your project and use .jailbreakProtection() on any view
//

import SwiftUI

/// Modifier that shows a full-screen overlay alert when jailbreak is detected
struct JailbreakOverlayModifier: ViewModifier {
    @State private var isJailbroken = false
    @State private var threatsDetected = 0
    @State private var isChecking = true
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isJailbroken ? 10 : 0)
            
            if isChecking {
                // Loading indicator
                ProgressView("Checking security...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
            
            if isJailbroken {
                // Full-screen overlay
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                // Jailbreak warning card
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .red.opacity(0.5), radius: 20)
                    
                    // Title
                    Text("⚠️ JAILBREAK DETECTED")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    
                    // Message
                    VStack(spacing: 8) {
                        Text("This device has been modified")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("\(threatsDetected) security threats detected")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    // Explanation
                    Text("For security reasons, some features may be disabled or unavailable on jailbroken devices.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            // Continue with limited features
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        Button {
                            // Exit app
                            exit(0)
                        } label: {
                            Text("Exit App")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .padding(40)
                .shadow(color: .black.opacity(0.3), radius: 30)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: isJailbroken)
        .animation(.easeInOut, value: isChecking)
        .onAppear {
            checkJailbreak()
        }
    }
    
    private func checkJailbreak() {
        let detector = JailbreakDetector()
        
        // Perform scan
        detector.performFullScan()
        
        // Wait for scan to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isChecking = false
            self.isJailbroken = detector.isJailbroken
            self.threatsDetected = detector.threatsDetected
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds jailbreak protection overlay to the view
    /// Shows a full-screen alert if jailbreak is detected
    func jailbreakProtection() -> some View {
        modifier(JailbreakOverlayModifier())
    }
}

// MARK: - Example Usage

struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .jailbreakProtection() // ✅ Add this single line!
        }
    }
}

// MARK: - Alternative: Custom Actions

struct JailbreakOverlayWithActions: ViewModifier {
    let onDetected: (Int) -> Void // Callback with threat count
    @State private var isJailbroken = false
    @State private var threatsDetected = 0
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                let detector = JailbreakDetector()
                detector.performFullScan()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.isJailbroken = detector.isJailbroken
                    self.threatsDetected = detector.threatsDetected
                    
                    if isJailbroken {
                        onDetected(threatsDetected)
                    }
                }
            }
    }
}

extension View {
    /// Adds jailbreak protection with custom action
    func jailbreakProtection(onDetected: @escaping (Int) -> Void) -> some View {
        modifier(JailbreakOverlayWithActions(onDetected: onDetected))
    }
}

// Usage with custom action:
// ContentView()
//     .jailbreakProtection { threatCount in
//         Analytics.log("jailbreak_detected", params: ["threats": threatCount])
//     }
