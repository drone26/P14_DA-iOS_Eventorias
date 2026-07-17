//
//  EmailSignInViewModel.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import Foundation
import FirebaseAuth
import Observation
import UIKit

@Observable
class EmailSignInViewModel {
    var email = ""
    var password = ""
    var isRegistering = false
    var errorMessage = ""
    var isLoading = false
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = Auth.auth()) {
        self.authService = authService
    }
    
    func authenticate() {
        // Force dismiss keyboard before starting network request
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        errorMessage = ""
        
        if isRegistering {
            if let validationError = validatePassword(password) {
                errorMessage = validationError
                return
            }
        }
        
        isLoading = true
        
        if isRegistering {
            authService.createUser(withEmail: email, password: password) { [weak self] result, error in
                self?.isLoading = false
                if let error = error {
                    self?.handleError(error)
                }
            }
        } else {
            authService.signIn(withEmail: email, password: password) { [weak self] result, error in
                self?.isLoading = false
                if let error = error {
                    self?.handleError(error)
                }
            }
        }
    }
    
    private func handleError(_ error: Error) {
        let nsError = error as NSError
        if let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
            switch authErrorCode {
            case .weakPassword:
                errorMessage = "Le mot de passe est trop faible. Il doit contenir au moins 20 caractères."
            case .invalidEmail:
                errorMessage = "L'adresse email n'est pas valide."
            case .emailAlreadyInUse:
                errorMessage = "Un compte existe déjà pour cette adresse email."
            case .wrongPassword, .userNotFound:
                errorMessage = "Email ou mot de passe incorrect."
            case .internalError:
                errorMessage = "Une erreur interne s'est produite. Veuillez réessayer."
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleRegistering() {
        isRegistering.toggle()
        errorMessage = ""
    }
    
    private func validatePassword(_ pass: String) -> String? {
        if pass.count < 20 {
            return "Le mot de passe doit contenir au moins 20 caractères."
        }
        if pass.count > 4096 {
            return "Le mot de passe ne peut excéder 4096 caractères."
        }
        if pass.rangeOfCharacter(from: .uppercaseLetters) == nil {
            return "Le mot de passe doit contenir au moins une lettre majuscule."
        }
        if pass.rangeOfCharacter(from: .lowercaseLetters) == nil {
            return "Le mot de passe doit contenir au moins une lettre minuscule."
        }
        if pass.rangeOfCharacter(from: .decimalDigits) == nil {
            return "Le mot de passe doit contenir au moins un chiffre."
        }
        if pass.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil {
            return "Le mot de passe doit contenir au moins un caractère spécial."
        }
        return nil
    }
}
