//
//  MetallicTheme.swift
//  SecureDataManager
//
//  Sistema de tema metálico con degradados plateados
//

import SwiftUI

// MARK: - Colores Metálicos

struct MetallicColors {
    // Degradados plateados para modo claro
    static let lightSilverStart = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let lightSilverMid = Color(red: 0.85, green: 0.87, blue: 0.90)
    static let lightSilverEnd = Color(red: 0.75, green: 0.78, blue: 0.82)
    
    // Degradados plateados para modo oscuro
    static let darkSilverStart = Color(red: 0.25, green: 0.27, blue: 0.30)
    static let darkSilverMid = Color(red: 0.15, green: 0.17, blue: 0.20)
    static let darkSilverEnd = Color(red: 0.08, green: 0.09, blue: 0.11)
    
    // Acentos metálicos
    static let chrome = Color(red: 0.90, green: 0.91, blue: 0.93)
    static let brushedAluminum = Color(red: 0.75, green: 0.76, blue: 0.78)
    static let titanium = Color(red: 0.60, green: 0.62, blue: 0.65)
    static let steel = Color(red: 0.45, green: 0.47, blue: 0.50)
    
    // Acentos brillantes
    static let silverHighlight = Color(red: 0.98, green: 0.98, blue: 1.0)
    static let silverShadow = Color(red: 0.50, green: 0.52, blue: 0.55)
    
