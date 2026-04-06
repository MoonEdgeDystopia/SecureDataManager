//
//  AccountsListView.swift
//  SecureDataManager
//
//  Lista de cuentas cifradas
//

import SwiftUI

struct AccountsListView: View {
    
    @StateObject private var viewModel = AccountsViewModel()
    @Environment(\.masterKey) private var masterKey
    
    @State private var searchText: String = ""
    @State private var showAddAccount: Bool = false
    @State private var selectedAccount: EncryptedAccount?
    @State private var isSearching: Bool = false
    
    var filteredAccounts: [EncryptedAccount] {
        if searchText.isEmpty {
            return viewModel.accounts
        }
        return viewModel.searchAccounts(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredAccounts) { account in
                    AccountRowView(
                        account: account,
                        serviceName: viewModel.decryptServiceName(for: account),
                        username: viewModel.decryptUsername(for: account),
                        email: viewModel.decryptEmail(for: account)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAccount = account
                    }
                }
                .onDelete(perform: deleteAccounts)
            }
            .listStyle(.plain)
            .navigationTitle("Cuentas")
            .searchable(text: $searchText, prompt: "Buscar cuentas")
            .onChange(of: searchText) { _, newValue in
                // La búsqueda se actualiza automáticamente
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddAccount = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                if let key = masterKey {
                    viewModel.setMasterKey(key)
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountView(viewModel: viewModel)
            }
            .sheet(item: $selectedAccount) { account in
                AccountDetailView(viewModel: viewModel, account: account)
            }
            .overlay {
                if viewModel.accounts.isEmpty {
                    ContentUnavailableView(
                        "No hay cuentas",
                        systemImage: "key.fill",
                        description: Text("Agrega tu primera cuenta segura")
                    )
                }
            }
        }
    }
    
    private func deleteAccounts(at offsets: IndexSet) {
        viewModel.deleteAccounts(at: offsets)
    }
}

/// Fila de cuenta
struct AccountRowView: View {
    let account: EncryptedAccount
    let serviceName: String
    let username: String?
    let email: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono del servicio
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "key.fill")
                    .foregroundStyle(.blue)
            }
            
            // Información
            VStack(alignment: .leading, spacing: 4) {
                Text(serviceName)
                    .font(.headline)
                
                if let username = username, !username.isEmpty {
                    Text(username)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if let email = email, !email.isEmpty {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

/// Vista de detalle de cuenta
struct AccountDetailView: View {
    
    @ObservedObject var viewModel: AccountsViewModel
    let account: EncryptedAccount
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPassword: Bool = false
    @State private var showEdit: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    // Datos descifrados
    private var serviceName: String {
        viewModel.decryptServiceName(for: account)
    }
    
    private var username: String? {
        viewModel.decryptUsername(for: account)
    }
    
    private var email: String? {
        viewModel.decryptEmail(for: account)
    }
    
    private var password: String {
        viewModel.decryptPassword(for: account)
    }
    
    private var notes: String? {
        viewModel.decryptNotes(for: account)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Sección de información principal
                Section("Información") {
                    DetailRow(title: "Servicio", value: serviceName, icon: "globe")
                    
                    if let username = username, !username.isEmpty {
                        DetailRow(title: "Usuario", value: username, icon: "person", isCopyable: true)
                    }
                    
                    if let email = email, !email.isEmpty {
                        DetailRow(title: "Email", value: email, icon: "envelope", isCopyable: true)
                    }
                    
                    // Contraseña
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Contraseña")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if showPassword {
                                Text(password)
                                    .font(.system(.body, design: .monospaced))
                            } else {
                                Text("••••••••")
                                    .font(.body)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        
                        Button(action: { UIPasteboard.general.string = password }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Notas
                if let notes = notes, !notes.isEmpty {
                    Section("Notas") {
                        Text(notes)
                            .font(.body)
                    }
                }
                
                // Información adicional
                Section("Detalles") {
                    HStack {
                        Text("Creado")
                        Spacer()
                        Text(account.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Modificado")
                        Spacer()
                        Text(account.updatedAt, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Eliminar
                Section {
                    Button("Eliminar Cuenta", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle(serviceName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Editar") {
                        showEdit = true
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                EditAccountView(viewModel: viewModel, account: account)
            }
            .alert("¿Eliminar cuenta?", isPresented: $showDeleteConfirmation) {
                Button("Eliminar", role: .destructive) {
                    viewModel.deleteAccount(account)
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
        }
    }
}

/// Fila de detalle
struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    var isCopyable: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }
            
            Spacer()
            
            if isCopyable {
                Button(action: { UIPasteboard.general.string = value }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Vista de editar cuenta
struct EditAccountView: View {
    
    @ObservedObject var viewModel: AccountsViewModel
    let account: EncryptedAccount
    @Environment(\.dismiss) private var dismiss
    
    @State private var serviceName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var notes: String = ""
    @State private var showPasswordGenerator: Bool = false
    
    init(viewModel: AccountsViewModel, account: EncryptedAccount) {
        self.viewModel = viewModel
        self.account = account
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Información del Servicio") {
                    TextField("Nombre del servicio", text: $serviceName)
                }
                
                Section("Credenciales") {
                    TextField("Usuario (opcional)", text: $username)
                        .textContentType(.username)
                    
                    TextField("Email (opcional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    
                    HStack {
                        SecureField("Contraseña", text: $password)
                            .textContentType(.password)
                        
                        Button(action: { showPasswordGenerator = true }) {
                            Image(systemName: "key.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                Section("Notas") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Editar Cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        saveAccount()
                    }
                    .disabled(serviceName.isEmpty || password.isEmpty)
                }
            }
            .sheet(isPresented: $showPasswordGenerator) {
                PasswordGeneratorSheet(password: $password)
            }
            .onAppear {
                // Cargar valores actuales
                serviceName = viewModel.decryptServiceName(for: account)
                username = viewModel.decryptUsername(for: account) ?? ""
                email = viewModel.decryptEmail(for: account) ?? ""
                password = viewModel.decryptPassword(for: account)
                notes = viewModel.decryptNotes(for: account) ?? ""
            }
        }
    }
    
    private func saveAccount() {
        viewModel.updateAccount(
            account,
            serviceName: serviceName,
            username: username.isEmpty ? nil : username,
            email: email.isEmpty ? nil : email,
            password: password,
            notes: notes.isEmpty ? nil : notes,
            totpSecret: nil
        )
        dismiss()
    }
}

#Preview {
    AccountsListView()
}
