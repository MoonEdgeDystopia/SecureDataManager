//
//  PasswordGenerator.swift
//  SecureDataManager
//
//  Generador de contraseñas seguras
//

import Foundation

/// Opciones para generación de contraseñas
struct PasswordOptions {
    var length: Int = 16
    var includeUppercase: Bool = true
    var includeLowercase: Bool = true
    var includeNumbers: Bool = true
    var includeSpecialCharacters: Bool = true
    var excludeAmbiguousCharacters: Bool = true
    
    static let `default` = PasswordOptions()
    static let pin = PasswordOptions(length: 6, includeUppercase: false, includeLowercase: false, includeNumbers: true, includeSpecialCharacters: false)
}

/// Generador de contraseñas criptográficamente seguras
class PasswordGenerator {
    
    static let shared = PasswordGenerator()
    
    private let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
    private let numbers = "0123456789"
    private let specialCharacters = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    private let ambiguousCharacters = "0O1Il"
    
    private init() {}
    
    /// Genera una contraseña segura
    /// - Parameter options: Opciones de generación
    /// - Returns: Contraseña generada
    func generatePassword(options: PasswordOptions = .default) -> String {
        var characterPool = ""
        var requiredCharacters: [String] = []
        
        if options.includeUppercase {
            characterPool += uppercaseLetters
            requiredCharacters.append(String(uppercaseLetters.randomElement()!))
        }
        
        if options.includeLowercase {
            characterPool += lowercaseLetters
            requiredCharacters.append(String(lowercaseLetters.randomElement()!))
        }
        
        if options.includeNumbers {
            characterPool += numbers
            requiredCharacters.append(String(numbers.randomElement()!))
        }
        
        if options.includeSpecialCharacters {
            characterPool += specialCharacters
            requiredCharacters.append(String(specialCharacters.randomElement()!))
        }
        
        // Eliminar caracteres ambiguos si se solicita
        if options.excludeAmbiguousCharacters {
            characterPool = characterPool.filter { !ambiguousCharacters.contains($0) }
        }
        
        // Generar contraseña
        var password = requiredCharacters
        let remainingLength = options.length - requiredCharacters.count
        
        for _ in 0..<remainingLength {
            if let char = characterPool.randomElement() {
                password.append(String(char))
            }
        }
        
        // Mezclar aleatoriamente
        password.shuffle()
        
        return password.joined()
    }
    
    /// Genera un PIN numérico
    /// - Parameter length: Longitud del PIN
    /// - Returns: PIN generado
    func generatePIN(length: Int = 6) -> String {
        var pin = ""
        for _ in 0..<length {
            pin.append(String(numbers.randomElement()!))
        }
        return pin
    }
    
    /// Genera una contraseña fácil de memorizar (estilo diceware)
    /// - Parameter wordCount: Número de palabras
    /// - Returns: Contraseña de palabras
    func generateMemorablePassword(wordCount: Int = 4) -> String {
        let words = [
            "apple", "beach", "chair", "dance", "eagle", "flame", "grape", "house",
            "igloo", "jungle", "kite", "lemon", "mountain", "night", "ocean", "piano",
            "queen", "river", "sunset", "tiger", "umbrella", "violin", "window", "yellow",
            "zebra", "anchor", "bridge", "castle", "dragon", "engine", "forest", "garden"
        ]
        
        var selectedWords: [String] = []
        for _ in 0..<wordCount {
            if let word = words.randomElement() {
                selectedWords.append(word)
            }
        }
        
        // Agregar un número y un carácter especial
        let number = Int.random(in: 0...99)
        selectedWords.append(String(number))
        
        return selectedWords.joined(separator: "-")
    }
    
    /// Calcula la entropía de una contraseña
    /// - Parameter password: Contraseña a analizar
    /// - Returns: Entropía en bits
    func calculateEntropy(_ password: String) -> Double {
        var poolSize = 0
        
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil {
            poolSize += 26
        }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil {
            poolSize += 26
        }
        if password.rangeOfCharacter(from: .decimalDigits) != nil {
            poolSize += 10
        }
        if password.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil {
            poolSize += 32
        }
        
        if poolSize == 0 { return 0 }
        
        return Double(password.count) * log2(Double(poolSize))
    }
    
    /// Evalúa la fortaleza de una contraseña
    /// - Parameter password: Contraseña a evaluar
    /// - Returns: Tupla con nivel y descripción
    func evaluateStrength(_ password: String) -> (level: PasswordStrength, description: String) {
        let entropy = calculateEntropy(password)
        
        switch entropy {
        case 0..<30:
            return (.veryWeak, "Muy débil")
        case 30..<50:
            return (.weak, "Débil")
        case 50..<70:
            return (.fair, "Aceptable")
        case 70..<90:
            return (.strong, "Fuerte")
        default:
            return (.veryStrong, "Muy fuerte")
        }
    }
}

enum PasswordStrength: Int, Comparable {
    case veryWeak = 0
    case weak = 1
    case fair = 2
    case strong = 3
    case veryStrong = 4
    
    var color: String {
        switch self {
        case .veryWeak: return "red"
        case .weak: return "orange"
        case .fair: return "yellow"
        case .strong: return "green"
        case .veryStrong: return "blue"
        }
    }
    
    static func < (lhs: PasswordStrength, rhs: PasswordStrength) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
