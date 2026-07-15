//
//  AuthManager.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import Foundation
import FirebaseAuth
import Observation

@Observable
class AuthManager {
    var isAuthenticated: Bool = false
    var currentUser: AppUserProtocol?
    
    private let authService: AuthServiceProtocol
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init(authService: AuthServiceProtocol = Auth.auth()) {
        self.authService = authService
        self.authStateListenerHandle = self.authService.addStateDidChangeListener { [weak self] auth, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            authService.removeStateDidChangeListener(handle)
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