    // Fondos
    static let metallicBackgroundLight = LinearGradient(
        colors: [
            Color(red: 0.96, green: 0.97, blue: 0.98),
            Color(red: 0.88, green: 0.90, blue: 0.93),
            Color(red: 0.82, green: 0.84, blue: 0.87)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let metallicBackgroundDark = LinearGradient(
        colors: [
            Color(red: 0.18, green: 0.19, blue: 0.22),
            Color(red: 0.12, green: 0.13, blue: 0.15),
            Color(red: 0.06, green: 0.07, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Degradado para cards
    static func cardGradient(isDark: Bool) -> LinearGradient {
        isDark ? darkCardGradient : lightCardGradient
    }
    
    static let lightCardGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.98, blue: 0.99),
            Color(red: 0.92, green: 0.93, blue: 0.95),
            Color(red: 0.86, green: 0.88, blue: 0.90)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkCardGradient = LinearGradient(
        colors: [
            Color(red: 0.30, green: 0.32, blue: 0.35),
            Color(red: 0.22, green: 0.24, blue: 0.27),
            Color(red: 0.15, green: 0.16, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Degradado para botones principales
    static func primaryButtonGradient(isDark: Bool) -> LinearGradient {
        isDark ? darkPrimaryButton : lightPrimaryButton
    }
    
    static let lightPrimaryButton = LinearGradient(
        colors: [
            Color(red: 0.40, green: 0.50, blue: 0.65),
            Color(red: 0.30, green: 0.40, blue: 0.55),
            Color(red: 0.25, green: 0.35, blue: 0.50)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkPrimaryButton = LinearGradient(
        colors: [
            Color(red: 0.50, green: 0.60, blue: 0.75),
            Color(red: 0.40, green: 0.50, blue: 0.65),
            Color(red: 0.35, green: 0.45, blue: 0.60)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Degradado para elementos de éxito
    static let successGradient = LinearGradient(
        colors: [
            Color(red: 0.30, green: 0.65, blue: 0.45),
            Color(red: 0.25, green: 0.55, blue: 0.38)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Degradado para advertencias
    static let warningGradient = LinearGradient(
        colors: [
            Color(red: 0.90, green: 0.60, blue: 0.20),
            Color(red: 0.85, green: 0.50, blue: 0.15)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Borde metálico
    static func metallicBorder(isDark: Bool) -> LinearGradient {
        isDark ? darkBorder : lightBorder
    }
    
    static let lightBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.8),
            Color(red: 0.70, green: 0.72, blue: 0.75).opacity(0.5),
            Color(red: 0.60, green: 0.62, blue: 0.65).opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkBorder = LinearGradient(
        colors: [
            Color(red: 0.50, green: 0.52, blue: 0.55).opacity(0.6),
            Color(red: 0.35, green: 0.37, blue: 0.40).opacity(0.4),
            Color(red: 0.20, green: 0.22, blue: 0.25).opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Modificadores de Estilo Metálico

struct MetallicCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(MetallicColors.cardGradient(isDark: colorScheme == .dark))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(MetallicColors.metallicBorder(isDark: colorScheme == .dark), lineWidth: 1.5)
                    )
            )
            .shadow(
                color: colorScheme == .dark 
                    ? Color.black.opacity(0.4)
                    : Color.black.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

struct MetallicButtonModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled 
                        ? MetallicColors.primaryButtonGradient(isDark: colorScheme == .dark)
                        : LinearGradient(colors: [Color.gray], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4), lineWidth: 1)
                    )
            )
            .shadow(
                color: isEnabled 
                    ? Color(red: 0.2, green: 0.3, blue: 0.5).opacity(colorScheme == .dark ? 0.4 : 0.3)
                    : Color.clear,
                radius: 6,
                x: 0,
                y: 3
            )
    }
}

struct MetallicIconModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size * 0.5))
            .foregroundStyle(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(red: 0.85, green: 0.87, blue: 0.90), Color(red: 0.60, green: 0.62, blue: 0.65)]
                        : [Color(red: 0.40, green: 0.45, blue: 0.55), Color(red: 0.25, green: 0.30, blue: 0.40)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(red: 0.25, green: 0.27, blue: 0.30), Color(red: 0.15, green: 0.17, blue: 0.20)]
                                : [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.85, green: 0.87, blue: 0.90)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(MetallicColors.metallicBorder(isDark: colorScheme == .dark), lineWidth: 2)
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.2),
                radius: 6,
                x: 0,
                y: 3
            )
    }
}

struct MetallicTextFieldModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        colorScheme == .dark
                            ? Color(red: 0.15, green: 0.16, blue: 0.18)
                            : Color(red: 0.95, green: 0.96, blue: 0.97)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                MetallicColors.metallicBorder(isDark: colorScheme == .dark),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Extensiones

extension View {
    func metallicCard() -> some View {
        modifier(MetallicCardModifier())
    }
    
    func metallicButton(isEnabled: Bool = true) -> some View {
        modifier(MetallicButtonModifier(isEnabled: isEnabled))
    }
    
    func metallicIcon(size: CGFloat = 60) -> some View {
        modifier(MetallicIconModifier(size: size))
    }
    
    func metallicTextField() -> some View {
        modifier(MetallicTextFieldModifier())
    }
}

// MARK: - Fondo Metálico

struct MetallicBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Fondo base con degradado
            (colorScheme == .dark 
                ? MetallicColors.metallicBackgroundDark 
                : MetallicColors.metallicBackgroundLight)
            .ignoresSafeArea()
            
            // Patrón de rejilla metálica sutil
            GeometryReader { geometry in
                GridPattern()
                    .stroke(
                        colorScheme == .dark 
                            ? Color.white.opacity(0.03)
                            : Color.black.opacity(0.03),
                        lineWidth: 0.5
                    )
            }
            .ignoresSafeArea()
            
            // Brillo superior
            VStack {
                LinearGradient(
                    colors: [
                        (colorScheme == .dark 
                            ? Color(red: 0.40, green: 0.45, blue: 0.50)
                            : Color.white)
                            .opacity(0.15),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .ignoresSafeArea()
                
                Spacer()
            }
        }
    }
}

// MARK: - Patrón de Rejilla

struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 40
        
        // Líneas verticales
        for x in stride(from: 0, to: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        // Líneas horizontales
        for y in stride(from: 0, to: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        return path
    }
}

// MARK: - Indicador de Fuerza Metálico

struct MetallicStrengthBar: View {
    let strength: Double // 0.0 to 1.0
    
    @Environment(\.colorScheme) var colorScheme
    
    private var barColor: LinearGradient {
        if strength < 0.3 {
            return LinearGradient(
                colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if strength < 0.6 {
            return LinearGradient(
                colors: [Color.orange.opacity(0.8), Color.orange.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if strength < 0.9 {
            return LinearGradient(
                colors: [Color.yellow.opacity(0.8), Color.yellow.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.8, blue: 0.5),
                    Color(red: 0.2, green: 0.7, blue: 0.4)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fondo
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        colorScheme == .dark
                            ? Color(red: 0.15, green: 0.16, blue: 0.18)
                            : Color(red: 0.85, green: 0.87, blue: 0.90)
                    )
                
                // Barra de fuerza
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: max(0, min(CGFloat(strength) * geometry.size.width, geometry.size.width)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
        .frame(height: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(MetallicColors.metallicBorder(isDark: colorScheme == .dark), lineWidth: 1)
        )
    }
}

// MARK: - Header Metálico

struct MetallicHeader: View {
    let title: String
    let icon: String
    let iconSize: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Círculo exterior brillante
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                colorScheme == .dark 
                                    ? Color(red: 0.4, green: 0.45, blue: 0.50).opacity(0.3)
                                    : Color.white.opacity(0.8),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: iconSize + 20, height: iconSize + 20)
                
                Image(systemName: icon)
                    .metallicIcon(size: iconSize)
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white, Color(red: 0.75, green: 0.77, blue: 0.80)]
                            : [Color(red: 0.15, green: 0.17, blue: 0.25), Color(red: 0.35, green: 0.40, blue: 0.50)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: colorScheme == .dark 
                        ? Color.black.opacity(0.5)
                        : Color.white.opacity(0.8),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        }
    }
}

#Preview {
    ZStack {
        MetallicBackground()
        
        VStack(spacing: 20) {
            MetallicHeader(title: "Secure Data", icon: "lock.shield.fill", iconSize: 70)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Fuerza: Débil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MetallicStrengthBar(strength: 0.3)
            }
            .frame(width: 200)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Fuerza: Fuerte")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MetallicStrengthBar(strength: 0.95)
            }
            .frame(width: 200)
            
            Button("Botón Metálico") {}
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 200, height: 50)
                .metallicButton(isEnabled: true)
            
            Text("Card Metálica")
                .font(.headline)
                .padding()
                .frame(width: 200, height: 80)
                .metallicCard()
        }
    }
}
