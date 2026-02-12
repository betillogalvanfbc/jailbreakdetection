//
//  DetectionResult.swift
//  JailbreakDetector
//
//  Model for detection results with forensic evidence
//

import Foundation
import UIKit

/// Result of a single detection technique
struct DetectionResult: Identifiable, Codable, Hashable {
    let id: UUID
    let technique: DetectionTechnique
    let detected: Bool
    let evidence: String
    let timestamp: Date
    
    var mstgReference: String {
        technique.mstgReference
    }
    
    var mitreReference: String {
        technique.mitreReference
    }
    
    var severity: String {
        technique.severity
    }
    
    init(technique: DetectionTechnique, detected: Bool, evidence: String) {
        self.id = UUID()
        self.technique = technique
        self.detected = detected
        self.evidence = evidence
        self.timestamp = Date()
    }
    
    /// Export to dictionary for JSON serialization
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "technique": technique.rawValue,
            "detected": detected,
            "evidence": evidence,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "mstg_reference": mstgReference,
            "mitre_reference": mitreReference,
            "severity": severity
        ]
    }
}

/// Overall detection report
struct DetectionReport: Codable {
    let timestamp: Date
    let deviceModel: String
    let iosVersion: String
    let isJailbroken: Bool
    let threatsDetected: Int
    let results: [DetectionResult]
    
    init(results: [DetectionResult]) {
        self.timestamp = Date()
        self.deviceModel = Self.getDeviceModel()
        self.iosVersion = UIDevice.current.systemVersion
        self.results = results
        self.threatsDetected = results.filter { $0.detected }.count
        self.isJailbroken = threatsDetected > 0
    }
    
    /// Export to JSON string
    func toJSON() -> String? {
        let dict: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "device_model": deviceModel,
            "ios_version": iosVersion,
            "is_jailbroken": isJailbroken,
            "threats_detected": threatsDetected,
            "total_checks": results.count,
            "results": results.map { $0.toDictionary() }
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
    
    private static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
