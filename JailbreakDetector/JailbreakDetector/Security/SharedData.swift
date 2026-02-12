//
//  SharedData.swift
//  JailbreakDetector
//
//  Shared data access between app and widget
//

import Foundation

class SharedData {
    static let appGroup = "group.com.security.jailbreakdetector"
    
    /// Save detection results to shared container
    static func saveResults(_ results: [DetectionResult]) {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return }
        
        if let encoded = try? JSONEncoder().encode(results) {
            defaults.set(encoded, forKey: "detection_results")
        }
        
        let threatsDetected = results.filter { $0.detected }.count
        defaults.set(threatsDetected > 0, forKey: "is_jailbroken")
        defaults.set(threatsDetected, forKey: "threats_detected")
        defaults.set(Date(), forKey: "last_scan")
    }
    
    /// Load detection results from shared container
    static func loadResults() -> [DetectionResult] {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = defaults.data(forKey: "detection_results"),
              let results = try? JSONDecoder().decode([DetectionResult].self, from: data) else {
            return []
        }
        return results
    }
    
    /// Check if device is jailbroken
    static func isJailbroken() -> Bool {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return false
        }
        return defaults.bool(forKey: "is_jailbroken")
    }
    
    /// Get threat count
    static func getThreatCount() -> Int {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return 0
        }
        return defaults.integer(forKey: "threats_detected")
    }
    
    /// Get last scan date
    static func getLastScanDate() -> Date? {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return nil
        }
        return defaults.object(forKey: "last_scan") as? Date
    }
}
