//
//  PhotosViewModel.swift
//  SecureDataManager
//
//  ViewModel para gestión de fotos
//

import Foundation
import Combine
import UIKit
import PhotosUI
import CryptoKit

/// ViewModel para gestión de fotos cifradas
class PhotosViewModel: ObservableObject {
    
    @Published var photos: [EncryptedPhoto] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let dataStore = DataStore.shared
    private var cancellables = Set<AnyCancellable>()
    private var masterKey: SymmetricKey?
    
    init() {
        setupBindings()
        loadPhotos()
    }
    
    func setMasterKey(_ key: SymmetricKey) {
        self.masterKey = key
    }
    
    private func setupBindings() {
        dataStore.$photos
            .receive(on: DispatchQueue.main)
            .assign(to: &$photos)
    }
    
    private func loadPhotos() {
        photos = dataStore.photos
    }
    
    // MARK: - Importación
    
    func importPhoto(_ image: UIImage, notes: String? = nil) {
        guard let masterKey = masterKey else {
            errorMessage = "No hay clave de cifrado disponible"
            return
        }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let photo = try EncryptedPhoto(
                    image: image,
                    notes: notes,
                    encryptionKey: masterKey,
                    includeThumbnail: true
                )
                
                DispatchQueue.main.async {
                    self.dataStore.addPhoto(photo)
                    self.isLoading = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error al cifrar foto: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func importPhotos(from results: [PHPickerResult]) {
        guard let masterKey = masterKey else {
            errorMessage = "No hay clave de cifrado disponible"
            return
        }
        
        isLoading = true
        
        let dispatchGroup = DispatchGroup()
        var importedCount = 0
        
        for result in results {
            dispatchGroup.enter()
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                defer { dispatchGroup.leave() }
                
                guard let self = self,
                      let image = object as? UIImage,
                      error == nil else { return }
                
                do {
                    let photo = try EncryptedPhoto(
                        image: image,
                        notes: nil,
                        encryptionKey: masterKey,
                        includeThumbnail: true
                    )
                    
                    DispatchQueue.main.async {
                        self.dataStore.addPhoto(photo)
                        importedCount += 1
                    }
                } catch {
                    print("Error importing photo: \(error)")
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    // MARK: - Captura
    
    func capturePhoto(_ image: UIImage, notes: String? = nil) {
        importPhoto(image, notes: notes)
    }
    
    // MARK: - CRUD
    
    func updatePhoto(_ photo: EncryptedPhoto, newNotes: String?) {
        // Las fotos no son mutables, se elimina y se vuelve a crear si es necesario
        // Esto es por diseño de seguridad
    }
    
    func deletePhoto(_ photo: EncryptedPhoto) {
        dataStore.deletePhoto(photo)
    }
    
    func deletePhotos(at offsets: IndexSet) {
        dataStore.deletePhoto(at: offsets)
    }
    
    // MARK: - Descifrado
    
    func decryptImage(for photo: EncryptedPhoto) -> UIImage? {
        guard let masterKey = masterKey else { return nil }
        
        do {
            return try photo.decryptImage(key: masterKey)
        } catch {
            errorMessage = "Error al descifrar imagen: \(error.localizedDescription)"
            return nil
        }
    }
    
    func decryptThumbnail(for photo: EncryptedPhoto) -> UIImage? {
        guard let masterKey = masterKey else { return nil }
        
        do {
            return try photo.decryptThumbnail(key: masterKey)
        } catch {
            // Si falla el thumbnail, intentar con la imagen completa
            return decryptImage(for: photo)
        }
    }
    
    func decryptNotes(for photo: EncryptedPhoto) -> String? {
        guard let masterKey = masterKey else { return nil }
        
        do {
            return try photo.decryptNotes(key: masterKey)
        } catch {
            return nil
        }
    }
    
    // MARK: - Exportación
    
    func exportPhoto(_ photo: EncryptedPhoto, to url: URL) -> Bool {
        guard let image = decryptImage(for: photo),
              let data = image.jpegData(compressionQuality: 0.9) else { return false }
        
        do {
            try data.write(to: url)
            return true
        } catch {
            errorMessage = "Error al exportar: \(error.localizedDescription)"
            return false
        }
    }
}
