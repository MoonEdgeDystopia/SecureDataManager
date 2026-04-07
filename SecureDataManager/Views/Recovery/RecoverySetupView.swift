//
//  RecoverySetupView.swift
//  SecureDataManager
//
//  Vista para mostrar códigos de recuperación durante el setup
//

import SwiftUI
import LocalAuthentication

struct RecoverySetupView: View {
    
    @ObservedObject var viewModel: SetupViewModel
    @State private var hasAcknowledgedWarning: Bool = false
    @State private var showShareDetail: SecretShare?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.2.on.ring.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    
                    Text("Códigos de Recuperación")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Guarda estos códigos en un lugar seguro. Necesitarás los 3 códigos principales (1, 2, 3) para recuperar tu acceso si olvidas tu contraseña.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Advertencia importante
                if !hasAcknowledgedWarning {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("IMPORTANTE", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        
                        Text("• No podremos recuperar tu cuenta sin estos códigos\n• Guárdalos fuera de este dispositivo\n• No los compartas con nadie")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Entendido, he guardado los códigos") {
                        withAnimation {
                            hasAcknowledgedWarning = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                
                // Grid de shares
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.shares) { share in
                        ShareCardView(share: share)
                            .onTapGesture {
                                showShareDetail = share
                            }
                    }
                }
                
                // Botón continuar
                Button(action: { viewModel.proceedToBiometric() }) {
                    Text("Continuar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(hasAcknowledgedWarning ? Color.orange : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(!hasAcknowledgedWarning)
                
                Spacer()
            }
            .padding()
        }
        .sheet(item: $showShareDetail) { share in
            ShareDetailView(share: share)
        }
    }
}

/// Tarjeta de share
struct ShareCardView: View {
    let share: SecretShare
    @State private var isCopied: Bool = false
    
    var shareNumber: Int {
        Int(share.index)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Número del share
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Text("\(shareNumber)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
            }
            
            // Preview del código
            VStack(alignment: .leading, spacing: 4) {
                Text("Código de Recuperación \(shareNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(maskedCode)
                    .font(.caption)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Botón copiar
            Button(action: copyShare) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(isCopied ? .green : .secondary)
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var maskedCode: String {
        let code = share.shareCode
        guard code.count > 8 else { return code }
        let prefix = code.prefix(4)
        let suffix = code.suffix(4)
        return "\(prefix)...\(suffix)"
    }
    
    private func copyShare() {
        UIPasteboard.general.string = share.shareCode
        isCopied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
}

/// Vista detallada del share
struct ShareDetailView: View {
    let share: SecretShare
    @Environment(\.dismiss) private var dismiss
    @State private var isCopied: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Text("\(Int(share.index))")
                            .font(.system(size: 40))
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                    
                    Text("Código de Recuperación \(Int(share.index))")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                // Código completo
                VStack(spacing: 12) {
                    Text(share.shareCode)
                        .font(.system(.body, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .contextMenu {
                            Button(action: copyToClipboard) {
                                Label("Copiar", systemImage: "doc.on.doc")
                            }
                        }
                    
                    Button(action: copyToClipboard) {
                        HStack {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "¡Copiado!" : "Copiar código")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(isCopied ? Color.green : Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                // Instrucciones
                VStack(alignment: .leading, spacing: 12) {
                    Label("Guarda este código en un lugar seguro", systemImage: "lock.fill")
                    Label("Necesitarás 3 de 5 códigos para recuperar tu cuenta", systemImage: "key.fill")
                    Label("No compartas estos códigos con nadie", systemImage: "exclamationmark.shield.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding()
            .navigationTitle("Código \(Int(share.index))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = share.shareCode
        isCopied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
}

/// Vista de configuración biométrica
struct BiometricSetupView: View {
    
    @ObservedObject var viewModel: SetupViewModel
    @Binding var isSetupComplete: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "faceid")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Autenticación Biométrica")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Activa Face ID o Touch ID para un acceso más rápido y seguro a tus datos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                Toggle("Habilitar Face ID / Touch ID", isOn: $viewModel.isBiometricEnabled)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: viewModel.isBiometricEnabled) { _, newValue in
                        if newValue {
                            verifyBiometric()
                        }
                    }
                
                if viewModel.isBiometricEnabled {
                    Label("Se requerirá tanto tu contraseña como tu biometría para acceder.", systemImage: "checkmark.shield")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
            
            Button(action: completeSetup) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Completar Configuración")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(viewModel.isLoading)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 30)
    }
    
    private func completeSetup() {
        Task {
            let success = await viewModel.completeSetup()
            if success {
                await MainActor.run {
                    isSetupComplete = true
                }
            }
        }
    }
    
    /// Verifica que la biometría funcione antes de habilitarla
    private func verifyBiometric() {
        let context = LAContext()
        let reason = "Verificando configuración de Face ID/Touch ID"
        
        Task {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
                
                if !success {
                    await MainActor.run {
                        viewModel.isBiometricEnabled = false
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.isBiometricEnabled = false
                }
            }
        }
    }
}

#Preview {
    let vm = SetupViewModel()
    vm.shares = [
        SecretShare(index: 1, value: Data([0x01, 0x02, 0x03]), threshold: 3, totalShares: 5),
        SecretShare(index: 2, value: Data([0x04, 0x05, 0x06]), threshold: 3, totalShares: 5),
        SecretShare(index: 3, value: Data([0x07, 0x08, 0x09]), threshold: 3, totalShares: 5),
    ]
    return RecoverySetupView(viewModel: vm)
}
