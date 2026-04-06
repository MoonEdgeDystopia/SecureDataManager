//
//  String+Extensions.swift
//  SecureDataManager
//

import Foundation

extension String {
    /// Valida si la contraseña cumple con los requisitos de seguridad
    var isValidPassword: Bool {
        // Mínimo 12 caracteres
        guard count >= 12 else { return false }
        
        // Al menos una mayúscula
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", ".*[A-Z]+.*")
        guard uppercasePredicate.evaluate(with: self) else { return false }
        
        // Al menos una minúscula
        let lowercasePredicate = NSPredicate(format: "SELF MATCHES %@", ".*[a-z]+.*")
        guard lowercasePredicate.evaluate(with: self) else { return false }
        
        // Al menos un número
        let numberPredicate = NSPredicate(format: "SELF MATCHES %@", ".*[0-9]+.*")
        guard numberPredicate.evaluate(with: self) else { return false }
        
        // Al menos un carácter especial
        let specialCharPredicate = NSPredicate(format: "SELF MATCHES %@", ".*[^A-Za-z0-9]+.*")
        guard specialCharPredicate.evaluate(with: self) else { return false }
        
        return true
    }
    
    /// Descripción de los requisitos de contraseña
    static var passwordRequirements: String {
        return """
        La contraseña debe tener:
        • Mínimo 12 caracteres
        • Al menos una mayúscula
        • Al menos una minúscula
        • Al menos un número
        • Al menos un carácter especial
        """
    }
    
    /// Calcula la fortaleza de la contraseña (0.0 - 1.0)
    var passwordStrength: Double {
        var score = 0.0
        
        // Longitud
        score += min(Double(count) / 16.0, 0.4)
        
        // Variedad de caracteres
        let hasUppercase = rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasDigits = rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
        
        let varietyCount = [hasUppercase, hasLowercase, hasDigits, hasSpecial].filter { $0 }.count
        score += Double(varietyCount) * 0.15
        
        return min(score, 1.0)
    }
    
    /// Oculta el contenido mostrando solo los últimos caracteres
    func masked(showLast: Int = 4) -> String {
        guard count > showLast else { return String(repeating: "•", count: count) }
        let maskCount = count - showLast
        let mask = String(repeating: "•", count: maskCount)
        let suffix = String(suffix(showLast))
        return mask + suffix
    }
}
