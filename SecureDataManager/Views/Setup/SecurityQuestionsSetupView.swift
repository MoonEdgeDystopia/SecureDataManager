//
//  SecurityQuestionsSetupView.swift
//  SecureDataManager
//
//  Vista para configurar preguntas de seguridad personalizadas durante setup - Estilo Metálico
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
    
    // Banco de preguntas sugeridas (ahora opcional)
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
        "¿Cuál es tu equipo deportivo favorito?",
        "¿Nombre de tu mejor amigo de la infancia?",
        "¿En qué calle creciste?",
        "¿Cuál es tu comida favorita?",
        "¿Nombre de tu primer jefe?",
        "¿Cuál fue tu primer coche?"
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
                
                Text("Crea 3 preguntas de seguridad personalizadas y sus respuestas. Puedes escribir tus propias preguntas o usar las sugeridas. Guarda tu código de recuperación en un lugar seguro.")
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
                
                // Preguntas y respuestas personalizadas
                VStack(alignment: .leading, spacing: 24) {
                    Text("Preguntas de Seguridad Personalizadas")
                        .font(.headline)
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                : Color(red: 0.25, green: 0.30, blue: 0.45)
                        )
                    
                    ForEach(0..<3, id: \.self) { index in
                        QuestionAnswerCard(
                            index: index,
                            question: $questions[index],
                            answer: $answers[index],
                            showAnswer: $showAnswers[index],
                            suggestedQuestions: suggestedQuestions
                        )
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
                    RecoveryCodeCard(
                        recoveryCode: recoveryCode,
                        hasAcknowledged: $hasAcknowledged,
                        onCopy: copyRecoveryCode,
                        onShare: shareRecoveryCode
                    )
                    
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
                    .padding(.horizontal)
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
                
                // Guardar en viewModel
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

// MARK: - Card de Pregunta y Respuesta

struct QuestionAnswerCard: View {
    let index: Int
    @Binding var question: String
    @Binding var answer: String
    @Binding var showAnswer: Bool
    let suggestedQuestions: [String]
    
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isQuestionFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header con número y botón de sugerencias
            HStack {
                Text("Pregunta \(index + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(red: 0.75, green: 0.80, blue: 0.90), Color(red: 0.55, green: 0.60, blue: 0.75)]
                                : [Color(red: 0.30, green: 0.35, blue: 0.50), Color(red: 0.45, green: 0.50, blue: 0.65)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                // Botón de sugerencias
                Menu {
                    Section("Sugerencias") {
                        ForEach(suggestedQuestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                question = suggestion
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                        Text("Sugerencias")
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(red: 0.35, green: 0.40, blue: 0.50).opacity(0.6), Color(red: 0.25, green: 0.30, blue: 0.40).opacity(0.4)]
                                        : [Color(red: 0.85, green: 0.88, blue: 0.95), Color(red: 0.75, green: 0.80, blue: 0.90)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(MetallicColors.metallicBorder(isDark: colorScheme == .dark), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(red: 0.85, green: 0.90, blue: 1.0), Color(red: 0.65, green: 0.70, blue: 0.85)]
                                : [Color(red: 0.25, green: 0.30, blue: 0.45), Color(red: 0.40, green: 0.45, blue: 0.60)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            
            // Campo de pregunta personalizada
            VStack(alignment: .leading, spacing: 4) {
                TextField("Escribe tu propia pregunta de seguridad...", text: $question, axis: .vertical)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                    .lineLimit(2...4)
                    .focused($isQuestionFocused)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                colorScheme == .dark
                                    ? Color(red: 0.12, green: 0.13, blue: 0.15)
                                    : Color(red: 0.97, green: 0.98, blue: 0.99)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isQuestionFocused
                                            ? Color(red: 0.40, green: 0.50, blue: 0.70)
                                            : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)),
                                        lineWidth: isQuestionFocused ? 2 : 1
                                    )
                            )
                    )
                
                // Contador de caracteres
                HStack {
                    Spacer()
                    Text("\(question.count) caracteres")
                        .font(.caption2)
                        .foregroundStyle(
                            question.count < 10
                                ? Color.red.opacity(0.8)
                                : (colorScheme == .dark ? Color.gray.opacity(0.6) : Color.gray)
                        )
                }
            }
            
            // Campo de respuesta
            VStack(alignment: .leading, spacing: 8) {
                Text("Respuesta")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        colorScheme == .dark
                            ? Color(red: 0.60, green: 0.65, blue: 0.75)
                            : Color(red: 0.40, green: 0.45, blue: 0.55)
                    )
                
                HStack {
                    if showAnswer {
                        TextField("Tu respuesta secreta", text: $answer)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                    } else {
                        SecureField("Tu respuesta secreta", text: $answer)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                    }
                    
                    Button(action: { showAnswer.toggle() }) {
                        Image(systemName: showAnswer ? "eye.slash" : "eye")
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
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            colorScheme == .dark
                                ? Color(red: 0.12, green: 0.13, blue: 0.15)
                                : Color(red: 0.97, green: 0.98, blue: 0.99)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(MetallicColors.metallicBorder(isDark: colorScheme == .dark), lineWidth: 1)
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.20, green: 0.22, blue: 0.26).opacity(0.5), Color(red: 0.15, green: 0.17, blue: 0.20).opacity(0.3)]
                            : [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.90, green: 0.92, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(MetallicColors.metallicBorder(isDark: colorScheme == .dark), lineWidth: 1)
                )
        )
    }
}

// MARK: - Card de Código de Recuperación

struct RecoveryCodeCard: View {
    let recoveryCode: String
    @Binding var hasAcknowledged: Bool
    let onCopy: () -> Void
    let onShare: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.85, green: 0.70, blue: 0.30), Color(red: 0.75, green: 0.60, blue: 0.20)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("Tu Código de Recuperación")
                    .font(.headline)
                    .foregroundStyle(
                        colorScheme == .dark
                            ? Color(red: 0.90, green: 0.85, blue: 0.70)
                            : Color(red: 0.60, green: 0.50, blue: 0.25)
                    )
                
                Text("Guarda este código en un lugar seguro fuera de este dispositivo")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        colorScheme == .dark
                            ? Color(red: 0.70, green: 0.65, blue: 0.55)
                            : Color(red: 0.50, green: 0.45, blue: 0.40)
                    )
            }
            
            // Código
            VStack(spacing: 12) {
                Text(recoveryCode)
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(red: 0.25, green: 0.23, blue: 0.18).opacity(0.8), Color(red: 0.20, green: 0.18, blue: 0.13).opacity(0.6)]
                                        : [Color(red: 1.0, green: 0.98, blue: 0.90), Color(red: 0.95, green: 0.93, blue: 0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.5), Color(red: 0.75, green: 0.60, blue: 0.20).opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
                
                // Botones de acción
                HStack(spacing: 16) {
                    ActionButton(
                        title: "Copiar",
                        icon: "doc.on.doc",
                        colors: [Color(red: 0.35, green: 0.50, blue: 0.70), Color(red: 0.25, green: 0.40, blue: 0.60)],
                        action: onCopy
                    )
                    
                    ActionButton(
                        title: "Compartir",
                        icon: "square.and.arrow.up",
                        colors: [Color(red: 0.40, green: 0.60, blue: 0.50), Color(red: 0.30, green: 0.50, blue: 0.40)],
                        action: onShare
                    )
                }
            }
            
            // Checkbox de confirmación
            VStack(spacing: 12) {
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                Toggle(isOn: $hasAcknowledged) {
                    Text("He guardado mi código de recuperación en un lugar seguro y memorizado mis respuestas. Entiendo que sin este código no podré recuperar mi cuenta.")
                        .font(.caption)
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color(red: 0.70, green: 0.75, blue: 0.85)
                                : Color(red: 0.35, green: 0.40, blue: 0.50)
                        )
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.85, green: 0.70, blue: 0.30)))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.22, green: 0.20, blue: 0.16), Color(red: 0.15, green: 0.14, blue: 0.10)]
                            : [Color(red: 1.0, green: 0.99, blue: 0.96), Color(red: 0.95, green: 0.94, blue: 0.91)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.90, green: 0.75, blue: 0.35).opacity(0.4), Color(red: 0.80, green: 0.65, blue: 0.25).opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(
            color: Color(red: 0.85, green: 0.70, blue: 0.30).opacity(colorScheme == .dark ? 0.2 : 0.1),
            radius: 10,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Botón de Acción

struct ActionButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundStyle(.white)
            .shadow(
                color: colors[0].opacity(0.4),
                radius: 4,
                x: 0,
                y: 2
            )
        }
    }
}

#Preview {
    SecurityQuestionsSetupView(viewModel: SetupViewModel(), isSetupComplete: .constant(false))
}
