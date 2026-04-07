//
//  CryptoService.swift
//  SecureDataManager
//
//  Servicio de cifrado usando AES-256-GCM con CryptoKit
//

import Foundation
import CryptoKit
import CommonCrypto

/// Errores de cifrado
enum CryptoError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    case invalidData
    case authenticationFailed
    case derivationFailed
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Error al cifrar los datos"
        case .decryptionFailed:
            return "Error al descifrar los datos"
        case .invalidKey:
            return "Clave de cifrado inválida"
        case .invalidData:
            return "Datos inválidos"
        case .authenticationFailed:
            return "Autenticación fallida - los datos pueden haber sido alterados"
        case .derivationFailed:
            return "Error al derivar la clave"
        }
    }
}

/// Resultado del cifrado
struct EncryptionResult {
    let ciphertext: Data
    let nonce: Data
    let tag: Data
}

/// Servicio de cifrado usando AES-256-GCM (AEAD)
class CryptoService {
    
    // MARK: - Generación de Claves
    
    /// Genera una nueva clave simétrica aleatoria de 256 bits
    func generateKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    /// Deriva una clave de 256 bits desde una contraseña usando PBKDF2
    /// - Parameters:
    ///   - password: Contraseña del usuario
    ///   - salt: Salt único (debe almacenarse junto con el hash)
    ///   - iterations: Número de iteraciones (recomendado: 600,000+)
    /// - Returns: SymmetricKey derivada
    func deriveKey(from password: String, salt: Data, iterations: UInt32 = 600_000) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw CryptoError.derivationFailed
        }
        
        var derivedKeyData = Data(count: 32) // 256 bits
        
        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress,
                        32
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            throw CryptoError.derivationFailed
        }
        
        return SymmetricKey(data: derivedKeyData)
    }
    
    /// Genera un salt criptográficamente seguro
    func generateSalt(length: Int = 32) -> Data {
        var salt = Data(count: length)
        _ = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        return salt
    }
    
    // MARK: - Cifrado AES-256-GCM
    
    /// Cifra datos usando AES-256-GCM
    /// - Parameters:
    ///   - data: Datos a cifrar
    ///   - key: Clave simétrica de 256 bits
    /// - Returns: Resultado del cifrado (ciphertext, nonce, tag)
    func encrypt(data: Data, key: SymmetricKey) throws -> EncryptionResult {
        do {
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            
            return EncryptionResult(
                ciphertext: sealedBox.ciphertext,
                nonce: Data(nonce),
                tag: sealedBox.tag
            )
        } catch {
            throw CryptoError.encryptionFailed
        }
    }
    
    /// Cifra un string usando AES-256-GCM
    /// - Parameters:
    ///   - string: String a cifrar
    ///   - key: Clave simétrica de 256 bits
    /// - Returns: Resultado del cifrado
    func encrypt(string: String, key: SymmetricKey) throws -> EncryptionResult {
        guard let data = string.data(using: .utf8) else {
            throw CryptoError.invalidData
        }
        return try encrypt(data: data, key: key)
    }
    
    // MARK: - Descifrado AES-256-GCM
    
    /// Descifra datos usando AES-256-GCM
    /// - Parameters:
    ///   - ciphertext: Datos cifrados
    ///   - nonce: Nonce usado en el cifrado
    ///   - tag: Tag de autenticación
    ///   - key: Clave simétrica
    /// - Returns: Datos descifrados
    func decryptData(ciphertext: Data, nonce: Data, tag: Data, key: SymmetricKey) throws -> Data {
        do {
            let nonce = try AES.GCM.Nonce(data: nonce)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch CryptoKitError.authenticationFailure {
            throw CryptoError.authenticationFailed
        } catch {
            throw CryptoError.decryptionFailed
        }
    }
    
    /// Descifra datos y retorna un String
    /// - Parameters:
    ///   - ciphertext: Datos cifrados
    ///   - nonce: Nonce usado en el cifrado
    ///   - tag: Tag de autenticación
    ///   - key: Clave simétrica
    /// - Returns: String descifrado
    func decrypt(ciphertext: Data, nonce: Data, tag: Data, key: SymmetricKey) throws -> String {
        let data = try decryptData(ciphertext: ciphertext, nonce: nonce, tag: tag, key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        return string
    }
    
    // MARK: - Hashing de Contraseñas
    
    /// Genera un hash seguro de contraseña usando PBKDF2
    /// - Parameters:
    ///   - password: Contraseña a hashear
    ///   - salt: Salt único
    /// - Returns: Hash de la contraseña
    func hashPassword(_ password: String, salt: Data) throws -> Data {
        let key = try deriveKey(from: password, salt: salt)
        return key.withUnsafeBytes { Data($0) }
    }
    
    /// Verifica una contraseña contra un hash
    /// - Parameters:
    ///   - password: Contraseña a verificar
    ///   - hash: Hash almacenado
    ///   - salt: Salt usado
    /// - Returns: true si la contraseña coincide
    func verifyPassword(_ password: String, against hash: Data, salt: Data) throws -> Bool {
        let computedHash = try hashPassword(password, salt: salt)
        return computedHash.constantTimeCompare(to: hash)
    }
    
    // MARK: - Encriptación de Master Key
    
    /// Encripta la master key usando una clave derivada de la contraseña
    /// - Parameters:
    ///   - masterKey: La master key a proteger
    ///   - password: Contraseña del usuario
    ///   - salt: Salt para derivación
    /// - Returns: Datos encriptados de la master key (nonce + ciphertext + tag)
    func encryptMasterKey(_ masterKey: SymmetricKey, password: String, salt: Data) throws -> Data {
        let derivedKey = try deriveKey(from: password, salt: salt)
        let sealedBox = try AES.GCM.seal(masterKey.withUnsafeBytes { Data($0) }, using: derivedKey)
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }
        return combined
    }
    
    /// Desencripta la master key usando una clave derivada de la contraseña
    /// - Parameters:
    ///   - encryptedData: Datos encriptados (nonce + ciphertext + tag)
    ///   - password: Contraseña del usuario
    ///   - salt: Salt para derivación
    /// - Returns: Master key desencriptada
    func decryptMasterKey(_ encryptedData: Data, password: String, salt: Data) throws -> SymmetricKey {
        let derivedKey = try deriveKey(from: password, salt: salt)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: derivedKey)
        return SymmetricKey(data: decryptedData)
    }
    
    /// Encripta la master key directamente con una clave proporcionada
    /// - Parameters:
    ///   - masterKey: La master key a proteger
    ///   - key: Clave para encriptar
    /// - Returns: Datos encriptados
    func encryptMasterKey(_ masterKey: SymmetricKey, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(masterKey.withUnsafeBytes { Data($0) }, using: key)
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }
        return combined
    }
    
    /// Desencripta la master key directamente con una clave proporcionada
    /// - Parameters:
    ///   - encryptedData: Datos encriptados
    ///   - key: Clave para desencriptar
    /// - Returns: Master key desencriptada
    func decryptMasterKey(_ encryptedData: Data, key: SymmetricKey) throws -> SymmetricKey {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return SymmetricKey(data: decryptedData)
    }
}

// MARK: - Extensiones de seguridad

extension Data {
    /// Comparación en tiempo constante para prevenir timing attacks
    func constantTimeCompare(to other: Data) -> Bool {
        guard count == other.count else { return false }
        return zip(self, other).reduce(0) { $0 | (UInt8($1.0) ^ UInt8($1.1)) } == 0
    }
}
