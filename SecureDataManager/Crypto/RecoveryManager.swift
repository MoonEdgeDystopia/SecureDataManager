//
//  RecoveryManager.swift
//  SecureDataManager
//
//  Gestión de recuperación de cuenta
//

import Foundation
import CryptoKit
import CommonCrypto

/// Errores de recuperación
enum RecoveryError: Error, LocalizedError {
    case invalidAnswer
    case invalidCode
    case recoveryDataNotFound
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidAnswer:
            return "Una o más respuestas son incorrectas"
        case .invalidCode:
            return "El código de recuperación es incorrecto"
        case .recoveryDataNotFound:
            return "No se encontraron datos de recuperación"
        case .decryptionFailed:
            return "Error al desencriptar los datos"
        }
    }
}

/// Gestiona todo el proceso de recuperación de cuenta
class RecoveryManager {
    
    static let shared = RecoveryManager()
    
    private let cryptoService = CryptoService()
    
    private init() {}
    
    // MARK: - Generación de Datos de Recuperación
    
    /// Genera un código de recuperación aleatorio
    func generateRecoveryCode() throws -> String {
        var codeBytes = Data(count: 32)
        let result = codeBytes.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        guard result == errSecSuccess else {
            throw RecoveryError.decryptionFailed
        }
        return codeBytes.base64EncodedString()
    }
    
    /// Genera todos los datos necesarios para la recuperación (código externo)
    func generateRecoveryData(
        questions: [String],
        answers: [String],
        code: String,
        masterSalt: Data
    ) throws -> (recoveryData: RecoveryData, recoveryCode: String) {
        guard questions.count == 3 && answers.count == 3 else {
            throw NSError(domain: "RecoveryManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Se necesitan exactamente 3 preguntas y respuestas"])
        }
        
        // Generar salt para recuperación
        let recoverySalt = cryptoService.generateSalt(length: 32)
        
        // Hashear respuestas
        let answer1Hash = hashAnswer(answers[0], salt: recoverySalt)
        let answer2Hash = hashAnswer(answers[1], salt: recoverySalt)
        let answer3Hash = hashAnswer(answers[2], salt: recoverySalt)
        
        // Hashear código para verificación
        let recoveryCodeHash = hashAnswer(code, salt: recoverySalt)
        
        // Derivar clave de recuperación
        let recoveryKey = try deriveRecoveryKey(
            answers: answers,
            code: code,
            salt: recoverySalt
        )
        
        // Encriptar el salt maestro con la clave de recuperación
        let encryptedMasterSalt = try encryptMasterSalt(masterSalt, key: recoveryKey)
        
        let recoveryData = RecoveryData(
            question1: questions[0],
            answer1Hash: answer1Hash,
            question2: questions[1],
            answer2Hash: answer2Hash,
            question3: questions[2],
            answer3Hash: answer3Hash,
            recoveryCodeHash: recoveryCodeHash,
            recoverySalt: recoverySalt,
            encryptedMasterSalt: encryptedMasterSalt
        )
        
        return (recoveryData, code)
    }
    
    // MARK: - Verificación
    
    /// Verifica si las respuestas son correctas
    func verifyAnswers(
        answers: [String],
        recoveryData: RecoveryData
    ) -> Bool {
        guard answers.count == 3 else { return false }
        
        let hash1 = hashAnswer(answers[0], salt: recoveryData.recoverySalt)
        let hash2 = hashAnswer(answers[1], salt: recoveryData.recoverySalt)
        let hash3 = hashAnswer(answers[2], salt: recoveryData.recoverySalt)
        
        // Comparación en tiempo constante para prevenir timing attacks
        return constantTimeCompare(hash1, recoveryData.answer1Hash) &&
               constantTimeCompare(hash2, recoveryData.answer2Hash) &&
               constantTimeCompare(hash3, recoveryData.answer3Hash)
    }
    
    /// Verifica si el código de recuperación es correcto
    func verifyCode(
        code: String,
        recoveryData: RecoveryData
    ) -> Bool {
        let hash = hashAnswer(code, salt: recoveryData.recoverySalt)
        return constantTimeCompare(hash, recoveryData.recoveryCodeHash)
    }
    
    // MARK: - Recuperación
    
    /// Recupera el salt maestro usando respuestas y código
    func recoverMasterSalt(
        answers: [String],
        code: String,
        recoveryData: RecoveryData
    ) throws -> Data {
        // Verificar respuestas
        guard verifyAnswers(answers: answers, recoveryData: recoveryData) else {
            throw RecoveryError.invalidAnswer
        }
        
        // Verificar código
        guard verifyCode(code: code, recoveryData: recoveryData) else {
            throw RecoveryError.invalidCode
        }
        
        // Derivar clave de recuperación
        let recoveryKey = try deriveRecoveryKey(
            answers: answers,
            code: code,
            salt: recoveryData.recoverySalt
        )
        
        // Desencriptar salt maestro
        return try decryptMasterSalt(
            recoveryData.encryptedMasterSalt,
            key: recoveryKey
        )
    }
    
    // MARK: - Helpers Privados
    
    /// Hashea una respuesta con salt
    private func hashAnswer(_ answer: String, salt: Data) -> Data {
        guard let answerData = answer.lowercased().trimmingCharacters(in: .whitespaces).data(using: .utf8) else {
            return Data()
        }
        
        // Usar PBKDF2 para hashear
        var derivedKeyData = Data(count: 32)
        let saltData = salt
        
        _ = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            saltData.withUnsafeBytes { saltBytes in
                answerData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        answerData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        saltData.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        100000, // 100k iteraciones
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress,
                        32
                    )
                }
            }
        }
        
        return derivedKeyData
    }
    
    /// Deriva la clave de recuperación combinando respuestas y código
    private func deriveRecoveryKey(
        answers: [String],
        code: String,
        salt: Data
    ) throws -> SymmetricKey {
        // Combinar respuestas en orden
        let combinedAnswers = answers
            .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            .joined(separator: "|")
        
        // Combinar con código
        let combinedString = combinedAnswers + "|" + code
        
        guard let combinedData = combinedString.data(using: .utf8) else {
            throw RecoveryError.decryptionFailed
        }
        
        // Derivar clave usando PBKDF2
        var derivedKeyData = Data(count: 32)
        
        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                combinedData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        combinedData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        600000, // 600k iteraciones (igual que contraseña)
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress,
                        32
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            throw RecoveryError.decryptionFailed
        }
        
        return SymmetricKey(data: derivedKeyData)
    }
    
    /// Encripta el salt maestro
    private func encryptMasterSalt(_ salt: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(salt, using: key)
            guard let combined = sealedBox.combined else {
                throw RecoveryError.decryptionFailed
            }
            return combined
        } catch {
            throw RecoveryError.decryptionFailed
        }
    }
    
    /// Desencripta el salt maestro
    private func decryptMasterSalt(_ encryptedData: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw RecoveryError.decryptionFailed
        }
    }
    
    /// Comparación en tiempo constante para prevenir timing attacks
    private func constantTimeCompare(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var result: UInt8 = 0
        for i in 0..<a.count {
            result |= a[i] ^ b[i]
        }
        return result == 0
    }
}
