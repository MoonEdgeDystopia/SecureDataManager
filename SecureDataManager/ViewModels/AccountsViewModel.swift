//
//  AccountsViewModel.swift
//  SecureDataManager
//
//  ViewModel para gestión de cuentas
//

import Foundation
import Combine
import CryptoKit

/// ViewModel para gestión de cuentas cifradas
class AccountsViewModel: ObservableObject {
    
    @Published var accounts: [EncryptedAccount] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let dataStore = DataStore.shared
    private var cancellables = Set<AnyCancellable>()
    private var masterKey: SymmetricKey?
    
    var filteredAccounts: [EncryptedAccount] {
        if searchText.isEmpty {
            return accounts
        }
        // Nota: Para búsqueda real necesitaríamos descifrar los nombres de servicio
        // Por ahora retornamos todos y la búsqueda se hace en la UI descifrando
        return accounts
    }
    
    init() {
        setupBindings()
        loadAccounts()
    }
    
    func setMasterKey(_ key: SymmetricKey) {
        self.masterKey = key
    }
    
    private func setupBindings() {
        dataStore.$accounts
            .receive(on: DispatchQueue.main)
            .assign(to: &$accounts)
    }
    
    private func loadAccounts() {
        accounts = dataStore.accounts
    }
    
    // MARK: - CRUD
    
    func addAccount(
        serviceName: String,
        username: String?,
        email: String?,
        password: String,
        notes: String?,
        totpSecret: String?
    ) {
        guard let masterKey = masterKey else {
            errorMessage = "No hay clave de cifrado disponible"
            return
        }
        
        isLoading = true
        
        do {
            let account = try EncryptedAccount(
                serviceName: serviceName,
                username: username,
                email: email,
                password: password,
                notes: notes,
                totpSecret: totpSecret,
                encryptionKey: masterKey
            )
            
            dataStore.addAccount(account)
            isLoading = false
            
        } catch {
            errorMessage = "Error al cifrar la cuenta: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func updateAccount(
        _ account: EncryptedAccount,
        serviceName: String,
        username: String?,
        email: String?,
        password: String,
        notes: String?,
        totpSecret: String?
    ) {
        guard let masterKey = masterKey else {
            errorMessage = "No hay clave de cifrado disponible"
            return
        }
        
        isLoading = true
        
        do {
            var updatedAccount = account
            try updatedAccount.update(
                serviceName: serviceName,
                username: username,
                email: email,
                password: password,
                notes: notes,
                totpSecret: totpSecret,
                encryptionKey: masterKey
            )
            
            dataStore.updateAccount(updatedAccount)
            isLoading = false
            
        } catch {
            errorMessage = "Error al actualizar la cuenta: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func deleteAccount(_ account: EncryptedAccount) {
        dataStore.deleteAccount(account)
    }
    
    func deleteAccounts(at offsets: IndexSet) {
        dataStore.deleteAccount(at: offsets)
    }
    
    // MARK: - Descifrado
    
    func decryptServiceName(for account: EncryptedAccount) -> String {
        guard let masterKey = masterKey else { return "••••••••" }
        
        do {
            return try account.decryptServiceName(key: masterKey)
        } catch {
            return "Error"
        }
    }
    
    func decryptUsername(for account: EncryptedAccount) -> String? {
        guard let masterKey = masterKey else { return nil }
        
        do {
            return try account.decryptUsername(key: masterKey)
        } catch {
            return nil
        }
    }
    
    func decryptEmail(for account: EncryptedAccount) -> String? {
        guard let masterKey = masterKey else { return nil }
        
        do {
            return try account.decryptEmail(key: masterKey)
        } catch {
            return nil
        }
    }
    
    func decryptPassword(for account: EncryptedAccount) -> String {
        guard let masterKey = masterKey else { return "" }
        
        do {
            return try account.decryptPassword(key: masterKey)
        } catch {
            return ""
        }
    }
    
    func decryptNotes(for account: EncryptedAccount) -> String? {
        guard let masterKey = masterKey else { return nil }
        
        do {
            return try account.decryptNotes(key: masterKey)
        } catch {
            return nil
        }
    }
    
    // MARK: - Búsqueda
    
    func searchAccounts(query: String) -> [EncryptedAccount] {
        guard !query.isEmpty else { return accounts }
        guard let masterKey = masterKey else { return accounts }
        
        let lowerQuery = query.lowercased()
        
        return accounts.filter { account in
            do {
                let serviceName = try account.decryptServiceName(key: masterKey).lowercased()
                let username = try account.decryptUsername(key: masterKey)?.lowercased() ?? ""
                let email = try account.decryptEmail(key: masterKey)?.lowercased() ?? ""
                
                return serviceName.contains(lowerQuery) ||
                       username.contains(lowerQuery) ||
                       email.contains(lowerQuery)
            } catch {
                return false
            }
        }
    }
}
