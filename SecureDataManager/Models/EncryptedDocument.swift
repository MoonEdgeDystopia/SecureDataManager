//
//  EncryptedDocument.swift
//  SecureDataManager
//
//  Modelo para almacenar documentos cifrados
//

import Foundation
import CryptoKit

/// Tipos de documentos soportados
enum DocumentType: String, Codable {
    case pdf = "pdf"
    case text = "txt"
    case markdown = "md"
    case other = "other"
    
    var icon: String {
        switch self {
        case .pdf: return "doc.text.fill"
        case .text: return "doc.plaintext.fill"
        case .markdown: return "doc.richtext.fill"
        case .other: return "doc.fill"
        }
    }
}

/// Representa un documento con su contenido cifrado
struct EncryptedDocument: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    
    // Metadata no sensible
    var documentType: DocumentType
    var fileExtension: String
    var fileSize: Int64
    
    // Contenido cifrado
    var encryptedContent: Data
    var encryptedNonce: Data
    var encryptedTag: Data
    
    // Nombre del archivo cifrado
    var encryptedFilename: Data
    var encryptedFilenameNonce: Data
    var encryptedFilenameTag: Data
    
    init(
        id: UUID = UUID(),
        filename: String,
        content: Data,
        documentType: DocumentType,
        fileExtension: String,
        encryptionKey: SymmetricKey
    ) throws {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.documentType = documentType
        self.fileExtension = fileExtension
        self.fileSize = Int64(content.count)
        
        let cryptoService = CryptoService()
        
        // Cifrar contenido
        let contentResult = try cryptoService.encrypt(data: content, key: encryptionKey)
        self.encryptedContent = contentResult.ciphertext
        self.encryptedNonce = contentResult.nonce
        self.encryptedTag = contentResult.tag
        
        // Cifrar nombre de archivo
        let filenameResult = try cryptoService.encrypt(string: filename, key: encryptionKey)
        self.encryptedFilename = filenameResult.ciphertext
        self.encryptedFilenameNonce = filenameResult.nonce
        self.encryptedFilenameTag = filenameResult.tag
    }
    
    // MARK: - Descifrado
    
    func decryptContent(key: SymmetricKey) throws -> Data {
        let cryptoService = CryptoService()
        return try cryptoService.decryptData(
            ciphertext: encryptedContent,
            nonce: encryptedNonce,
            tag: encryptedTag,
            key: key
        )
    }
    
    func decryptFilename(key: SymmetricKey) throws -> String {
        let cryptoService = CryptoService()
        return try cryptoService.decrypt(
            ciphertext: encryptedFilename,
            nonce: encryptedFilenameNonce,
            tag: encryptedFilenameTag,
            key: key
        )
    }
    
    // MARK: - Vista previa segura
    
    /// Obtiene una vista previa del contenido si es texto
    func getTextPreview(key: SymmetricKey, maxLength: Int = 200) throws -> String? {
        guard documentType == .text || documentType == .markdown else { return nil }
        
        let content = try decryptContent(key: key)
        guard let text = String(data: content, encoding: .utf8) else { return nil }
        
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        }
        return text
    }
}
