//
//  SecurityQuestionsSetupView.swift
//  SecureDataManager
//
//  Vista para configurar preguntas de seguridad durante setup
//

import SwiftUI

struct SecurityQuestionsSetupView: View {
    
    @ObservedObject var viewModel: SetupViewModel
    @Binding var isSetupComplete: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var questions: [String] = ["", "", ""]
    @State private var answers: [String] = ["", "", ""]
    @State private var showAnswers: [Bool] = [false, false, false]
    @State private var recoveryCode: String = ""
    @State private var hasAcknowledged: Bool = false
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    @State private var showShareSheet: Bool = false
    
    private let recoveryManager = RecoveryManager.shared
    
    let suggestedQuestions = [
        "¿Cuál es el nombre de tu primera mascota?",
        "¿En qué ciudad naciste?",
        "¿Cuál es tu película favorita?",
        "¿Cómo se llamaba tu primer colegio?",
        "¿Cuál es el nombre de tu madre de soltera?",
        "¿En qué año terminaste el colegio?",
        "¿Cuál fue tu primer empleo?",
        "¿Cuál es tu libro favorito?",
        "¿En qué ciudad conociste a tu pareja?",
        "¿Cuál es tu equipo deportivo favorito?"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    
                    Text("Configura tu Recuperación")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Configura 3 preguntas de seguridad y guarda tu código de recuperación. Estos son necesarios para recuperar tu cuenta si olvidas tu contraseña.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Preguntas y respuestas
                VStack(alignment: .leading, spacing: 20) {
                    Text("Preguntas de Seguridad")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(0..<3, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pregunta \(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            // Selector de preguntas sugeridas
                            Menu {
                                ForEach(suggestedQuestions, id: \.self) { question in
                                    Button(question) {
                                        questions[index] = question
                                    }
                                }
                            } label: {
                                HStack {
                                    TextField("Escribe o selecciona una pregunta", text: $questions[index])
                                        .lineLimit(2)
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            HStack {
                                if showAnswers[index] {
                                    TextField("Tu respuesta", text: $answers[index])
                                } else {
                                    SecureField("Tu respuesta", text: $answers[index])
                                }
                                
                                Button(action: { showAnswers[index].toggle() }) {
                                    Image(systemName: showAnswers[index] ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Botón generar código
                if recoveryCode.isEmpty {
                    Button(action: generateRecoverySetup) {
                        if isGenerating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Generar Código de Recuperación")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(allFieldsValid ? Color.orange : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(!allFieldsValid || isGenerating)
                    .padding(.horizontal)
                } else {
                    // Mostrar código generado
                    VStack(spacing: 16) {
                        Text("Tu Código de Recuperación")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Text(recoveryCode)
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            HStack(spacing: 16) {
                                Button(action: copyRecoveryCode) {
                                    Label("Copiar", systemImage: "doc.on.doc")
                                }
                                
                                Button(action: shareRecoveryCode) {
                                    Label("Compartir", systemImage: "square.and.arrow.up")
                                }
                            }
                            .font(.subheadline)
                        }
                        .padding(.horizontal)
                        
                        // Checkbox de confirmación
                        Toggle(isOn: $hasAcknowledged) {
                            Text("He guardado mi código de recuperación en un lugar seguro y he memorizado mis respuestas.")
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        
                        // Botón continuar
                        Button(action: proceedToBiometricSetup) {
                            Text("Continuar")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .background(hasAcknowledged ? Color.green : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(!hasAcknowledged)
                        .padding(.horizontal)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(
                items: ["Mi código de recuperación para SecureDataManager:\n\n\(recoveryCode)\n\nGuárdalo en un lugar seguro."]
            )
        }
    }
    
    private var allFieldsValid: Bool {
        !questions[0].isEmpty &&
        !questions[1].isEmpty &&
        !questions[2].isEmpty &&
        !answers[0].isEmpty &&
        !answers[1].isEmpty &&
        !answers[2].isEmpty
    }
    
    private func generateRecoverySetup() {
        guard allFieldsValid else { return }
        
        isGenerating = true
        errorMessage = nil
        
        print("=== GENERANDO CÓDIGO DE RECUPERACIÓN ===")
        
        Task {
            do {
                // Limpiar respuestas
                let cleanedQuestions = questions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let cleanedAnswers = answers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                
                // Generar código de recuperación
                let code = try recoveryManager.generateRecoveryCode()
                
                print("Código generado: \(code.prefix(20))...")
                
                // Guardar en viewModel (solo guardamos los datos, el RecoveryData se crea al completar setup)
                await MainActor.run {
                    viewModel.setRecoveryQuestions(cleanedQuestions, answers: cleanedAnswers)
                    recoveryCode = code
                    viewModel.recoveryCode = code
                    isGenerating = false
                    print("Setup de recuperación completado")
                }
                
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }
    
    private func copyRecoveryCode() {
        UIPasteboard.general.string = recoveryCode
        print("Código copiado al portapapeles")
    }
    
    private func shareRecoveryCode() {
        showShareSheet = true
    }
    
    private func proceedToBiometricSetup() {
        print("Continuando a configuración biométrica...")
        viewModel.proceedToBiometricSetup()
    }
}

#Preview {
    SecurityQuestionsSetupView(viewModel: SetupViewModel(), isSetupComplete: .constant(false))
}
