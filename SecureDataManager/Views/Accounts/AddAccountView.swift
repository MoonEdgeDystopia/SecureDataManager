//
//  AddAccountView.swift
//  SecureDataManager
//
//  Vista para agregar nueva cuenta
//

import SwiftUI

struct AddAccountView: View {
    
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var serviceName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var notes: String = ""
    @State private var showPasswordGenerator: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Información del Servicio") {
                    TextField("Nombre del servicio", text: $serviceName)
                        .textContentType(.organizationName)
                }
                
                Section("Credenciales") {
                    TextField("Usuario (opcional)", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                    
                    TextField("Email (opcional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    HStack {
                        SecureField("Contraseña", text: $password)
                            .textContentType(.newPassword)
                        
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
            .navigationTitle("Nueva Cuenta")
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
        }
    }
    
    private func saveAccount() {
        viewModel.addAccount(
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

/// Sheet de generador de contraseñas
struct PasswordGeneratorSheet: View {
    
    @Binding var password: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var generatedPassword: String = ""
    @State private var length: Double = 16
    @State private var includeUppercase: Bool = true
    @State private var includeLowercase: Bool = true
    @State private var includeNumbers: Bool = true
    @State private var includeSpecial: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview de contraseña
                VStack(spacing: 12) {
                    Text(generatedPassword)
                        .font(.system(.title3, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .contextMenu {
                            Button(action: { UIPasteboard.general.string = generatedPassword }) {
                                Label("Copiar", systemImage: "doc.on.doc")
                            }
                        }
                    
                    Button(action: generatePassword) {
                        Label("Generar Nueva", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
                
                // Opciones
                VStack(spacing: 16) {
                    HStack {
                        Text("Longitud: \(Int(length))")
                        Spacer()
                    }
                    
                    Slider(value: $length, in: 8...32, step: 1)
                    
                    Toggle("Mayúsculas (A-Z)", isOn: $includeUppercase)
                    Toggle("Minúsculas (a-z)", isOn: $includeLowercase)
                    Toggle("Números (0-9)", isOn: $includeNumbers)
                    Toggle("Especiales (!@#$)", isOn: $includeSpecial)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                Button(action: usePassword) {
                    Text("Usar Contraseña")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("Generar Contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generatePassword()
            }
            .onChange(of: length) { _, _ in generatePassword() }
            .onChange(of: includeUppercase) { _, _ in generatePassword() }
            .onChange(of: includeLowercase) { _, _ in generatePassword() }
            .onChange(of: includeNumbers) { _, _ in generatePassword() }
            .onChange(of: includeSpecial) { _, _ in generatePassword() }
        }
    }
    
    private func generatePassword() {
        let options = PasswordOptions(
            length: Int(length),
            includeUppercase: includeUppercase,
            includeLowercase: includeLowercase,
            includeNumbers: includeNumbers,
            includeSpecialCharacters: includeSpecial
        )
        generatedPassword = PasswordGenerator.shared.generatePassword(options: options)
    }
    
    private func usePassword() {
        password = generatedPassword
        dismiss()
    }
}

#Preview {
    AddAccountView(viewModel: AccountsViewModel())
}
