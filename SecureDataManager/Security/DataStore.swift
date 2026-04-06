//
//  DataStore.swift
//  SecureDataManager
//
//  Almacenamiento local de datos cifrados
//

import Foundation
import Combine
import SwiftUI

/// Servicio de almacenamiento de datos cifrados
class DataStore: ObservableObject {
    
    static let shared = DataStore()
    
    @Published var accounts: [EncryptedAccount] = []
    @Published var documents: [EncryptedDocument] = []
    @Published var photos: [EncryptedPhoto] = []
    
    private let fileManager = FileManager.default
    private let accountsFileName = "accounts.dat"
    private let documentsFileName = "documents.dat"
    private let photosFileName = "photos.dat"
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var accountsURL: URL {
        documentsDirectory.appendingPathComponent(accountsFileName)
    }
    
    private var documentsURL: URL {
        documentsDirectory.appendingPathComponent(documentsFileName)
    }
    
    private var photosURL: URL {
        documentsDirectory.appendingPathComponent(photosFileName)
    }
    
    private init() {
        loadAllData()
    }
    
    // MARK: - Cuentas
    
    func addAccount(_ account: EncryptedAccount) {
        accounts.append(account)
        saveAccounts()
    }
    
    func updateAccount(_ account: EncryptedAccount) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
        }
    }
    
    func deleteAccount(_ account: EncryptedAccount) {
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
    }
    
    func deleteAccount(at offsets: IndexSet) {
        accounts.remove(atOffsets: offsets)
        saveAccounts()
    }
    
    private func saveAccounts() {
        do {
            let data = try JSONEncoder().encode(accounts)
            try data.write(to: accountsURL, options: .atomic)
        } catch {
            print("Error saving accounts: \(error)")
        }
    }
    
    private func loadAccounts() {
        do {
            let data = try Data(contentsOf: accountsURL)
            accounts = try JSONDecoder().decode([EncryptedAccount].self, from: data)
        } catch {
            accounts = []
        }
    }
    
    // MARK: - Documentos
    
    func addDocument(_ document: EncryptedDocument) {
        documents.append(document)
        saveDocuments()
    }
    
    func updateDocument(_ document: EncryptedDocument) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
            saveDocuments()
        }
    }
    
    func deleteDocument(_ document: EncryptedDocument) {
        documents.removeAll { $0.id == document.id }
        saveDocuments()
    }
    
    func deleteDocument(at offsets: IndexSet) {
        documents.remove(atOffsets: offsets)
        saveDocuments()
    }
    
    private func saveDocuments() {
        do {
            let data = try JSONEncoder().encode(documents)
            try data.write(to: documentsURL, options: .atomic)
        } catch {
            print("Error saving documents: \(error)")
        }
    }
    
    private func loadDocuments() {
        do {
            let data = try Data(contentsOf: documentsURL)
            documents = try JSONDecoder().decode([EncryptedDocument].self, from: data)
        } catch {
            documents = []
        }
    }
    
    // MARK: - Fotos
    
    func addPhoto(_ photo: EncryptedPhoto) {
        photos.append(photo)
        savePhotos()
    }
    
    func updatePhoto(_ photo: EncryptedPhoto) {
        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
            photos[index] = photo
            savePhotos()
        }
    }
    
    func deletePhoto(_ photo: EncryptedPhoto) {
        photos.removeAll { $0.id == photo.id }
        savePhotos()
    }
    
    func deletePhoto(at offsets: IndexSet) {
        photos.remove(atOffsets: offsets)
        savePhotos()
    }
    
    private func savePhotos() {
        do {
            let data = try JSONEncoder().encode(photos)
            try data.write(to: photosURL, options: .atomic)
        } catch {
            print("Error saving photos: \(error)")
        }
    }
    
    private func loadPhotos() {
        do {
            let data = try Data(contentsOf: photosURL)
            photos = try JSONDecoder().decode([EncryptedPhoto].self, from: data)
        } catch {
            photos = []
        }
    }
    
    // MARK: - Carga General
    
    func loadAllData() {
        loadAccounts()
        loadDocuments()
        loadPhotos()
    }
    
    // MARK: - Limpieza
    
    func clearAllData() {
        accounts.removeAll()
        documents.removeAll()
        photos.removeAll()
        
        try? fileManager.removeItem(at: accountsURL)
        try? fileManager.removeItem(at: documentsURL)
        try? fileManager.removeItem(at: photosURL)
    }
}
