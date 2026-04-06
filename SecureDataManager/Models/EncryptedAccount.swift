//
//  EncryptedAccount.swift
//  SecureDataManager
//
//  Modelo para almacenar cuentas con credenciales cifradas
//

import Foundation
import CryptoKit

/// Representa una cuenta con todos sus campos sensibles cifrados individualmente
struct EncryptedAccount: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    
    // Campos cifrados (almacenados como Data)
    var encryptedServiceName: Data
    var encryptedServiceNameNonce: Data
    var encryptedServiceNameTag: Data
    
    var encryptedUsername: Data?
    var encryptedUsernameNonce: Data?
    var encryptedUsernameTag: Data?
    
    var encryptedEmail: Data?
    var encryptedEmailNonce: Data?
    var encryptedEmailTag: Data?
    
    var encryptedPassword: Data
    var encryptedPasswordNonce: Data
    var encryptedPasswordTag: Data
    
    var encryptedNotes: Data?
    var encryptedNotesNonce: Data?
    var encryptedNotesTag: Data?
    
    var encryptedTOTPSecret: Data?
    var encryptedTOTPSecretNonce: Data?
    var encryptedTOTPSecretTag: Data?
    
    // Metadata no sensible (para búsqueda/organización sin descifrar)
    var categoryIcon: String
    var lastAccessed: Date?
    
    init(
        id: UUID = UUID(),
        serviceName: String,
        username: String?,
        email: String?,
        password: String,
        notes: String?,
        totpSecret: String?,
        encryptionKey: SymmetricKey
    ) throws {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.categoryIcon = "key.fill"
        
        let cryptoService = CryptoService()
        
        // Cifrar cada campo individualmente con su propio nonce
        let serviceNameResult = try cryptoService.encrypt(string: serviceName, key: encryptionKey)
        self.encryptedServiceName = serviceNameResult.ciphertext
        self.encryptedServiceNameNonce = serviceNameResult.nonce
        self.encryptedServiceNameTag = serviceNameResult.tag
        
        if let username = username, !username.isEmpty {
            let usernameResult = try cryptoService.encrypt(string: username, key: encryptionKey)
            self.encryptedUsername = usernameResult.ciphertext
            self.encryptedUsernameNonce = usernameResult.nonce
            self.encryptedUsernameTag = usernameResult.tag
        }
        
        if let email = email, !email.isEmpty {
            let emailResult = try cryptoService.encrypt(string: email, key: encryptionKey)
            self.encryptedEmail = emailResult.ciphertext
            self.encryptedEmailNonce = emailResult.nonce
            self.encryptedEmailTag = emailResult.tag
        }
        
        let passwordResult = try cryptoService.encrypt(string: password, key: encryptionKey)
        self.encryptedPassword = passwordResult.ciphertext
        self.encryptedPasswordNonce = passwordResult.nonce
        self.encryptedPasswordTag = passwordResult.tag
        
        if let notes = notes, !notes.isEmpty {
            let notesResult = try cryptoService.encrypt(string: notes, key: encryptionKey)
            self.encryptedNotes = notesResult.ciphertext
            self.encryptedNotesNonce = notesResult.nonce
            self.encryptedNotesTag = notesResult.tag
        }
        
        if let totpSecret = totpSecret, !totpSecret.isEmpty {
            let totpResult = try cryptoService.encrypt(string: totpSecret, key: encryptionKey)
            self.encryptedTOTPSecret = totpResult.ciphertext
            self.encryptedTOTPSecretNonce = totpResult.nonce
            self.encryptedTOTPSecretTag = totpResult.tag
        }
    }
    
    // MARK: - Descifrado
    
    func decryptServiceName(key: SymmetricKey) throws -> String {
        let cryptoService = CryptoService()
        return try cryptoService.decrypt(
            ciphertext: encryptedServiceName,
            nonce: encryptedServiceNameNonce,
            tag: encryptedServiceNameTag,
            key: key
        )
    }
    
    func decryptUsername(key: SymmetricKey) throws -> String? {
        guard let encrypted = encryptedUsername,
              let nonce = encryptedUsernameNonce,
              let tag = encryptedUsernameTag else { return nil }
        let cryptoService = CryptoService()
        return try cryptoService.decrypt(ciphertext: encrypted, nonce: nonce, tag: tag, key: key)
    }
    
    func decryptEmail(key: SymmetricKey) throws -> String? {
        guard let encrypted = encryptedEmail,
              let nonce = encryptedEmailNonce,
              let tag = encryptedEmailTag else { return nil }
        let cryptoService = CryptoService()
        return try cryptoService.decrypt(ciphertext: encrypted, nonce: nonce, tag: tag, key: key)
    }
    
    func decryptPassword(key: SymmetricKey) throws -> String {
        let cryptoService = CryptoService()
        return try cryptoService.decrypt(
            ciphertext: encryptedPassword,
            nonce: encryptedPasswordNonce,
            tag: encryptedPasswordTag,
            key: key
        )
    }
    
    func decryptNotes(key: SymmetricKey) throws -> String? {
        guard let encrypted = encryptedNotes,
              let nonce = encryptedNotesNonce,
              let tag = encryptedNotesTag else { return nil }
        let cryptoService = CryptoService()
        return try cryptoService.decrypt(ciphertext: encrypted, nonce: nonce, tag: tag, key: key)
    }
    
    func decryptTOTPSecret(key: SymmetricKey) throws -> String? {
        guard let encrypted = encryptedTOTPSecret,
              let nonce = encryptedTOTPSecretNonce,
              let tag = encryptedTOTPSecretTag else { return nil }
        let cryptoService = CryptoService()
        return try cryptoService.decrypt(ciphertext: encrypted, nonce: nonce, tag: tag, key: key)
    }
    
    // MARK: - Actualización
    
    mutating func update(
        serviceName: String,
        username: String?,
        email: String?,
        password: String,
        notes: String?,
        totpSecret: String?,
        encryptionKey: SymmetricKey
    ) throws {
        self.updatedAt = Date()
        
        let cryptoService = CryptoService()
        
        let serviceNameResult = try cryptoService.encrypt(string: serviceName, key: encryptionKey)
        self.encryptedServiceName = serviceNameResult.ciphertext
        self.encryptedServiceNameNonce = serviceNameResult.nonce
        self.encryptedServiceNameTag = serviceNameResult.tag
        
        if let username = username, !username.isEmpty {
            let usernameResult = try cryptoService.encrypt(string: username, key: encryptionKey)
            self.encryptedUsername = usernameResult.ciphertext
            self.encryptedUsernameNonce = usernameResult.nonce
            self.encryptedUsernameTag = usernameResult.tag
        } else {
            self.encryptedUsername = nil
            self.encryptedUsernameNonce = nil
            self.encryptedUsernameTag = nil
        }
        
        if let email = email, !email.isEmpty {
            let emailResult = try cryptoService.encrypt(string: email, key: encryptionKey)
            self.encryptedEmail = emailResult.ciphertext
            self.encryptedEmailNonce = emailResult.nonce
            self.encryptedEmailTag = emailResult.tag
        } else {
            self.encryptedEmail = nil
            self.encryptedEmailNonce = nil
            self.encryptedEmailTag = nil
        }
        
        let passwordResult = try cryptoService.encrypt(string: password, key: encryptionKey)
        self.encryptedPassword = passwordResult.ciphertext
        self.encryptedPasswordNonce = passwordResult.nonce
        self.encryptedPasswordTag = passwordResult.tag
        
        if let notes = notes, !notes.isEmpty {
            let notesResult = try cryptoService.encrypt(string: notes, key: encryptionKey)
            self.encryptedNotes = notesResult.ciphertext
            self.encryptedNotesNonce = notesResult.nonce
            self.encryptedNotesTag = notesResult.tag
        } else {
            self.encryptedNotes = nil
            self.encryptedNotesNonce = nil
            self.encryptedNotesTag = nil
        }
        
        if let totpSecret = totpSecret, !totpSecret.isEmpty {
            let totpResult = try cryptoService.encrypt(string: totpSecret, key: encryptionKey)
            self.encryptedTOTPSecret = totpResult.ciphertext
            self.encryptedTOTPSecretNonce = totpResult.nonce
            self.encryptedTOTPSecretTag = totpResult.tag
        } else {
            self.encryptedTOTPSecret = nil
            self.encryptedTOTPSecretNonce = nil
            self.encryptedTOTPSecretTag = nil
        }
    }
}
