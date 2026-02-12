//
//  DetectionTechnique.swift
//  JailbreakDetector
//
//  Security Testing Tool - OWASP MSTG Compliance
//  MITRE ATT&CK Mobile Framework Reference
//

import Foundation

/// Enumeration of all jailbreak detection techniques
/// Mapped to OWASP MSTG and MITRE ATT&CK frameworks
enum DetectionTechnique: String, CaseIterable, Codable {
    case fileSystem = "File System Check"
    case urlSchemes = "URL Schemes"
    case sandboxIntegrity = "Sandbox Integrity"
    case dynamicLibraries = "Dynamic Libraries"
    case forkRestriction = "Fork Restriction"
    case symbolicLinks = "Symbolic Links"
    case systemCalls = "System Calls"
    case environmentVariables = "Environment Variables"
    
    /// OWASP MSTG Reference
    var mstgReference: String {
        switch self {
        case .fileSystem, .urlSchemes, .symbolicLinks:
            return "MSTG-RESILIENCE-1"
        case .sandboxIntegrity, .systemCalls:
            return "MSTG-RESILIENCE-1, MSTG-STORAGE-2"
        case .dynamicLibraries, .forkRestriction:
            return "MSTG-RESILIENCE-1, MSTG-RESILIENCE-2"
        case .environmentVariables:
            return "MSTG-RESILIENCE-1"
        }
    }
    
    /// MITRE ATT&CK Mobile Technique ID
    var mitreReference: String {
        switch self {
        case .fileSystem, .symbolicLinks, .systemCalls:
            return "T1426" // System Information Discovery
        case .urlSchemes:
            return "T1426, T1575" // System Info + Native Code
        case .sandboxIntegrity:
            return "T1575" // Native Code
        case .dynamicLibraries:
            return "T1407" // Download New Code at Runtime
        case .forkRestriction:
            return "T1575" // Native Code
        case .environmentVariables:
            return "T1426" // System Information Discovery
        }
    }
    
    /// Human-readable description
    var description: String {
        switch self {
        case .fileSystem:
            return "Checks for suspicious files and directories commonly found on jailbroken devices"
        case .urlSchemes:
            return "Attempts to open URL schemes of jailbreak tools (Cydia, Sileo, etc.)"
        case .sandboxIntegrity:
            return "Verifies iOS sandbox integrity by attempting unauthorized file operations"
        case .dynamicLibraries:
            return "Detects suspicious dynamic libraries loaded at runtime"
        case .forkRestriction:
            return "Tests fork() system call restrictions (unavailable on stock iOS)"
        case .symbolicLinks:
            return "Checks for abnormal symbolic links in system directories"
        case .systemCalls:
            return "Verifies system call behavior on restricted paths"
        case .environmentVariables:
            return "Detects suspicious environment variables used for code injection"
        }
    }
    
    /// Severity level
    var severity: String {
        switch self {
        case .fileSystem, .urlSchemes:
            return "HIGH"
        case .sandboxIntegrity, .dynamicLibraries:
            return "CRITICAL"
        case .forkRestriction:
            return "CRITICAL"
        case .symbolicLinks, .systemCalls:
            return "MEDIUM"
        case .environmentVariables:
            return "HIGH"
        }
    }
}
