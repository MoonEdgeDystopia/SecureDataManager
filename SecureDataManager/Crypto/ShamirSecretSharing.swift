//
//  ShamirSecretSharing.swift
//  SecureDataManager
//
//  Implementación de Shamir's Secret Sharing usando curvas polinómicas
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
        guard let data = Data(base64Encoded: shareCode), data.count > 3 else {
            return nil
        }
        
        self.index = data[0]
        self.threshold = Int(data[1])
        self.totalShares = Int(data[2])
        self.value = data.dropFirst(3)
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
    case invalidSecretLength
    
    var errorDescription: String? {
        switch self {
        case .invalidThreshold:
            return "El umbral debe ser mayor que 1 y menor o igual al número de shares"
        case .invalidShareCount:
            return "Número inválido de shares"
        case .insufficientShares:
            return "Shares insuficientes para reconstruir el secreto"
        case .invalidShare:
            return "Share inválido o corrupto"
        case .reconstructionFailed:
            return "Error al reconstruir el secreto"
        case .invalidSecretLength:
            return "Longitud del secreto inválida"
        }
    }
}

/// Implementación de Shamir's Secret Sharing
class ShamirSecretSharing {
    
    // Campo primo para operaciones aritméticas (2^31 - 1 = número primo de Mersenne)
    // Usamos un primo grande para mayor seguridad
    private let prime: UInt32 = 2147483647
    
    /// Divide un secreto en múltiples shares
    /// - Parameters:
    ///   - secret: El secreto a dividir (debe ser múltiplo de 16 bytes)
    ///   - totalShares: Número total de shares a generar (5)
    ///   - threshold: Número mínimo de shares necesarios para reconstruir (3)
    /// - Returns: Array de shares
    func split(secret: Data, totalShares: Int = 5, threshold: Int = 3) throws -> [SecretShare] {
        guard threshold > 1 && threshold <= totalShares else {
            throw ShamirError.invalidThreshold
        }
        
        guard totalShares <= 255 else {
            throw ShamirError.invalidShareCount
        }
        
        // Asegurar que el secreto sea múltiplo de 16 bytes (tamaño de bloque AES)
        var paddedSecret = secret
        let paddingNeeded = 16 - (secret.count % 16)
        if paddingNeeded != 16 {
            paddedSecret.append(contentsOf: [UInt8](repeating: UInt8(paddingNeeded), count: paddingNeeded))
        }
        
        // Dividir el secreto en bloques de 4 bytes para trabajar con UInt32
        let blockSize = 4
        var shares: [[SecretShare]] = []
        
        // Procesar cada bloque del secreto
        for blockStart in stride(from: 0, to: paddedSecret.count, by: blockSize) {
            let blockEnd = min(blockStart + blockSize, paddedSecret.count)
            let block = paddedSecret[blockStart..<blockEnd]
            
            // Convertir bloque a UInt32
            var secretValue: UInt32 = 0
            for (i, byte) in block.enumerated() {
                secretValue |= UInt32(byte) << (8 * i)
            }
            
            // Generar polinomio aleatorio de grado (threshold - 1)
            // f(x) = secret + a1*x + a2*x^2 + ... + a(threshold-1)*x^(threshold-1)
            var coefficients: [UInt32] = [secretValue]
            for _ in 1..<threshold {
                coefficients.append(randomUInt32())
            }
            
            // Generar shares para este bloque
            var blockShares: [SecretShare] = []
            for i in 1...totalShares {
                let x = UInt8(i)
                let y = evaluatePolynomial(coefficients: coefficients, x: UInt32(x))
                
                // Convertir y a Data (4 bytes, little endian)
                var yData = Data(count: 4)
                yData[0] = UInt8(y & 0xFF)
                yData[1] = UInt8((y >> 8) & 0xFF)
                yData[2] = UInt8((y >> 16) & 0xFF)
                yData[3] = UInt8((y >> 24) & 0xFF)
                
                blockShares.append(SecretShare(
                    index: x,
                    value: yData,
                    threshold: threshold,
                    totalShares: totalShares
                ))
            }
            
            shares.append(blockShares)
        }
        
        // Combinar shares de todos los bloques
        var finalShares: [SecretShare] = []
        for i in 0..<totalShares {
            var combinedValue = Data()
            for blockShares in shares {
                combinedValue.append(blockShares[i].value)
            }
            
            finalShares.append(SecretShare(
                index: UInt8(i + 1),
                value: combinedValue,
                threshold: threshold,
                totalShares: totalShares
            ))
        }
        
        return finalShares
    }
    
