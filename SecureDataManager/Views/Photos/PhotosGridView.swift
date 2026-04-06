//
//  PhotosGridView.swift
//  SecureDataManager
//
//  Grid de fotos cifradas
//

import SwiftUI
import PhotosUI

struct PhotosGridView: View {
    
    @StateObject private var viewModel = PhotosViewModel()
    @Environment(\.masterKey) private var masterKey
    
    @State private var showImagePicker: Bool = false
    @State private var showCamera: Bool = false
    @State private var selectedPhoto: EncryptedPhoto?
    @State private var selectedItems: [PhotosPickerItem] = []
    
    // Configuración del grid
    private let columns = 4
    private let spacing: CGFloat = 12
    
    var body: some View {
        NavigationStack {
            ScrollView {
                PhotoGridContent(
                    photos: viewModel.photos.sorted(by: { $0.createdAt > $1.createdAt }),
                    spacing: spacing,
                    columns: columns,
                    decryptThumbnail: viewModel.decryptThumbnail,
                    onSelect: { photo in
                        selectedPhoto = photo
                    }
                )
                .padding(spacing)
            }
            .navigationTitle(viewModel.photos.isEmpty ? "Fotos" : "\(viewModel.photos.count) fotos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showCamera = true }) {
                            Label("Cámara", systemImage: "camera")
                        }
                        
                        Button(action: { showImagePicker = true }) {
                            Label("Galería", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .onAppear {
                if let key = masterKey {
                    viewModel.setMasterKey(key)
                }
            }
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $selectedItems,
                maxSelectionCount: 10,
                matching: .images
            )
            .onChange(of: selectedItems) { _, newItems in
                importPhotos(from: newItems)
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    if let image = image {
                        viewModel.capturePhoto(image)
                    }
                }
            }
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(viewModel: viewModel, photo: photo)
            }
            .overlay {
                if viewModel.photos.isEmpty {
                    ContentUnavailableView(
                        "No hay fotos",
                        systemImage: "photo.fill",
                        description: Text("Captura o importa fotos para cifrarlas")
                    )
                }
            }
        }
    }
    
    private func importPhotos(from items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.importPhoto(image)
                    }
                }
            }
        }
    }
}

// MARK: - Grid de Fotos

struct PhotoGridContent: View {
    let photos: [EncryptedPhoto]
    let spacing: CGFloat
    let columns: Int
    let decryptThumbnail: (EncryptedPhoto) -> UIImage?
    let onSelect: (EncryptedPhoto) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let totalSpacing = spacing * CGFloat(columns - 1)
            let availableWidth = geometry.size.width - totalSpacing
            let cellSize = floor(availableWidth / CGFloat(columns))
            
            let rows = stride(from: 0, to: photos.count, by: columns).map { startIndex in
                Array(photos[startIndex..<min(startIndex + columns, photos.count)])
            }
            
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, rowPhotos in
                    HStack(spacing: spacing) {
                        ForEach(rowPhotos) { photo in
                            PhotoThumbnailCell(
                                photo: photo,
                                image: decryptThumbnail(photo),
                                size: cellSize
                            )
                            .onTapGesture {
                                onSelect(photo)
                            }
                        }
                        
                        // Espacios vacíos para completar la fila
                        let emptyCount = columns - rowPhotos.count
                        ForEach(0..<emptyCount, id: \.self) { _ in
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Celda Individual

struct PhotoThumbnailCell: View {
    let photo: EncryptedPhoto
    let image: UIImage?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Fondo gris mientras carga o si no hay imagen
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: size * 0.3))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Vista de detalle de foto

struct PhotoDetailView: View {
    
    @ObservedObject var viewModel: PhotosViewModel
    let photo: EncryptedPhoto
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var showFullImage: Bool = false
    
    private var image: UIImage? {
        viewModel.decryptImage(for: photo)
    }
    
    private var notes: String? {
        viewModel.decryptNotes(for: photo)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Imagen principal
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .padding(.horizontal)
                            .onTapGesture {
                                showFullImage = true
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.secondary)
                                    Text("No se puede cargar la imagen")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                    }
                    
                    // Información
                    VStack(alignment: .leading, spacing: 16) {
                        if let notes = notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notas")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(notes)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Metadatos
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detalles")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            InfoRow(icon: "aspectratio", title: "Dimensiones", value: "\(photo.width) × \(photo.height) px")
                            InfoRow(icon: "externaldrive", title: "Tamaño", value: formatFileSize(photo.fileSize))
                            InfoRow(icon: "calendar", title: "Capturada", value: photo.createdAt.formatted(date: .long, time: .shortened))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Botón eliminar
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Eliminar Foto", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("¿Eliminar foto?", isPresented: $showDeleteConfirmation) {
                Button("Eliminar", role: .destructive) {
                    viewModel.deletePhoto(photo)
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .fullScreenCover(isPresented: $showFullImage) {
                if let image = image {
                    FullScreenImageView(image: image)
                }
            }
        }
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let kb = Double(size) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024.0
        return String(format: "%.2f MB", mb)
    }
}

// MARK: - Fila de información

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Vista de imagen a pantalla completa

struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .onTapGesture {
                    dismiss()
                }
        }
    }
}

// MARK: - Vista de cámara

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void
        
        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onCapture(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    PhotosGridView()
}
