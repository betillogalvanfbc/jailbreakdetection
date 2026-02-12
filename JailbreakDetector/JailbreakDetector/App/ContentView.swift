//
//  ContentView.swift
//  JailbreakDetector
//
//  Main UI showing detection results
//

import SwiftUI

struct ContentView: View {
    @StateObject private var detector = JailbreakDetector()
    @State private var showExportSheet = false
    @State private var exportedJSON = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: detector.isJailbroken
                        ? [Color.red.opacity(0.2), Color.orange.opacity(0.1)]
                        : [Color.green.opacity(0.2), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Status Card
                        StatusCard(
                            isJailbroken: detector.isJailbroken,
                            threatsDetected: detector.threatsDetected,
                            totalChecks: DetectionTechnique.allCases.count
                        )
                        .padding(.top, 20)
                        
                        // Scan Button
                        Button(action: {
                            detector.performFullScan()
                        }) {
                            HStack {
                                Image(systemName: detector.isScanning ? "arrow.triangle.2.circlepath" : "shield.checkered")
                                Text(detector.isScanning ? "Scanning..." : "Run Security Scan")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(detector.isScanning)
                        .padding(.horizontal)
                        
                        // Results Section
                        if !detector.results.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Detection Results")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: {
                                        exportResults()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Export")
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                                
                                ForEach(detector.results) { result in
                                    ResultCard(result: result)
                                }
                            }
                        } else {
                            EmptyStateView()
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Jailbreak Detector")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Auto-scan on first launch
                if detector.results.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        detector.performFullScan()
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportView(jsonString: exportedJSON)
            }
        }
    }
    
    private func exportResults() {
        if let json = SecurityLogger.shared.exportResultsAsJSON() {
            exportedJSON = json
            showExportSheet = true
        }
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let isJailbroken: Bool
    let threatsDetected: Int
    let totalChecks: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isJailbroken ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(isJailbroken ? .red : .green)
            
            Text(isJailbroken ? "JAILBREAK DETECTED" : "DEVICE SECURE")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isJailbroken ? .red : .green)
            
            if threatsDetected > 0 {
                Text("\(threatsDetected) of \(totalChecks) checks detected threats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("All \(totalChecks) security checks passed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Result Card
struct ResultCard: View {
    let result: DetectionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.detected ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundColor(result.detected ? .red : .green)
                
                Text(result.technique.rawValue)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(result.severity)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor(result.severity).opacity(0.2))
                    .foregroundColor(severityColor(result.severity))
                    .cornerRadius(4)
            }
            
            Text(result.evidence)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Label(result.mstgReference, systemImage: "book.closed")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Label(result.mitreReference, systemImage: "shield.lefthalf.filled")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "CRITICAL": return .red
        case "HIGH": return .orange
        case "MEDIUM": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Scan Results")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap 'Run Security Scan' to check for jailbreak")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Export View
struct ExportView: View {
    let jsonString: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(jsonString)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Export Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        UIPasteboard.general.string = jsonString
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
}
#endif