    /// Reconstruye el secreto desde los shares
    /// - Parameter shares: Array de shares (debe tener al menos 'threshold' shares)
    /// - Returns: El secreto reconstruido
    func combine(shares: [SecretShare]) throws -> Data {
        guard !shares.isEmpty else {
            throw ShamirError.insufficientShares
        }
        
        let threshold = shares[0].threshold
        
        guard shares.count >= threshold else {
            throw ShamirError.insufficientShares
        }
        
        // Verificar que todos los shares tengan el mismo formato
        let blockSize = 4
        let numBlocks = shares[0].value.count / blockSize
        
        guard shares.allSatisfy({ $0.value.count == shares[0].value.count }) else {
            throw ShamirError.invalidShare
        }
        
        var reconstructedSecret = Data()
        
        // Reconstruir cada bloque usando interpolación de Lagrange
        for blockIndex in 0..<numBlocks {
            // Preparar puntos para este bloque
            var points: [(x: UInt32, y: UInt32)] = []
            
            for share in shares.prefix(threshold) {
                let blockStart = blockIndex * blockSize
                let block = share.value[blockStart..<(blockStart + blockSize)]
                
                let x = UInt32(share.index)
                let y = UInt32(block[0]) |
                         (UInt32(block[1]) << 8) |
                         (UInt32(block[2]) << 16) |
                         (UInt32(block[3]) << 24)
                
                points.append((x: x, y: y))
            }
            
            // Interpolación de Lagrange para encontrar f(0) = secreto
            let secret = lagrangeInterpolation(points: points)
            
            // Convertir secreto a bytes
            reconstructedSecret.append(UInt8(secret & 0xFF))
            reconstructedSecret.append(UInt8((secret >> 8) & 0xFF))
            reconstructedSecret.append(UInt8((secret >> 16) & 0xFF))
            reconstructedSecret.append(UInt8((secret >> 24) & 0xFF))
        }
        
        // Remover padding PKCS7
        if let lastByte = reconstructedSecret.last, lastByte > 0 && lastByte <= 16 {
            let paddingLength = Int(lastByte)
            if reconstructedSecret.count >= paddingLength {
                let paddingStart = reconstructedSecret.count - paddingLength
                let isValidPadding = reconstructedSecret[paddingStart...].allSatisfy { $0 == lastByte }
                if isValidPadding {
                    reconstructedSecret = reconstructedSecret[0..<paddingStart]
                }
            }
        }
        
        return reconstructedSecret
    }
    
    // MARK: - Operaciones en Campo Finito
    
    /// Genera un número aleatorio en el campo
    private func randomUInt32() -> UInt32 {
        var randomBytes = Data(count: 4)
        _ = randomBytes.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 4, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        return (UInt32(randomBytes[0]) |
                (UInt32(randomBytes[1]) << 8) |
                (UInt32(randomBytes[2]) << 16) |
                (UInt32(randomBytes[3]) << 24)) % prime
    }
    
    /// Evalúa un polinomio en el punto x
    private func evaluatePolynomial(coefficients: [UInt32], x: UInt32) -> UInt32 {
        var result: UInt32 = 0
        var power: UInt32 = 1
        
        for coef in coefficients {
            result = modularAdd(result, modularMultiply(coef, power))
            power = modularMultiply(power, x)
        }
        
        return result
    }
    
    /// Interpolación de Lagrange para encontrar f(0)
    private func lagrangeInterpolation(points: [(x: UInt32, y: UInt32)]) -> UInt32 {
        var result: UInt32 = 0
        
        for i in 0..<points.count {
            var numerator: UInt32 = 1
            var denominator: UInt32 = 1
            
            for j in 0..<points.count {
                if i != j {
                    // (x - xj) para x = 0 => -xj
                    numerator = modularMultiply(numerator, (prime - points[j].x) % prime)
                    // (xi - xj)
                    let diff = (points[i].x + prime - points[j].x) % prime
                    denominator = modularMultiply(denominator, diff)
                }
            }
            
            // yi * numerador / denominador
            let term = modularMultiply(points[i].y, modularMultiply(numerator, modularInverse(denominator)))
            result = modularAdd(result, term)
        }
        
        return result
    }
    
    /// Suma modular
    private func modularAdd(_ a: UInt32, _ b: UInt32) -> UInt32 {
        return (a + b) % prime
    }
    
    /// Multiplicación modular
    private func modularMultiply(_ a: UInt32, _ b: UInt32) -> UInt32 {
        return UInt32((UInt64(a) * UInt64(b)) % UInt64(prime))
    }
    
    /// Inverso modular usando el algoritmo extendido de Euclides
    private func modularInverse(_ a: UInt32) -> UInt32 {
        var t: Int64 = 0
        var newT: Int64 = 1
        var r = Int64(prime)
        var newR = Int64(a)
        
        while newR != 0 {
            let quotient = r / newR
            (t, newT) = (newT, t - quotient * newT)
            (r, newR) = (newR, r - quotient * newR)
        }
        
        if t < 0 {
            t += Int64(prime)
        }
        
        return UInt32(t)
    }
}
