//
//  SecurityLogger.swift
//  JailbreakDetector
//
//  Forensic logging system for security events
//

import Foundation

class SecurityLogger {
    static let shared = SecurityLogger()
    
    private let appGroup = "group.com.security.jailbreakdetector"
    private let logsKey = "security_logs"
    private let resultsKey = "detection_results"
    
    private init() {}
    
    /// Log detection results
    func logResults(_ results: [DetectionResult]) {
        let report = DetectionReport(results: results)
        
        // Save to UserDefaults for widget access
        if let defaults = UserDefaults(suiteName: appGroup) {
            if let encoded = try? JSONEncoder().encode(results) {
                defaults.set(encoded, forKey: resultsKey)
            }
            
            // Also save summary
            defaults.set(report.isJailbroken, forKey: "is_jailbroken")
            defaults.set(report.threatsDetected, forKey: "threats_detected")
            defaults.set(Date(), forKey: "last_scan")
        }
        
        // Log to console in debug mode
        #if DEBUG
        print("=== JAILBREAK DETECTION SCAN ===")
        print("Timestamp: \(report.timestamp)")
        print("Device: \(report.deviceModel)")
        print("iOS: \(report.iosVersion)")
        print("Jailbroken: \(report.isJailbroken)")
        print("Threats: \(report.threatsDetected)/\(results.count)")
        print("================================")
        
        for result in results {
            let status = result.detected ? "⚠️ DETECTED" : "✅ SECURE"
            print("[\(status)] \(result.technique.rawValue)")
            print("  Evidence: \(result.evidence)")
            print("  MSTG: \(result.mstgReference)")
            print("  MITRE: \(result.mitreReference)")
        }
        #endif
    }
    
    /// Get stored results
    func getStoredResults() -> [DetectionResult]? {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = defaults.data(forKey: resultsKey),
              let results = try? JSONDecoder().decode([DetectionResult].self, from: data) else {
            return nil
        }
        return results
    }
    
    /// Export results as JSON string
    func exportResultsAsJSON() -> String? {
        guard let results = getStoredResults() else {
            return nil
        }
        
        let report = DetectionReport(results: results)
        return report.toJSON()
    }
    
    /// Get last scan timestamp
    func getLastScanDate() -> Date? {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return nil
        }
        return defaults.object(forKey: "last_scan") as? Date
    }
    
    /// Check if device is jailbroken (from cached results)
    func isJailbroken() -> Bool {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return false
        }
        return defaults.bool(forKey: "is_jailbroken")
    }
    
    /// Get threat count (from cached results)
    func getThreatCount() -> Int {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return 0
        }
        return defaults.integer(forKey: "threats_detected")
    }
}
