//
//  SecurityQuestionsSetupView.swift
//  SecureDataManager
//
//  Vista para configurar preguntas de seguridad durante setup - Estilo Metálico
//

import SwiftUI

struct SecurityQuestionsSetupView: View {
    
    @ObservedObject var viewModel: SetupViewModel
    @Binding var isSetupComplete: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
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
                MetallicHeader(
                    title: "Recuperación",
                    icon: "shield.lefthalf.filled",
                    iconSize: 70
                )
                
                Text("Configura 3 preguntas de seguridad y guarda tu código de recuperación. Estos son necesarios para recuperar tu cuenta si olvidas tu contraseña.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(red: 0.60, green: 0.65, blue: 0.75), Color(red: 0.45, green: 0.50, blue: 0.60)]
                                : [Color(red: 0.35, green: 0.40, blue: 0.50), Color(red: 0.50, green: 0.55, blue: 0.65)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal)
                
                // Preguntas y respuestas
                VStack(alignment: .leading, spacing: 20) {
                    Text("Preguntas de Seguridad")
                        .font(.headline)
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                : Color(red: 0.25, green: 0.30, blue: 0.45)
                        )
                    
                    ForEach(0..<3, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pregunta \(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? Color(red: 0.65, green: 0.70, blue: 0.80)
                                        : Color(red: 0.35, green: 0.40, blue: 0.50)
                                )
                            
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
                                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: colorScheme == .dark
                                                    ? [Color(red: 0.70, green: 0.75, blue: 0.85), Color(red: 0.50, green: 0.55, blue: 0.65)]
                                                    : [Color(red: 0.40, green: 0.45, blue: 0.55), Color(red: 0.60, green: 0.65, blue: 0.75)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                                .metallicTextField()
                            }
                            
                            HStack {
                                if showAnswers[index] {
                                    TextField("Tu respuesta", text: $answers[index])
                                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                } else {
                                    SecureField("Tu respuesta", text: $answers[index])
                                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                }
                                
                                Button(action: { showAnswers[index].toggle() }) {
                                    Image(systemName: showAnswers[index] ? "eye.slash" : "eye")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: colorScheme == .dark
                                                    ? [Color(red: 0.70, green: 0.75, blue: 0.85), Color(red: 0.50, green: 0.55, blue: 0.65)]
                                                    : [Color(red: 0.40, green: 0.45, blue: 0.55), Color(red: 0.60, green: 0.65, blue: 0.75)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                            }
                            .metallicTextField()
                        }
                    }
                }
                .padding(24)
                .metallicCard()
                
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
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(height: 54)
                    .metallicButton(isEnabled: allFieldsValid && !isGenerating)
                    .disabled(!allFieldsValid || isGenerating)
                    .padding(.horizontal)
                } else {
                    // Mostrar código generado
                    VStack(spacing: 16) {
                        Text("Tu Código de Recuperación")
                            .font(.headline)
                            .foregroundStyle(
                                colorScheme == .dark
                                    ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                    : Color(red: 0.25, green: 0.30, blue: 0.45)
                            )
                        
                        VStack(spacing: 12) {
                            Text(recoveryCode)
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: colorScheme == .dark
                                                    ? [Color(red: 0.25, green: 0.30, blue: 0.40).opacity(0.5), Color(red: 0.20, green: 0.25, blue: 0.35).opacity(0.3)]
                                                    : [Color(red: 0.90, green: 0.93, blue: 0.98), Color(red: 0.85, green: 0.88, blue: 0.93)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(MetallicColors.metallicBorder(isDark: colorScheme == .dark), lineWidth: 1.5)
                                        )
                                )
                            
                            HStack(spacing: 20) {
                                Button(action: copyRecoveryCode) {
                                    Label("Copiar", systemImage: "doc.on.doc")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: colorScheme == .dark
                                            ? [Color(red: 0.65, green: 0.75, blue: 0.95), Color(red: 0.55, green: 0.65, blue: 0.85)]
                                            : [Color(red: 0.30, green: 0.40, blue: 0.70), Color(red: 0.40, green: 0.50, blue: 0.80)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                
                                Button(action: shareRecoveryCode) {
                                    Label("Compartir", systemImage: "square.and.arrow.up")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: colorScheme == .dark
                                            ? [Color(red: 0.65, green: 0.75, blue: 0.95), Color(red: 0.55, green: 0.65, blue: 0.85)]
                                            : [Color(red: 0.30, green: 0.40, blue: 0.70), Color(red: 0.40, green: 0.50, blue: 0.80)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            }
                        }
                        
                        // Checkbox de confirmación
                        Toggle(isOn: $hasAcknowledged) {
                            Text("He guardado mi código de recuperación en un lugar seguro y he memorizado mis respuestas.")
                                .font(.subheadline)
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? Color(red: 0.70, green: 0.75, blue: 0.85)
                                        : Color(red: 0.35, green: 0.40, blue: 0.50)
                                )
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.40, green: 0.50, blue: 0.70)))
                        
                        // Botón continuar
                        Button(action: proceedToBiometricSetup) {
                            Text("Continuar")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .foregroundStyle(.white)
                        .frame(height: 54)
                        .metallicButton(isEnabled: hasAcknowledged)
                        .disabled(!hasAcknowledged)
                    }
                    .padding(24)
                    .metallicCard()
                }
                
                if let errorMessage = errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 30)
            }
            .padding()
        }
        .background(MetallicBackground().ignoresSafeArea())
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
