//
//  Category.swift
//  SecureDataManager
//
//  Categorías de datos soportadas por la aplicación
//

import Foundation

/// Categorías de datos que pueden almacenarse en la aplicación
enum DataCategory: String, CaseIterable, Identifiable, Codable {
    case accounts = "Cuentas"
    case documents = "Documentos"
    case photos = "Fotos"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .accounts:
            return "key.fill"
        case .documents:
            return "doc.fill"
        case .photos:
            return "photo.fill"
        }
    }
    
    var color: String {
        switch self {
        case .accounts:
            return "blue"
        case .documents:
            return "green"
        case .photos:
            return "purple"
        }
    }
}
