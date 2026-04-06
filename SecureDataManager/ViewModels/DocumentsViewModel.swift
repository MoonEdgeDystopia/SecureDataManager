//
//  DocumentsViewModel.swift
//  SecureDataManager
//
//  ViewModel para gestión de documentos
//

import Foundation
import Combine
import UIKit
import PDFKit
import CryptoKit

/// ViewModel para gestión de documentos cifrados
class DocumentsViewModel: ObservableObject {
    
    @Published var documents: [EncryptedDocument] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let dataStore = DataStore.shared
    private var cancellables = Set<AnyCancellable>()
    private var masterKey: SymmetricKey?
    
    init() {
        setupBindings()
        loadDocuments()
    }
    
    func setMasterKey(_ key: SymmetricKey) {
        self.masterKey = key
    }
    
    private func setupBindings() {
        dataStore.$documents
            .receive(on: DispatchQueue.main)
            .assign(to: &$documents)
    }
    
    private func loadDocuments() {
        documents = dataStore.documents
    }
    
    // MARK: - Importación
    
    func importDocument(from url: URL, filename: String) {
        guard let masterKey = masterKey else {
            errorMessage = "No hay clave de cifrado disponible"
            return
        }
        
        isLoading = true
        
        // Acceder al recurso de forma segura
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "No se puede acceder al archivo. Verifica los permisos."
            isLoading = false
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            // Verificar que el archivo existe y tiene contenido
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: url.path) else {
                errorMessage = "El archivo no existe"
                isLoading = false
                return
            }
            
            let content = try Data(contentsOf: url)
            
            guard !content.isEmpty else {
                errorMessage = "El archivo está vacío"
                isLoading = false
                return
            }
            
            let documentType: DocumentType
            let fileExtension = url.pathExtension.lowercased()
            
            switch fileExtension {
            case "pdf":
                documentType = .pdf
            case "txt":
                documentType = .text
            case "md", "markdown":
                documentType = .markdown
            default:
                documentType = .other
            }
            
            let document = try EncryptedDocument(
                filename: filename,
                content: content,
                documentType: documentType,
                fileExtension: fileExtension,
                encryptionKey: masterKey
            )
            
            dataStore.addDocument(document)
            isLoading = false
            
        } catch {
            errorMessage = "Error al importar documento: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func importTextDocument(text: String, filename: String) {
        guard let masterKey = masterKey else {
            errorMessage = "No hay clave de cifrado disponible"
            return
        }
        
        isLoading = true
        
        do {
            guard let content = text.data(using: .utf8) else {
                throw NSError(domain: "DocumentsViewModel", code: -1)
            }
            
            let document = try EncryptedDocument(
                filename: filename,
                content: content,
                documentType: .text,
                fileExtension: "txt",
                encryptionKey: masterKey
            )
            
            dataStore.addDocument(document)
            isLoading = false
            
        } catch {
            errorMessage = "Error al crear documento: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - CRUD
    
    func deleteDocument(_ document: EncryptedDocument) {
        dataStore.deleteDocument(document)
    }
    
    func deleteDocuments(at offsets: IndexSet) {
        dataStore.deleteDocument(at: offsets)
    }
    
    // MARK: - Descifrado
    
    func decryptFilename(for document: EncryptedDocument) -> String {
        guard let masterKey = masterKey else { return "Documento cifrado" }
        
        do {
            return try document.decryptFilename(key: masterKey)
        } catch {
            return "Error al descifrar"
        }
    }
    
    func decryptContent(for document: EncryptedDocument) -> Data? {
        guard let masterKey = masterKey else { return nil }
        
        do {
            return try document.decryptContent(key: masterKey)
        } catch {
            errorMessage = "Error al descifrar: \(error.localizedDescription)"
            return nil
        }
    }
    
    func decryptTextContent(for document: EncryptedDocument) -> String? {
        guard let data = decryptContent(for: document) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func decryptPDF(for document: EncryptedDocument) -> PDFDocument? {
        guard let data = decryptContent(for: document) else { return nil }
        return PDFDocument(data: data)
    }
    
    func getPreview(for document: EncryptedDocument) -> String {
        guard let masterKey = masterKey else { return "••••••••" }
        
        do {
            if let preview = try document.getTextPreview(key: masterKey) {
                return preview
            }
        } catch {}
        
        return "No hay vista previa disponible"
    }
    
    // MARK: - Exportación
    
    func exportDocument(_ document: EncryptedDocument, to url: URL) -> Bool {
        guard let content = decryptContent(for: document) else { return false }
        
        do {
            try content.write(to: url)
            return true
        } catch {
            errorMessage = "Error al exportar: \(error.localizedDescription)"
            return false
        }
    }
}
