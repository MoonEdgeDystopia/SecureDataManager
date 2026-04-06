//
//  EncryptedPhoto.swift
//  SecureDataManager
//
//  Modelo para almacenar fotos cifradas
//

import Foundation
import CryptoKit
import UIKit

/// Representa una foto con su contenido cifrado
struct EncryptedPhoto: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    
    // Metadata no sensible (para organización)
    var width: Int
    var height: Int
    var fileSize: Int64
    
    // Imagen completa cifrada
    var encryptedImageData: Data
    var encryptedImageNonce: Data
    var encryptedImageTag: Data
    
    // Thumbnail cifrado (opcional, para mejor UX)
    var encryptedThumbnailData: Data?
    var encryptedThumbnailNonce: Data?
    var encryptedThumbnailTag: Data?
    
    // Notas/descripción cifrada
    var encryptedNotes: Data?
    var encryptedNotesNonce: Data?
    var encryptedNotesTag: Data?
    
    init(
        id: UUID = UUID(),
        image: UIImage,
        notes: String?,
        encryptionKey: SymmetricKey,
        includeThumbnail: Bool = true
    ) throws {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw CryptoError.encryptionFailed
        }
        
        self.width = Int(image.size.width)
        self.height = Int(image.size.height)
        self.fileSize = Int64(imageData.count)
        
        let cryptoService = CryptoService()
        
        // Cifrar imagen completa
        let imageResult = try cryptoService.encrypt(data: imageData, key: encryptionKey)
        self.encryptedImageData = imageResult.ciphertext
        self.encryptedImageNonce = imageResult.nonce
        self.encryptedImageTag = imageResult.tag
        
        // Generar y cifrar thumbnail si se solicita
        if includeThumbnail, let thumbnail = image.preparingThumbnail(of: CGSize(width: 200, height: 200)),
           let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
            let thumbnailResult = try cryptoService.encrypt(data: thumbnailData, key: encryptionKey)
            self.encryptedThumbnailData = thumbnailResult.ciphertext
            self.encryptedThumbnailNonce = thumbnailResult.nonce
            self.encryptedThumbnailTag = thumbnailResult.tag
        }
        
        // Cifrar notas si existen
        if let notes = notes, !notes.isEmpty {
            let notesResult = try cryptoService.encrypt(string: notes, key: encryptionKey)
            self.encryptedNotes = notesResult.ciphertext
            self.encryptedNotesNonce = notesResult.nonce
            self.encryptedNotesTag = notesResult.tag
        }
    }
    
    // MARK: - Descifrado
    
    func decryptImage(key: SymmetricKey) throws -> UIImage {
        let cryptoService = CryptoService()
        let imageData = try cryptoService.decryptData(
            ciphertext: encryptedImageData,
            nonce: encryptedImageNonce,
            tag: encryptedImageTag,
            key: key
        )
        
        guard let image = UIImage(data: imageData) else {
            throw CryptoError.decryptionFailed
        }
        
        return image
    }
    
    func decryptThumbnail(key: SymmetricKey) throws -> UIImage? {
        guard let encryptedData = encryptedThumbnailData,
              let nonce = encryptedThumbnailNonce,
              let tag = encryptedThumbnailTag else { return nil }
        
        let cryptoService = CryptoService()
        let thumbnailData = try cryptoService.decryptData(
            ciphertext: encryptedData,
            nonce: nonce,
            tag: tag,
            key: key
        )
        
        return UIImage(data: thumbnailData)
    }
    
    func decryptNotes(key: SymmetricKey) throws -> String? {
        guard let encrypted = encryptedNotes,
              let nonce = encryptedNotesNonce,
              let tag = encryptedNotesTag else { return nil }
        
        let cryptoService = CryptoService()
        return try cryptoService.decrypt(ciphertext: encrypted, nonce: nonce, tag: tag, key: key)
    }
}
