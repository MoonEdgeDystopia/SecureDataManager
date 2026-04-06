//
//  SecureDataManagerApp.swift
//  SecureDataManager
//
//  Punto de entrada de la aplicación
//

import SwiftUI

@main
struct SecureDataManagerApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// AppDelegate para configuración adicional
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Configurar apariencia
        configureAppearance()
        
        // Configurar seguridad
        configureSecurity()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Limpiar datos sensibles de la UI cuando la app va a background
        NotificationCenter.default.post(name: .appDidEnterBackground, object: nil)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Notificar que la app vuelve a primer plano
        NotificationCenter.default.post(name: .appWillEnterForeground, object: nil)
    }
    
    private func configureAppearance() {
        // Configurar navegación
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func configureSecurity() {
        // Prevenir capturas de pantalla en áreas sensibles
        // Esto se maneja por vista usando .privacyScreen() o similar
    }
}

// MARK: - Notificaciones

extension Notification.Name {
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
    static let userDidLogout = Notification.Name("userDidLogout")
}
