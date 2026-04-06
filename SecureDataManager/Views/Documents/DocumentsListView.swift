//
//  DocumentsListView.swift
//  SecureDataManager
//
//  Lista de documentos cifrados
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct DocumentsListView: View {
    
    @StateObject private var viewModel = DocumentsViewModel()
    @Environment(\.masterKey) private var masterKey
    
    @State private var showDocumentPicker: Bool = false
    @State private var showAddText: Bool = false
    @State private var selectedDocument: EncryptedDocument?
    @State private var showErrorAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.documents) { document in
                    DocumentRowView(
                        document: document,
                        filename: viewModel.decryptFilename(for: document)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDocument = document
                    }
                }
                .onDelete(perform: deleteDocuments)
            }
            .listStyle(.plain)
            .navigationTitle("Documentos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { 
                            print("Abriendo document picker...")
                            showDocumentPicker = true 
                        }) {
                            Label("Importar archivo", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: { showAddText = true }) {
                            Label("Crear nota de texto", systemImage: "doc.text")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                if let key = masterKey {
                    viewModel.setMasterKey(key)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { url in
                    print("Archivo seleccionado: \(url.lastPathComponent)")
                    importDocument(from: url)
                }
            }
            .sheet(isPresented: $showAddText) {
                AddTextDocumentView(viewModel: viewModel)
            }
            .sheet(item: $selectedDocument) { document in
                DocumentDetailView(viewModel: viewModel, document: document)
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showErrorAlert = newValue != nil
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                } else {
                    Text("Ha ocurrido un error")
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Importando...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
            .overlay {
                if viewModel.documents.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No hay documentos",
                        systemImage: "doc.fill",
                        description: Text("Importa documentos o crea notas de texto")
                    )
                }
            }
        }
    }
    
    private func importDocument(from url: URL) {
        let filename = url.lastPathComponent
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.importDocument(from: url, filename: filename)
        }
    }
    
    private func deleteDocuments(at offsets: IndexSet) {
        viewModel.deleteDocuments(at: offsets)
    }
}

/// Fila de documento
struct DocumentRowView: View {
    let document: EncryptedDocument
    let filename: String
    
    var iconName: String {
        switch document.documentType {
        case .pdf: return "doc.text.fill"
        case .text: return "doc.plaintext.fill"
        case .markdown: return "doc.richtext.fill"
        case .other:
            // Iconos según extensión
            switch document.fileExtension.lowercased() {
            case "jpg", "jpeg", "png", "gif", "heic":
                return "photo.fill"
            case "doc", "docx":
                return "doc.text.fill"
            case "xls", "xlsx", "csv":
                return "tablecells.fill"
            case "ppt", "pptx":
                return "play.rectangle.fill"
            default:
                return "doc.fill"
            }
        }
    }
    
