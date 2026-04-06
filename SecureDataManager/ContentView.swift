//
//  ContentView.swift
//  SecureDataManager
//
//  Vista principal de la aplicación
//

import SwiftUI
import CryptoKit
import Combine

/// Singleton para compartir el estado de autenticación entre vistas
class AuthStateManager: ObservableObject {
    static let shared = AuthStateManager()
    
    @Published var masterKey: SymmetricKey?
    
    private init() {}
}

struct ContentView: View {
    
    @State private var isAuthenticated: Bool = false
    @State private var showSetup: Bool = false
    
    var body: some View {
        Group {
            if isAuthenticated, AuthStateManager.shared.masterKey != nil {
                // Usuario autenticado - mostrar contenido principal
                MainTabView(
                    isAuthenticated: $isAuthenticated,
                    masterKey: AuthStateManager.shared.masterKey!
                )
            } else if showSetup || !isConfigured() {
                // Configuración inicial
                SetupPasswordView(isSetupComplete: .init(
                    get: { isAuthenticated },
                    set: { completed in
                        if completed {
                            completeSetup()
                        }
                    }
                ))
            } else {
                // Pantalla de login
                LoginView(
                    isAuthenticated: .init(
                        get: { isAuthenticated },
                        set: { auth in
                            if auth {
                                isAuthenticated = true
                            }
                        }
                    ),
                    showSetup: $showSetup
                )
            }
        }
        .onAppear {
            // Por seguridad, reiniciar autenticación al iniciar
            isAuthenticated = false
            AuthStateManager.shared.masterKey = nil
        }
    }
    
    /// Verifica si ya hay configuración
    private func isConfigured() -> Bool {
        do {
            return try KeychainManager.shared.getPasswordHash() != nil
        } catch {
            return false
        }
    }
    
    /// Completa el proceso de setup
    private func completeSetup() {
        isAuthenticated = true
    }
}

#Preview {
    ContentView()
}
