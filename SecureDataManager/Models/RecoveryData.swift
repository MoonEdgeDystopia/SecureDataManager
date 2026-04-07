//
//  RecoveryData.swift
//  SecureDataManager
//
//  Modelo para datos de recuperación de cuenta
//

import Foundation

/// Datos necesarios para recuperar la cuenta
struct RecoveryData: Codable {
    let question1: String
    let answer1Hash: Data
    let question2: String
    let answer2Hash: Data
    let question3: String
    let answer3Hash: Data
    let recoveryCodeHash: Data      // Hash del código para verificación
    let recoverySalt: Data          // Salt único para recuperación
    let encryptedMasterSalt: Data   // Salt maestro encriptado con recoveryKey
    
    init(
        question1: String,
        answer1Hash: Data,
        question2: String,
        answer2Hash: Data,
        question3: String,
        answer3Hash: Data,
        recoveryCodeHash: Data,
        recoverySalt: Data,
        encryptedMasterSalt: Data
    ) {
        self.question1 = question1
        self.answer1Hash = answer1Hash
        self.question2 = question2
        self.answer2Hash = answer2Hash
        self.question3 = question3
        self.answer3Hash = answer3Hash
        self.recoveryCodeHash = recoveryCodeHash
        self.recoverySalt = recoverySalt
        self.encryptedMasterSalt = encryptedMasterSalt
    }
}

/// Sugerencias de preguntas de seguridad
struct SecurityQuestionSuggestions {
    static let suggestions = [
        "¿Cuál es el nombre de tu primera mascota?",
        "¿En qué ciudad naciste?",
        "¿Cuál es tu comida favorita?",
        "¿Nombre de tu escuela primaria?",
        "¿Cuál es el segundo nombre de tu madre?",
        "¿En qué calle creciste?",
        "¿Cuál fue tu primer trabajo?",
        "¿Nombre de tu mejor amigo de la infancia?",
        "¿Cuál es tu película favorita?",
        "¿En qué hospital naciste?"
    ]
    
    static func randomQuestions() -> [String] {
        return Array(suggestions.shuffled().prefix(3))
    }
}
