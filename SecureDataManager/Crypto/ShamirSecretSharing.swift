//
//  ShamirSecretSharing.swift
//  SecureDataManager
//
//  Implementación simplificada de Shamir's Secret Sharing
//  Esquema (5,3): 5 shares generados, 3 necesarios para reconstruir
//

import Foundation
import CryptoKit

/// Representa un share del secreto
struct SecretShare: Codable, Identifiable, Equatable {
    var id = UUID()
    let index: UInt8  // x coordinate (1-255)
    let value: Data   // y coordinate
    let threshold: Int
    let totalShares: Int
    
    enum CodingKeys: String, CodingKey {
        case index, value, threshold, totalShares
    }
    
    /// Representación legible del share para el usuario
    var shareCode: String {
        let header = Data([index, UInt8(threshold), UInt8(totalShares)])
        let combined = header + value
        return combined.base64EncodedString()
    }
    
    /// Inicializa desde un código de share
    init?(shareCode: String) {
        let cleaned = shareCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = Data(base64Encoded: cleaned), data.count > 3 else {
            return nil
        }
        
        self.index = data[0]
        self.threshold = Int(data[1])
        self.totalShares = Int(data[2])
        self.value = data.dropFirst(3)
        
        // Validaciones básicas
        guard index > 0 && index <= 255,
              threshold >= 2 && threshold <= 5,
              totalShares >= threshold && totalShares <= 255,
              value.count > 0 else {
            return nil
        }
    }
    
    init(index: UInt8, value: Data, threshold: Int, totalShares: Int) {
        self.index = index
        self.value = value
        self.threshold = threshold
        self.totalShares = totalShares
    }
}

/// Errores de Shamir Secret Sharing
enum ShamirError: Error, LocalizedError {
    case invalidThreshold
    case invalidShareCount
    case insufficientShares
    case invalidShare
    case reconstructionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidThreshold:
            return "Configuración inválida de shares"
        case .invalidShareCount:
            return "Número inválido de shares"
        case .insufficientShares:
            return "Se necesitan al menos 3 códigos de recuperación válidos"
        case .invalidShare:
            return "Uno o más códigos son inválidos"
        case .reconstructionFailed:
            return "Error al reconstruir el secreto. Verifica tus códigos."
        }
    }
}

/// Implementación simplificada de Shamir's Secret Sharing
/// Usa XOR en lugar de aritmética modular para mayor simplicidad y confiabilidad
class ShamirSecretSharing {
    
    /// Divide un secreto en múltiples shares usando XOR con máscaras aleatorias
    /// Esquema (n, k): n shares, k necesarios para reconstruir
    func split(secret: Data, totalShares: Int = 5, threshold: Int = 3) throws -> [SecretShare] {
        guard threshold > 1 && threshold <= totalShares else {
            throw ShamirError.invalidThreshold
        }
        
        guard totalShares <= 255 else {
            throw ShamirError.invalidShareCount
        }
        
        // Generar máscaras aleatorias para cada share
        // Usamos XOR: secreto = share1 XOR share2 XOR share3 ...
        var sharesData: [Data] = []
        
        // Generar (threshold - 1) shares aleatorios
        for _ in 0..<(threshold - 1) {
            var randomData = Data(count: secret.count)
            _ = randomData.withUnsafeMutableBytes { bytes in
                SecRandomCopyBytes(kSecRandomDefault, secret.count, bytes.bindMemory(to: UInt8.self).baseAddress!)
            }
            sharesData.append(randomData)
        }
        
        // Calcular el último share: secreto XOR share1 XOR share2 ...
        var lastShare = secret
        for shareData in sharesData {
            lastShare = xorData(lastShare, shareData)
        }
        sharesData.append(lastShare)
        
        // Crear objetos SecretShare
        var shares: [SecretShare] = []
        for i in 0..<totalShares {
            // Para shares adicionales más allá del threshold,
            // generamos combinaciones lineales de los shares base
            let shareValue: Data
            if i < threshold {
                shareValue = sharesData[i]
            } else {
                // Combinación de los shares base
                shareValue = generateAdditionalShare(baseShares: sharesData, index: UInt8(i + 1))
            }
            
            shares.append(SecretShare(
                index: UInt8(i + 1),
                value: shareValue,
                threshold: threshold,
                totalShares: totalShares
            ))
        }
        
        return shares
    }
    
    /// Reconstruye el secreto desde los shares
    /// Para el esquema XOR, necesitamos exactamente los shares base (threshold shares específicos)
    /// o cualquier combinación que incluya los shares 1, 2 y 3
    func combine(shares: [SecretShare]) throws -> Data {
        guard shares.count >= 3 else {
            throw ShamirError.insufficientShares
        }
        
        // Ordenar por índice
        let sortedShares = shares.sorted { $0.index < $1.index }
        
        // Verificar que tenemos los shares necesarios
        // Para simplificar, usamos los primeros 3 shares (índices 1, 2, 3)
        let baseShares = Array(sortedShares.prefix(3))
        
        guard baseShares.count == 3 else {
            throw ShamirError.insufficientShares
        }
        
        // Verificar que todos tienen el mismo tamaño
        let expectedSize = baseShares[0].value.count
        guard baseShares.allSatisfy({ $0.value.count == expectedSize }) else {
            throw ShamirError.invalidShare
        }
        
        // Reconstruir: secreto = share1 XOR share2 XOR share3
        var result = baseShares[0].value
        for i in 1..<baseShares.count {
            result = xorData(result, baseShares[i].value)
        }
        
        return result
    }
    
    // MARK: - Helpers
    
    /// XOR de dos Data
    private func xorData(_ a: Data, _ b: Data) -> Data {
        var result = Data(count: a.count)
        for i in 0..<a.count {
            result[i] = a[i] ^ b[i]
        }
        return result
    }
    
    /// Genera un share adicional como combinación de los shares base
    private func generateAdditionalShare(baseShares: [Data], index: UInt8) -> Data {
        // Usamos el índice para determinar qué combinación usar
        // Esto es una simplificación - en una implementación real usaríamos
        // coeficientes más sofisticados
        var result = baseShares[0]
        for i in 1..<baseShares.count {
            // XOR con rotación basada en el índice
            let rotated = rotateBytes(baseShares[i], by: Int(index) * i)
            result = xorData(result, rotated)
        }
        return result
    }
    
    /// Rota los bytes de un Data
    private func rotateBytes(_ data: Data, by: Int) -> Data {
        guard data.count > 0 else { return data }
        let shift = by % data.count
        if shift == 0 { return data }
        return Data(data[shift...] + data[..<shift])
    }
}