    var iconColor: Color {
        switch document.documentType {
        case .pdf: return .red
        case .text: return .blue
        case .markdown: return .purple
        case .other:
            switch document.fileExtension.lowercased() {
            case "jpg", "jpeg", "png", "gif", "heic":
                return .green
            case "doc", "docx":
                return .blue
            case "xls", "xlsx", "csv":
                return .green
            case "ppt", "pptx":
                return .orange
            default:
                return .gray
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(filename)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(document.fileExtension.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.2))
                        .foregroundStyle(iconColor)
                        .clipShape(Capsule())
                    
                    Text(formatFileSize(document.fileSize))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
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

/// Vista de detalle de documento - Versión mejorada
struct DocumentDetailView: View {
    
    @ObservedObject var viewModel: DocumentsViewModel
    let document: EncryptedDocument
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var tempExportURL: URL?
    @State private var decryptedImage: UIImage?
    @State private var decryptedData: Data?
    
    private var filename: String {
        viewModel.decryptFilename(for: document)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Vista previa del contenido
                    contentPreview
                        .padding(.horizontal)
                    
                    // Información del archivo
                    fileInfoSection
                        .padding(.horizontal)
                    
                    // Botones de acción
                    actionButtons
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(filename)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("¿Eliminar documento?", isPresented: $showDeleteConfirmation) {
                Button("Eliminar", role: .destructive) {
                    viewModel.deleteDocument(document)
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = tempExportURL {
                    ShareSheet(items: [url])
                }
            }
            .onAppear {
                loadContent()
            }
            .onDisappear {
                // Limpiar archivo temporal
                if let url = tempExportURL {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
    }
    
    // MARK: - Vista previa del contenido
    
    @ViewBuilder
    private var contentPreview: some View {
        switch document.documentType {
        case .text, .markdown:
            textPreview
            
        case .pdf:
            pdfPreview
            
        default:
            // Para otros tipos, verificar si es imagen
            if isImageFile {
                imagePreview
            } else {
                genericFilePreview
            }
        }
    }
    
    private var textPreview: some View {
        Group {
            if let text = viewModel.decryptTextContent(for: document) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contenido")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    ScrollView {
                        Text(text)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(minHeight: 200, maxHeight: 400)
                }
            } else {
                errorPreview(message: "No se puede descifrar el contenido")
            }
        }
    }
    
    private var pdfPreview: some View {
        Group {
            if let pdf = viewModel.decryptPDF(for: document) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Vista Previa")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    PDFViewer(document: pdf)
                        .frame(height: 500)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                errorPreview(message: "No se puede descifrar el PDF")
            }
        }
    }
    
    private var imagePreview: some View {
        Group {
            if let image = decryptedImage {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Imagen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                }
            } else {
                loadingPreview
            }
        }
    }
    
    private var genericFilePreview: some View {
        VStack(spacing: 20) {
            Image(systemName: iconForFile)
                .font(.system(size: 80))
                .foregroundStyle(colorForFile)
            
            Text(filename)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Este tipo de archivo no tiene vista previa, pero puedes compartirlo o exportarlo.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var loadingPreview: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func errorPreview(message: String) -> some View {
        ContentUnavailableView(
            "Error",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Información del archivo
    
    private var fileInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Información")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 0) {
                InfoRow(icon: "doc", title: "Nombre", value: filename)
                Divider()
                InfoRow(icon: "folder", title: "Tipo", value: document.fileExtension.uppercased())
                Divider()
                InfoRow(icon: "externaldrive", title: "Tamaño", value: formatFileSize(document.fileSize))
                Divider()
                InfoRow(icon: "calendar", title: "Agregado", value: document.createdAt.formatted(date: .long, time: .shortened))
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Botones de acción
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Compartir/Exportar
            Button(action: exportAndShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Compartir / Exportar")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Eliminar
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Eliminar Documento")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isImageFile: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "heic", "heif", "tiff", "webp"]
        return imageExtensions.contains(document.fileExtension.lowercased())
    }
    
    private var iconForFile: String {
        switch document.fileExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic":
            return "photo"
        case "doc", "docx":
            return "doc.text"
        case "xls", "xlsx", "csv":
            return "tablecells"
        case "ppt", "pptx":
            return "play.rectangle"
        case "zip", "rar", "7z":
            return "archivebox"
        case "mp3", "wav", "aac", "m4a":
            return "music.note"
        case "mp4", "mov", "avi":
            return "film"
        default:
            return "doc"
        }
    }
    
    private var colorForFile: Color {
        switch document.fileExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic":
            return .green
        case "doc", "docx":
            return .blue
        case "xls", "xlsx", "csv":
            return .green
        case "ppt", "pptx":
            return .orange
        case "zip", "rar":
            return .yellow
        case "mp3", "mp4":
            return .purple
        default:
            return .gray
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
    
    private func loadContent() {
        if isImageFile {
            decryptedData = viewModel.decryptContent(for: document)
            if let data = decryptedData {
                decryptedImage = UIImage(data: data)
            }
        } else {
            decryptedData = viewModel.decryptContent(for: document)
        }
    }
    
    private func exportAndShare() {
        // Intentar obtener los datos descifrados
        if decryptedData == nil {
            decryptedData = viewModel.decryptContent(for: document)
        }
        
        guard let data = decryptedData else {
            print("No se pueden descifrar los datos")
            return
        }
        
        createTempFileAndShare(data: data)
    }
    
    private func createTempFileAndShare(data: Data) {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            tempExportURL = tempURL
            showShareSheet = true
        } catch {
            print("Error al crear archivo temporal: \(error)")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Vista de PDF

struct PDFViewer: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Selector de documentos

struct DocumentPicker: UIViewControllerRepresentable {
    let onSelect: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let contentTypes: [UTType] = [
            .pdf,
            .plainText,
            .utf8PlainText,
            .rtf,
            .image,
            .jpeg,
            .png,
            .data,
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "doc") ?? .data,
            UTType(filenameExtension: "docx") ?? .data,
            UTType(filenameExtension: "xls") ?? .data,
            UTType(filenameExtension: "xlsx") ?? .data,
            UTType(filenameExtension: "ppt") ?? .data,
            UTType(filenameExtension: "pptx") ?? .data,
            UTType(filenameExtension: "pages") ?? .data,
            UTType(filenameExtension: "numbers") ?? .data,
            UTType(filenameExtension: "keynote") ?? .data,
            UTType(filenameExtension: "csv") ?? .plainText,
            UTType(filenameExtension: "json") ?? .plainText,
            UTType(filenameExtension: "xml") ?? .plainText,
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSelect: (URL) -> Void
        
        init(onSelect: @escaping (URL) -> Void) {
            self.onSelect = onSelect
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else {
                    print("No se puede acceder al archivo: \(url.lastPathComponent)")
                    continue
                }
                
                defer { url.stopAccessingSecurityScopedResource() }
                
                onSelect(url)
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Selección de documento cancelada")
        }
    }
}

// MARK: - Vista para agregar nota de texto

struct AddTextDocumentView: View {
    
    @ObservedObject var viewModel: DocumentsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var filename: String = ""
    @State private var content: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre") {
                    TextField("Nombre del documento", text: $filename)
                }
                
                Section("Contenido") {
                    TextEditor(text: $content)
                        .frame(minHeight: 300)
                }
            }
            .navigationTitle("Nueva Nota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        saveDocument()
                    }
                    .disabled(filename.isEmpty || content.isEmpty)
                }
            }
        }
    }
    
    private func saveDocument() {
        viewModel.importTextDocument(text: content, filename: filename)
        dismiss()
    }
}

#Preview {
    DocumentsListView()
}
