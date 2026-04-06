//
//  AuthViewModel.swift
//  SecureDataManager
//
//  ViewModel para autenticación
//

import Foundation
import LocalAuthentication
import Combine
import CryptoKit

/// Estados de autenticación
enum AuthState {
    case unauthenticated
    case passwordVerified
    case fullyAuthenticated
    case locked
}

/// ViewModel para gestión de autenticación
class AuthViewModel: ObservableObject {
    
    @Published var authState: AuthState = .unauthenticated
    @Published var isBiometricAvailable: Bool = false
    @Published var biometricType: LABiometryType = .none
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var remainingAttempts: Int = 5
    
    private let context = LAContext()
    private var cancellables = Set<AnyCancellable>()
    
    // Referencia a la clave maestra en memoria (solo mientras está autenticado)
    private(set) var masterKey: SymmetricKey?
    
    init() {
        checkBiometricAvailability()
        setupBruteForceMonitoring()
    }
    
    // MARK: - Verificación de Biometría
    
    private func checkBiometricAvailability() {
        var error: NSError?
        isBiometricAvailable = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        biometricType = context.biometryType
    }
    
    /// Verifica si la autenticación biométrica está habilitada en la app
    var isBiometricEnabled: Bool {
        return (try? KeychainManager.shared.isBiometricEnabled()) ?? false
    }
    
    // MARK: - Autenticación
    
    /// Paso 1: Verificar contraseña
    func verifyPassword(_ password: String) async -> Bool {
        await MainActor.run { isLoading = true }
        
        do {
            // Verificar bloqueo por fuerza bruta
            if BruteForceProtection.shared.isCurrentlyLocked {
                let remaining = BruteForceProtection.shared.remainingLockoutTime
                await MainActor.run {
                    errorMessage = "Demasiados intentos. Espere \(Int(remaining/60)) minutos."
                    isLoading = false
                }
                return false
            }
            
            // Recuperar salt y hash almacenados
            guard let salt = try KeychainManager.shared.getSalt(),
                  let storedHash = try KeychainManager.shared.getPasswordHash() else {
                await MainActor.run {
                    errorMessage = "Configuración inicial requerida"
                    isLoading = false
                }
                return false
            }
            
            // Verificar contraseña
            let cryptoService = CryptoService()
            let isValid = try cryptoService.verifyPassword(password, against: storedHash, salt: salt)
            
            if isValid {
                // Derivar clave maestra
                masterKey = try cryptoService.deriveKey(from: password, salt: salt)
                
                await MainActor.run {
                    BruteForceProtection.shared.recordSuccessfulAttempt()
                    authState = .passwordVerified
                    errorMessage = nil
                    isLoading = false
                }
                return true
            } else {
                try BruteForceProtection.shared.recordFailedAttempt()
                await MainActor.run {
                    errorMessage = "Contraseña incorrecta"
                    isLoading = false
                }
                return false
            }
            
        } catch let error as BruteForceError {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            return false
        } catch {
            await MainActor.run {
                errorMessage = "Error de autenticación"
                isLoading = false
            }
            return false
        }
    }
    
    /// Paso 2: Autenticación biométrica (con fallback a PIN del dispositivo)
    func authenticateWithBiometric() async -> Bool {
        guard isBiometricEnabled else {
            // Si la biometría no está habilitada, saltar al estado completamente autenticado
            await MainActor.run {
                authState = .fullyAuthenticated
            }
            return true
        }
        
        let context = LAContext()
        let reason = "Autenticación requerida para acceder a tus datos seguros"
        
        do {
            // Usar .deviceOwnerAuthentication que incluye biometría + PIN/código como fallback
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            await MainActor.run {
                if success {
                    authState = .fullyAuthenticated
                }
            }
            
            return success
        } catch let error as LAError {
            await MainActor.run {
                switch error.code {
                case .userCancel:
                    errorMessage = "Autenticación cancelada"
                case .biometryNotAvailable:
                    // Si la biometría no está disponible, permitir acceso con solo contraseña
                    authState = .fullyAuthenticated
                case .biometryNotEnrolled:
                    errorMessage = "No hay biometría configurada. Configura Face ID/Touch ID en Ajustes."
                default:
                    errorMessage = "Autenticación fallida: \(error.localizedDescription)"
                }
            }
            return error.code == .biometryNotAvailable
        } catch {
            await MainActor.run {
                errorMessage = "Autenticación fallida"
            }
            return false
        }
    }
    
    /// Autenticación completa (contraseña + biometría)
    func authenticate(password: String) async -> Bool {
        let passwordValid = await verifyPassword(password)
        guard passwordValid else { return false }
        
        return await authenticateWithBiometric()
    }
    
    // MARK: - Setup
    
    /// Configura la contraseña inicial
    func setupPassword(_ password: String) throws {
        let cryptoService = CryptoService()
        
        // Generar salt
        let salt = cryptoService.generateSalt()
        
        // Generar hash de contraseña
        let passwordHash = try cryptoService.hashPassword(password, salt: salt)
        
        // Derivar clave maestra
        let masterKey = try cryptoService.deriveKey(from: password, salt: salt)
        
        // Guardar en Keychain
        try KeychainManager.shared.saveSalt(salt)
        try KeychainManager.shared.savePasswordHash(passwordHash)
        try KeychainManager.shared.saveMasterKey(masterKey)
        
        self.masterKey = masterKey
    }
    
    /// Habilita autenticación biométrica
    func enableBiometric() throws {
        try KeychainManager.shared.saveBiometricEnabled(true)
    }
    
    /// Deshabilita autenticación biométrica
    func disableBiometric() throws {
        try KeychainManager.shared.saveBiometricEnabled(false)
    }
    
    // MARK: - Recuperación
    
    /// Verifica si el usuario ya tiene configuración
    var isConfigured: Bool {
        do {
            return try KeychainManager.shared.getPasswordHash() != nil
        } catch {
            return false
        }
    }
    
    /// Resetea la autenticación
    func logout() {
        masterKey = nil
        authState = .unauthenticated
    }
    
    /// Configura nueva contraseña después de recuperación
    func resetPassword(_ newPassword: String) throws {
        // Limpiar datos anteriores
        try KeychainManager.shared.clearAllAuthData()
        
        // Configurar nueva contraseña
        try setupPassword(newPassword)
        
        // Limpiar protección de fuerza bruta
        BruteForceProtection.shared.reset()
    }
    
    // MARK: - Monitoreo
    
    private func setupBruteForceMonitoring() {
        BruteForceProtection.shared.$remainingAttempts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] attempts in
                self?.remainingAttempts = attempts
            }
            .store(in: &cancellables)
        
        BruteForceProtection.shared.$isLocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLocked in
                if isLocked {
                    self?.authState = .locked
                }
            }
            .store(in: &cancellables)
    }
}
