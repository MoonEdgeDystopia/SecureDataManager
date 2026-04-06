//
//  Data+Extensions.swift
//  SecureDataManager
//

import Foundation
import CryptoKit

extension Data {
    /// Convierte los datos a una cadena hexadecimal
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Convierte los datos a una cadena Base64
    var base64String: String {
        return base64EncodedString()
    }
    
    /// Inicializa datos desde una cadena hexadecimal
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        
        for i in 0..<length {
            let startIndex = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let endIndex = hexString.index(startIndex, offsetBy: 2)
            let bytes = hexString[startIndex..<endIndex]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        
        self = data
    }
    
    /// Limpia los datos de forma segura sobrescribiendo con ceros
    mutating func secureClear() {
        let count = self.count
        self.withUnsafeMutableBytes { rawBuffer in
            if let baseAddress = rawBuffer.baseAddress {
                memset(baseAddress, 0, count)
            }
        }
    }
}

extension SymmetricKey {
    /// Convierte la clave a datos
    var data: Data {
        return withUnsafeBytes { Data($0) }
    }
}
