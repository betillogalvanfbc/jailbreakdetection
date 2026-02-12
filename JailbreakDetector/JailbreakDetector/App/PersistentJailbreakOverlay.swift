//
//  PersistentJailbreakOverlay.swift
//  Overlay que aparece CADA VEZ que se abre la app en dispositivo jailbroken
//
//  Uso: .persistentJailbreakProtection() en lugar de .jailbreakProtection()
//

import SwiftUI

/// Modifier que muestra overlay CADA VEZ que se abre la app (foreground)
struct PersistentJailbreakOverlayModifier: ViewModifier {
    @State private var isJailbroken = false
    @State private var threatsDetected = 0
    @State private var showOverlay = false
    @State private var isChecking = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: showOverlay ? 10 : 0)
            
            if isChecking {
                ProgressView("Verificando seguridad...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
            
            if showOverlay {
                // Overlay de jailbreak
                jailbreakOverlayView
            }
        }
        .animation(.spring(), value: showOverlay)
        .onAppear {
            // Primera vez que se abre la app
            checkJailbreak()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // CADA VEZ que la app regresa a foreground
            checkJailbreak()
        }
    }
    
    private var jailbreakOverlayView: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Icono de alerta (cambia según el estado)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isJailbroken ? [.red, .orange] : [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: isJailbroken ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                }
                .shadow(color: isJailbroken ? .red.opacity(0.5) : .green.opacity(0.5), radius: 20)
                
                // Título (cambia según el estado)
                Text(isJailbroken ? "⚠️ JAILBREAK DETECTADO" : "✅ DISPOSITIVO SEGURO")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                
                // Mensaje (cambia según el estado)
                VStack(spacing: 8) {
                    Text(isJailbroken ? "Este dispositivo ha sido modificado" : "Tu dispositivo está protegido")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(isJailbroken 
                        ? "\(threatsDetected) amenazas de seguridad detectadas" 
                        : "Todas las verificaciones de seguridad pasaron")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                // Explicación (cambia según el estado)
                Text(isJailbroken 
                    ? "Por razones de seguridad, esta aplicación tiene funcionalidad limitada en dispositivos con jailbreak." 
                    : "El análisis de seguridad no detectó modificaciones en el sistema.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Timestamp
                Text("Verificado: \(Date().formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                // Acciones (botón Continuar siempre, Salir solo si hay jailbreak)
                HStack(spacing: 16) {
                    Button {
                        // Continuar (registrar y cerrar modal)
                        showOverlay = false
                        logSecurityCheck()
                    } label: {
                        Text("Continuar")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isJailbroken ? Color.white.opacity(0.2) : Color.green)
                            .cornerRadius(12)
                    }
                    
                    if isJailbroken {
                        Button {
                            // Cerrar app
                            exit(0)
                        } label: {
                            Text("Salir")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
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
        }
    }
    
    private func checkJailbreak() {
        isChecking = true
        
        let detector = JailbreakDetector()
        detector.performFullScan()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isChecking = false
            self.isJailbroken = detector.isJailbroken
            self.threatsDetected = detector.threatsDetected
            self.showOverlay = true  // ✅ SIEMPRE mostrar el modal
            
            // Log apropiado según el estado
            if detector.isJailbroken {
                print("⚠️ JAILBREAK DETECTED - \(self.threatsDetected) threats")
            } else {
                print("✅ DEVICE SECURE - All checks passed")
            }
        }
    }
    
    private func logSecurityCheck() {
        // Aquí puedes enviar a analytics, backend, etc.
        let timestamp = Date()
        UserDefaults.standard.set(timestamp, forKey: "last_security_check")
        
        // Ejemplo: Enviar a analytics
        // Analytics.logEvent("security_check_dismissed", parameters: [
        //     "isJailbroken": isJailbroken,
        //     "threats": threatsDetected,
        //     "timestamp": timestamp
        // ])
        
        if isJailbroken {
            print("📊 User dismissed jailbreak warning at \(timestamp)")
        } else {
            print("📊 User acknowledged secure status at \(timestamp)")
        }
    }
}

// MARK: - View Extension

extension View {
    /// Protección de jailbreak PERSISTENTE - aparece cada vez que se abre la app
    func persistentJailbreakProtection() -> some View {
        modifier(PersistentJailbreakOverlayModifier())
    }
}

// MARK: - Ejemplo de Uso

/*
 USO EN TU APP:
 
 @main
 struct MiApp: App {
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .persistentJailbreakProtection() // ✅ Verifica CADA VEZ que se abre
         }
     }
 }
 
 COMPORTAMIENTO:
 1. Usuario abre la app → Verifica jailbreak
 2. Usuario cierra la app (background)
 3. Usuario vuelve a abrir → Verifica de nuevo ✅
 4. Se repite CADA VEZ
 
 */

// MARK: - Versión con Control de Frecuencia

/// Modifier que verifica pero solo muestra el overlay cada X horas
struct ThrottledJailbreakOverlay: ViewModifier {
    @State private var isJailbroken = false
    @State private var showOverlay = false
    
    let minimumHoursBetweenWarnings: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if showOverlay {
                // Tu overlay aquí
                Text("Jailbreak detected")
            }
        }
        .onAppear {
            checkIfShouldShow()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkIfShouldShow()
        }
    }
    
    private func checkIfShouldShow() {
        let detector = JailbreakDetector()
        detector.performFullScan()
        
        guard detector.isJailbroken else { return }
        
        // Verificar última vez que se mostró
        if let lastShown = UserDefaults.standard.object(forKey: "last_warning_shown") as? Date {
            let hoursSince = Date().timeIntervalSince(lastShown) / 3600
            
            if hoursSince >= minimumHoursBetweenWarnings {
                showOverlay = true
                UserDefaults.standard.set(Date(), forKey: "last_warning_shown")
            }
        } else {
            // Primera vez
            showOverlay = true
            UserDefaults.standard.set(Date(), forKey: "last_warning_shown")
        }
    }
}

extension View {
    /// Muestra overlay pero con throttling (máximo cada X horas)
    func throttledJailbreakProtection(minimumHours: Double = 24) -> some View {
        modifier(ThrottledJailbreakOverlay(minimumHoursBetweenWarnings: minimumHours))
    }
}

// Uso:
// ContentView()
//     .throttledJailbreakProtection(minimumHours: 12) // Máximo cada 12 horas
