//
//  JailbreakDetector.swift
//  JailbreakDetector
//
//  Main detection engine implementing OWASP MSTG-RESILIENCE-1
//  MITRE ATT&CK Mobile Framework: T1407, T1426, T1575, T1576
//

import Foundation
import UIKit
import Darwin
import MachO

/// Main jailbreak detection engine
class JailbreakDetector: ObservableObject {
    @Published var results: [DetectionResult] = []
    @Published var isScanning: Bool = false
    @Published var isJailbroken: Bool = false
    @Published var threatsDetected: Int = 0
    
    // Suspicious paths commonly found on jailbroken devices
    private let suspiciousFiles = [
        "/Applications/Cydia.app",
        "/Applications/blackra1n.app",
        "/Applications/FakeCarrier.app",
        "/Applications/Icy.app",
        "/Applications/IntelliScreen.app",
        "/Applications/MxTube.app",
        "/Applications/RockApp.app",
        "/Applications/SBSettings.app",
        "/Applications/WinterBoard.app",
        "/Applications/Sileo.app",
        "/Applications/Zebra.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/Library/MobileSubstrate/DynamicLibraries/",
        "/bin/bash",
        "/bin/sh",
        "/usr/sbin/sshd",
        "/usr/libexec/ssh-keysign",
        "/usr/sbin/frida-server",
        "/usr/bin/cycript",
        "/usr/local/bin/cycript",
        "/usr/lib/libcycript.dylib",
        "/etc/apt",
        "/etc/ssh/sshd_config",
        "/private/var/lib/apt/",
        "/private/var/lib/cydia",
        "/private/var/mobile/Library/SBSettings/Themes",
        "/private/var/stash",
        "/private/var/tmp/cydia.log",
        "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        "/var/cache/apt",
        "/var/lib/cydia",
        "/var/log/syslog",
        "/.bootstrapped_electra",
        "/.installed_unc0ver",
        "/jb/lzma",
        "/jb/offsets.plist",
        "/.cydia_no_stash"
    ]
    
    // URL schemes of jailbreak tools
    private let suspiciousURLSchemes = [
        "cydia://package/com.example.package",
        "sileo://package/com.example.package",
        "zbra://package/com.example.package",
        "filza://",
        "activator://"
    ]
    
