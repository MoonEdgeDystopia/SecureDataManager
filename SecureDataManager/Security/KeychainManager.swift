//
//  KeychainManager.swift
//  SecureDataManager
//
//  Gestión segura de claves usando Keychain
//

import Foundation
import Security
import CryptoKit

/// Errores de Keychain
enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidStatus(OSStatus)
    case conversionFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Elemento no encontrado en Keychain"
        case .duplicateItem:
            return "El elemento ya existe en Keychain"
        case .invalidStatus(let status):
            return "Error de Keychain: \(status)"
        case .conversionFailed:
            return "Error al convertir datos"
        case .invalidData:
            return "Datos inválidos"
        }
    }
}

/// Gestor de Keychain para almacenamiento seguro de claves
class KeychainManager {
    
    static let shared = KeychainManager()
    
    private let service = "com.securedatamanager.app"
    private let accessGroup: String? = nil
    
    private init() {}
    
    // MARK: - Clave Maestra
    
    /// Guarda la clave maestra en Keychain
    func saveMasterKey(_ key: SymmetricKey) throws {
        let keyData = key.data
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "masterKey",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Actualizar si ya existe
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "masterKey"
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: keyData
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.invalidStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.invalidStatus(status)
        }
    }
    
    /// Recupera la clave maestra del Keychain
    func getMasterKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "masterKey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.invalidStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.conversionFailed
        }
        
        return SymmetricKey(data: data)
    }
    
    /// Elimina la clave maestra del Keychain
    func deleteMasterKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "masterKey"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.invalidStatus(status)
        }
    }
    
    // MARK: - Salt
    
    /// Guarda el salt para derivación de clave
    func saveSalt(_ salt: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "passwordSalt",
            kSecValueData as String: salt,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "passwordSalt"
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: salt
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.invalidStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.invalidStatus(status)
        }
    }
    
    /// Recupera el salt
    func getSalt() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "passwordSalt",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.invalidStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.conversionFailed
        }
        
        return data
    }
    
    // MARK: - Hash de Contraseña
    
    /// Guarda el hash de la contraseña
    func savePasswordHash(_ hash: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "passwordHash",
            kSecValueData as String: hash,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "passwordHash"
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: hash
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.invalidStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.invalidStatus(status)
        }
    }
    
    /// Recupera el hash de la contraseña
    func getPasswordHash() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "passwordHash",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.invalidStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.conversionFailed
        }
        
        return data
    }
    
    // MARK: - Configuración Biométrica
    
    /// Guarda si la autenticación biométrica está habilitada
    func saveBiometricEnabled(_ enabled: Bool) throws {
        let value = enabled ? "1" : "0"
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.conversionFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "biometricEnabled",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "biometricEnabled"
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.invalidStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.invalidStatus(status)
        }
    }
    
    /// Verifica si la autenticación biométrica está habilitada
    func isBiometricEnabled() throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "biometricEnabled",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return false
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return false
        }
        
        return value == "1"
    }
    
    // MARK: - Master Key Encriptada
    
    /// Guarda la master key encriptada
    func saveEncryptedMasterKey(_ data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "encryptedMasterKey",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "encryptedMasterKey"
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.invalidStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.invalidStatus(status)
        }
    }
    
    /// Recupera la master key encriptada
    func getEncryptedMasterKey() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "encryptedMasterKey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.invalidStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.conversionFailed
        }
        
        return data
    }
    
    // MARK: - Datos de Recuperación
    
    /// Guarda los datos de recuperación
    func saveRecoveryData(_ data: RecoveryData) throws {
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(data)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "recoveryData",
            kSecValueData as String: encodedData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "recoveryData"
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: encodedData
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.invalidStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.invalidStatus(status)
        }
    }
    
    /// Recupera los datos de recuperación
    func getRecoveryData() throws -> RecoveryData? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "recoveryData",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.invalidStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.conversionFailed
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(RecoveryData.self, from: data)
    }
    
    // MARK: - Limpieza
    
    /// Elimina todos los datos de autenticación
    func clearAllAuthData() throws {
        try deleteMasterKey()
        
        let accounts = ["passwordSalt", "passwordHash", "biometricEnabled", "recoveryData", "encryptedMasterKey"]
        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}
