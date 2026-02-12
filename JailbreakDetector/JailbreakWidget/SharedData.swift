//
//  SharedData.swift
//  JailbreakWidget
//
//  Simplified shared data access for widget (no complex types)
//

import Foundation

class SharedData {
    static let appGroup = "group.com.security.jailbreakdetector"
    
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
