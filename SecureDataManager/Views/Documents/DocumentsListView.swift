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
        // Obtener nombre de archivo completo con extensión
        let filename = url.lastPathComponent
        
        // Pequeño delay para asegurar que el picker se cierre primero
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
        case .other: return "doc.fill"
        }
    }
    
    var iconColor: Color {
        switch document.documentType {
        case .pdf: return .red
        case .text: return .blue
        case .markdown: return .purple
        case .other: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
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

/// Vista de detalle de documento
struct DocumentDetailView: View {
    
    @ObservedObject var viewModel: DocumentsViewModel
    let document: EncryptedDocument
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: Bool = false
    
    private var filename: String {
        viewModel.decryptFilename(for: document)
    }
    
    var body: some View {
        NavigationStack {
            documentContent
                .navigationTitle(filename)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
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
        }
    }
    
    @ViewBuilder
    private var documentContent: some View {
        switch document.documentType {
        case .text, .markdown:
            if let text = viewModel.decryptTextContent(for: document) {
                ScrollView {
                    Text(text)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ContentUnavailableView(
                    "No se puede mostrar",
                    systemImage: "doc.text",
                    description: Text("Error al descifrar el documento")
                )
            }
            
        case .pdf:
            if let pdf = viewModel.decryptPDF(for: document) {
                PDFViewer(document: pdf)
            } else {
                ContentUnavailableView(
                    "No se puede mostrar",
                    systemImage: "doc.text",
                    description: Text("Error al descifrar el PDF")
                )
            }
            
        default:
            ContentUnavailableView(
                "Vista previa no disponible",
                systemImage: "doc",
                description: Text("Este tipo de archivo no tiene vista previa")
            )
        }
    }
}

/// Vista de PDF
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

/// Selector de documentos - Versión mejorada
struct DocumentPicker: UIViewControllerRepresentable {
    let onSelect: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Tipos de archivos soportados
        let contentTypes: [UTType] = [
            .pdf,                    // Documentos PDF
            .plainText,              // Archivos .txt
            .utf8PlainText,          // Texto UTF-8
            .rtf,                    // Rich Text Format
            .image,                  // Imágenes (JPEG, PNG, etc.)
            .jpeg,                   // JPEG específico
            .png,                    // PNG específico
            .data,                   // Datos genéricos (cualquier archivo)
            UTType(filenameExtension: "md") ?? .plainText,  // Markdown
            UTType(filenameExtension: "doc") ?? .data,      // Word antiguo
            UTType(filenameExtension: "docx") ?? .data,     // Word moderno
            UTType(filenameExtension: "xls") ?? .data,      // Excel antiguo
            UTType(filenameExtension: "xlsx") ?? .data,     // Excel moderno
            UTType(filenameExtension: "ppt") ?? .data,      // PowerPoint
            UTType(filenameExtension: "pptx") ?? .data,     // PowerPoint moderno
            UTType(filenameExtension: "pages") ?? .data,    // Pages
            UTType(filenameExtension: "numbers") ?? .data,  // Numbers
            UTType(filenameExtension: "keynote") ?? .data,  // Keynote
            UTType(filenameExtension: "csv") ?? .plainText, // CSV
            UTType(filenameExtension: "json") ?? .plainText, // JSON
            UTType(filenameExtension: "xml") ?? .plainText,  // XML
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true  // Permitir selección múltiple
        picker.shouldShowFileExtensions = true // Mostrar extensiones de archivo
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
            // Procesar todos los archivos seleccionados
            for url in urls {
                // Asegurar que el archivo sea accesible
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

/// Vista para agregar nota de texto
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
