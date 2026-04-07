//
//  PasswordStrengthBar.swift
//  SecureDataManager
//
//  Barra de fortaleza de contraseña
//

import SwiftUI

struct PasswordStrengthBar: View {
    let password: String
    
    var strength: Double {
        password.passwordStrength
    }
    
    var color: Color {
        switch strength {
        case 0..<0.3: return .red
        case 0.3..<0.5: return .orange
        case 0.5..<0.7: return .yellow
        case 0.7..<0.9: return .green
        default: return .blue
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * strength, height: 4)
                    .animation(.easeInOut, value: strength)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        PasswordStrengthBar(password: "weak")
        PasswordStrengthBar(password: "Medium123")
        PasswordStrengthBar(password: "StrongP@ssw0rd!")
    }
    .padding()
}