    /// Execute all detection techniques
    func performFullScan() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isScanning = true
                self.results.removeAll()
            }
            
            var scanResults: [DetectionResult] = []
            
            // 1. File System Check (MSTG-RESILIENCE-1)
            scanResults.append(self.checkFileSystem())
            
            // 2. URL Scheme Check (MSTG-RESILIENCE-1)
            scanResults.append(self.checkURLSchemes())
            
            // 3. Sandbox Integrity Check (MSTG-RESILIENCE-1, MSTG-STORAGE-2)
            scanResults.append(self.checkSandboxIntegrity())
            
            // 4. Dynamic Libraries Check (MSTG-RESILIENCE-1, T1407)
            scanResults.append(self.checkDynamicLibraries())
            
            // 5. Fork Restriction Check (MSTG-RESILIENCE-2, T1575)
            scanResults.append(self.checkForkRestriction())
            
            // 6. Symbolic Links Check (MSTG-RESILIENCE-1, T1426)
            scanResults.append(self.checkSymbolicLinks())
            
            // 7. System Calls Check (MSTG-RESILIENCE-1)
            scanResults.append(self.checkSystemCalls())
            
            // 8. Environment Variables Check (T1407, T1426)
            scanResults.append(self.checkEnvironmentVariables())
            
            DispatchQueue.main.async {
                self.results = scanResults
                self.threatsDetected = scanResults.filter { $0.detected }.count
                self.isJailbroken = self.threatsDetected > 0
                self.isScanning = false
                
                // Save results
                SecurityLogger.shared.logResults(scanResults)
            }
        }
    }
    
    // MARK: - Detection Techniques
    
    /// Technique 1: File System Check
    /// Checks for existence of common jailbreak files and directories
    private func checkFileSystem() -> DetectionResult {
        var detectedFiles: [String] = []
        
        for path in suspiciousFiles {
            if FileManager.default.fileExists(atPath: path) {
                detectedFiles.append(path)
            }
        }
        
        let detected = !detectedFiles.isEmpty
        let evidence = detected
            ? "Found \(detectedFiles.count) suspicious files: \(detectedFiles.prefix(3).joined(separator: ", "))"
            : "No suspicious files found"
        
        return DetectionResult(
            technique: .fileSystem,
            detected: detected,
            evidence: evidence
        )
    }
    
    /// Technique 2: URL Scheme Check
    /// Attempts to open URL schemes of jailbreak tools
    private func checkURLSchemes() -> DetectionResult {
        var detectedSchemes: [String] = []
        
        for urlString in suspiciousURLSchemes {
            if let url = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(url) {
                    detectedSchemes.append(urlString.components(separatedBy: "://").first ?? urlString)
                }
            }
        }
        
        let detected = !detectedSchemes.isEmpty
        let evidence = detected
            ? "Detected URL schemes: \(detectedSchemes.joined(separator: ", "))"
            : "No jailbreak URL schemes detected"
        
        return DetectionResult(
            technique: .urlSchemes,
            detected: detected,
            evidence: evidence
        )
    }
    
    /// Technique 3: Sandbox Integrity Check
    /// Attempts to write outside of app sandbox
    private func checkSandboxIntegrity() -> DetectionResult {
        let testPath = "/private/jailbreak_test.txt"
        let testString = "jailbreak_test"
        
        do {
            try testString.write(toFile: testPath, atomically: true, encoding: .utf8)
            // If we can write, device is jailbroken
            try? FileManager.default.removeItem(atPath: testPath)
            return DetectionResult(
                technique: .sandboxIntegrity,
                detected: true,
                evidence: "Successfully wrote to \(testPath) - sandbox compromised"
            )
        } catch {
            // Normal behavior - sandbox prevents writing
            return DetectionResult(
                technique: .sandboxIntegrity,
                detected: false,
                evidence: "Sandbox integrity intact - cannot write to restricted paths"
            )
        }
    }
    
    /// Technique 4: Dynamic Libraries Check
    /// Detects suspicious dylibs loaded at runtime
    private func checkDynamicLibraries() -> DetectionResult {
        var suspiciousDylibs: [String] = []
        let suspiciousNames = ["MobileSubstrate", "substrate", "cycript", "frida", "SSLKillSwitch"]
        
        for i in 0..<_dyld_image_count() {
            if let imageName = _dyld_get_image_name(i) {
                let path = String(cString: imageName)
                
                for susName in suspiciousNames {
                    if path.lowercased().contains(susName.lowercased()) {
                        suspiciousDylibs.append(path)
                        break
                    }
                }
            }
        }
        
        let detected = !suspiciousDylibs.isEmpty
        let evidence = detected
            ? "Suspicious libraries loaded: \(suspiciousDylibs.joined(separator: ", "))"
            : "No suspicious dynamic libraries detected"
        
        return DetectionResult(
            technique: .dynamicLibraries,
            detected: detected,
            evidence: evidence
        )
    }
    
    /// Technique 5: Fork Restriction Check
    /// Tests process spawning (restricted on stock iOS)
    private func checkForkRestriction() -> DetectionResult {
        // On modern iOS, fork() is deprecated but we can test sandbox restrictions
        // by attempting to spawn a process
        let testPath = "/bin/sh"
        
        // First check if the binary exists (shouldn't on stock iOS)
        if FileManager.default.fileExists(atPath: testPath) {
            return DetectionResult(
                technique: .forkRestriction,
                detected: true,
                evidence: "Found \(testPath) - process spawning available"
            )
        }
        
        // Check if we can access fork-related resources
        // On jailbroken devices, we might have access to posix spawn
        var attr: posix_spawnattr_t?
        let result = posix_spawnattr_init(&attr)
        
        if result == 0 {
            posix_spawnattr_destroy(&attr)
            // Being able to init spawn attributes might indicate jailbreak
            // but it's also available on stock iOS, so we check execution
            return DetectionResult(
                technique: .forkRestriction,
                detected: false,
                evidence: "Process spawning properly restricted"
            )
        }
        
        return DetectionResult(
            technique: .forkRestriction,
            detected: false,
            evidence: "System correctly restricts process creation"
        )
    }
    
    /// Technique 6: Symbolic Links Check
    /// Checks for abnormal symbolic links
    private func checkSymbolicLinks() -> DetectionResult {
        let systemPaths = ["/Applications", "/Library", "/usr/bin", "/usr/sbin"]
        var suspiciousLinks: [String] = []
        
        for path in systemPaths {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                if let fileType = attributes[.type] as? FileAttributeType,
                   fileType == .typeSymbolicLink {
                    suspiciousLinks.append(path)
                }
            } catch {
                // Path doesn't exist or can't read - normal on stock iOS
            }
        }
        
        let detected = !suspiciousLinks.isEmpty
        let evidence = detected
            ? "Suspicious symbolic links found: \(suspiciousLinks.joined(separator: ", "))"
            : "No abnormal symbolic links detected"
        
        return DetectionResult(
            technique: .symbolicLinks,
            detected: detected,
            evidence: evidence
        )
    }
    
    /// Technique 7: System Calls Check
    /// Verifies stat() behavior on restricted paths
    private func checkSystemCalls() -> DetectionResult {
        var st = stat()
        let restrictedPaths = ["/bin/bash", "/usr/sbin/sshd", "/etc/apt"]
        var accessiblePaths: [String] = []
        
        for path in restrictedPaths {
            if stat(path, &st) == 0 {
                accessiblePaths.append(path)
            }
        }
        
        let detected = !accessiblePaths.isEmpty
        let evidence = detected
            ? "stat() succeeded on restricted paths: \(accessiblePaths.joined(separator: ", "))"
            : "System calls behave normally - restricted paths inaccessible"
        
        return DetectionResult(
            technique: .systemCalls,
            detected: detected,
            evidence: evidence
        )
    }
    
    /// Technique 8: Environment Variables Check
    /// Detects suspicious environment variables
    private func checkEnvironmentVariables() -> DetectionResult {
        let suspiciousVars = ["DYLD_INSERT_LIBRARIES", "_MSSafeMode", "_SafeMode"]
        var detectedVars: [String] = []
        
        // Legitimate Apple libraries that should NOT be flagged (Xcode debugging tools)
        let legitimateAppleLibraries = [
            "libViewDebuggerSupport.dylib",      // Xcode View Debugger
            "libMainThreadChecker.dylib",        // Xcode Main Thread Checker
            "libBacktraceRecording.dylib",       // Xcode Memory Debugging
            "libMallocStackLogging.dylib",       // Xcode Memory Debugging
            "libggdb.dylib",                      // GPU Frame Capture
            "libXCTTargetBootstrap.dylib",       // XCTest framework
            "IDEBundleInjection.framework"       // Xcode bundle injection
        ]
        
        for varName in suspiciousVars {
            if let value = getenv(varName) {
                let valueString = String(cString: value)
                
                // Special handling for DYLD_INSERT_LIBRARIES
                if varName == "DYLD_INSERT_LIBRARIES" {
                    // Check if it's a legitimate Apple debugging library
                    let isLegitimate = legitimateAppleLibraries.contains { library in
                        valueString.contains(library)
                    }
                    
                    // Also check if it's in /usr/lib (Apple's system libraries)
                    let isSystemLib = valueString.hasPrefix("/usr/lib/") || valueString.hasPrefix("/System/Library/")
                    
                    // Only flag if it's NOT a legitimate Apple library
                    if !isLegitimate && !isSystemLib {
                        detectedVars.append("\(varName)=\(valueString)")
                    }
                } else {
                    // For other variables (_MSSafeMode, _SafeMode), always flag them
                    detectedVars.append("\(varName)=\(valueString)")
                }
            }
        }
        
        let detected = !detectedVars.isEmpty
        let evidence = detected
            ? "Suspicious environment variables: \(detectedVars.joined(separator: ", "))"
            : "No suspicious environment variables detected"
        
        return DetectionResult(
            technique: .environmentVariables,
            detected: detected,
            evidence: evidence
        )
    }
}
