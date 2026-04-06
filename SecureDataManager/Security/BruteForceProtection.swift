//
//  BruteForceProtection.swift
//  SecureDataManager
//
//  Protección contra ataques de fuerza bruta
//

import Foundation
import Combine

/// Errores de protección contra fuerza bruta
enum BruteForceError: Error, LocalizedError {
    case tooManyAttempts(lockoutDuration: TimeInterval)
    case permanentlyLocked
    case dataWiped
    
    var errorDescription: String? {
        switch self {
        case .tooManyAttempts(let duration):
            let minutes = Int(duration / 60)
            if minutes < 1 {
                return "Demasiados intentos. Espere \(Int(duration)) segundos."
            } else {
                return "Demasiados intentos. Espere \(minutes) minutos."
            }
        case .permanentlyLocked:
            return "La aplicación está bloqueada permanentemente. Use la recuperación de clave."
        case .dataWiped:
            return "Los datos han sido borrados por seguridad tras demasiados intentos fallidos."
        }
    }
}

/// Gestiona la protección contra ataques de fuerza bruta
class BruteForceProtection: ObservableObject {
    
    static let shared = BruteForceProtection()
    
    @Published var isLocked: Bool = false
    @Published var lockoutEndTime: Date?
    @Published var remainingAttempts: Int = 5
    
    private let userDefaults = UserDefaults.standard
    private let failedAttemptsKey = "failedAuthAttempts"
    private let lastAttemptTimeKey = "lastFailedAttemptTime"
    private let lockoutEndTimeKey = "lockoutEndTime"
    private let totalAttemptsKey = "totalFailedAttempts"
    
    // Configuración
    private let maxAttemptsBeforeLockout = 5
    private let maxTotalAttempts = 10
    private let lockoutDurations: [TimeInterval] = [60, 300, 900, 3600] // 1min, 5min, 15min, 1hora
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkLockoutStatus()
        startMonitoring()
    }
    
    // MARK: - Estado de Bloqueo
    
    /// Verifica si la aplicación está actualmente bloqueada
    var isCurrentlyLocked: Bool {
        checkLockoutStatus()
        if let endTime = getLockoutEndTime() {
            return Date() < endTime
        }
        return false
    }
    
    /// Tiempo restante de bloqueo
    var remainingLockoutTime: TimeInterval {
        guard let endTime = getLockoutEndTime() else { return 0 }
        let remaining = endTime.timeIntervalSince(Date())
        return max(remaining, 0)
    }
    
    /// Número actual de intentos fallidos consecutivos
    var currentFailedAttempts: Int {
        return getFailedAttempts()
    }
    
    // MARK: - Registro de Intentos
    
    /// Registra un intento fallido de autenticación
    func recordFailedAttempt() throws {
        // Verificar si ya está bloqueado
        if isCurrentlyLocked {
            let remaining = remainingLockoutTime
            throw BruteForceError.tooManyAttempts(lockoutDuration: remaining)
        }
        
        // Incrementar contador de intentos fallidos
        let attempts = getFailedAttempts() + 1
        setFailedAttempts(attempts)
        
        // Incrementar contador total
        let totalAttempts = getTotalAttempts() + 1
        setTotalAttempts(totalAttempts)
        
        // Actualizar tiempo del último intento
        setLastAttemptTime(Date())
        
        // Verificar si se debe bloquear
        if attempts >= maxAttemptsBeforeLockout {
            applyLockout()
        }
        
        // Verificar si se debe borrar datos (después de maxTotalAttempts)
        if totalAttempts >= maxTotalAttempts {
            // En una implementación real, aquí se borrarían los datos
            // Por seguridad, solo bloqueamos permanentemente
            setLockoutEndTime(Date.distantFuture)
            throw BruteForceError.permanentlyLocked
        }
        
        updatePublishedValues()
    }
    
    /// Registra un intento exitoso de autenticación
    func recordSuccessfulAttempt() {
        // Resetear contador de intentos fallidos consecutivos
        setFailedAttempts(0)
        setLastAttemptTime(nil)
        setLockoutEndTime(nil)
        updatePublishedValues()
    }
    
    // MARK: - Bloqueo
    
    private func applyLockout() {
        let attempts = getFailedAttempts()
        let lockoutIndex = min((attempts / maxAttemptsBeforeLockout) - 1, lockoutDurations.count - 1)
        let duration = lockoutDurations[lockoutIndex]
        
        let endTime = Date().addingTimeInterval(duration)
        setLockoutEndTime(endTime)
        
        updatePublishedValues()
    }
    
    private func checkLockoutStatus() {
        updatePublishedValues()
    }
    
    private func startMonitoring() {
        // Monitorear cada segundo para actualizar la UI
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkLockoutStatus()
            }
            .store(in: &cancellables)
    }
    
    private func updatePublishedValues() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let now = Date()
            if let endTime = self.getLockoutEndTime(), now < endTime {
                self.isLocked = true
                self.lockoutEndTime = endTime
                self.remainingAttempts = 0
            } else {
                self.isLocked = false
                self.lockoutEndTime = nil
                let attempts = self.getFailedAttempts()
                self.remainingAttempts = max(0, self.maxAttemptsBeforeLockout - attempts)
                
                // Limpiar bloqueo expirado
                if let lockoutEnd = self.getLockoutEndTime(), now >= lockoutEnd {
                    self.setLockoutEndTime(nil)
                    self.setFailedAttempts(0)
                }
            }
        }
    }
    
    // MARK: - Persistencia (Ofuscada)
    
    private func getFailedAttempts() -> Int {
        // Ofuscar el valor almacenado
        let storedValue = userDefaults.integer(forKey: failedAttemptsKey)
        return storedValue > 0 ? storedValue - 12345 : 0
    }
    
    private func setFailedAttempts(_ value: Int) {
        let obfuscatedValue = value + 12345
        userDefaults.set(obfuscatedValue, forKey: failedAttemptsKey)
    }
    
    private func getTotalAttempts() -> Int {
        let storedValue = userDefaults.integer(forKey: totalAttemptsKey)
        return storedValue > 0 ? storedValue - 54321 : 0
    }
    
    private func setTotalAttempts(_ value: Int) {
        let obfuscatedValue = value + 54321
        userDefaults.set(obfuscatedValue, forKey: totalAttemptsKey)
    }
    
    private func getLastAttemptTime() -> Date? {
        return userDefaults.object(forKey: lastAttemptTimeKey) as? Date
    }
    
    private func setLastAttemptTime(_ date: Date?) {
        if let date = date {
            userDefaults.set(date, forKey: lastAttemptTimeKey)
        } else {
            userDefaults.removeObject(forKey: lastAttemptTimeKey)
        }
    }
    
    private func getLockoutEndTime() -> Date? {
        return userDefaults.object(forKey: lockoutEndTimeKey) as? Date
    }
    
    private func setLockoutEndTime(_ date: Date?) {
        if let date = date {
            userDefaults.set(date, forKey: lockoutEndTimeKey)
        } else {
            userDefaults.removeObject(forKey: lockoutEndTimeKey)
        }
    }
    
    // MARK: - Reset
    
    /// Resetea todos los contadores (usar con precaución)
    func reset() {
        setFailedAttempts(0)
        setTotalAttempts(0)
        setLastAttemptTime(nil)
        setLockoutEndTime(nil)
        updatePublishedValues()
    }
}
