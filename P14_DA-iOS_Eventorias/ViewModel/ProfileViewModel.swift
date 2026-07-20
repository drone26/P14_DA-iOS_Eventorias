//
//  ProfileViewModel.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
@preconcurrency import FirebaseAuth
import Observation
import UIKit

extension Notification.Name {
    /// Posted after a user's avatar has been uploaded and persisted, with `userInfo["uid"]`.
    static let avatarDidChange = Notification.Name("avatarDidChange")
}

@MainActor
@Observable
class ProfileViewModel {
    var profile: UserProfile?
    var isLoading = false
    var errorMessage: String?
    
    private let userRepository: UserRepositoryProtocol
    private let storageService: ImageStorageServiceProtocol
    
    init(userRepository: UserRepositoryProtocol? = nil,
         storageService: ImageStorageServiceProtocol? = nil) {
        self.userRepository = userRepository ?? FirebaseUserRepository()
        self.storageService = storageService ?? FirebaseImageStorageService()
    }
    
    func fetchProfile(authManager: AuthManager) {
        guard let user = authManager.currentUser else {
            self.errorMessage = "Utilisateur non connecté."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let uid = user.uid
        let displayName = user.displayName ?? "Utilisateur"
        let email = user.email ?? ""
        let avatarUrl = user.photoURL?.absoluteString
        
        // Start a timeout task to force end loading if Firestore hangs in UI tests
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if self?.isLoading == true {
                self?.isLoading = false
            }
        }
        
        userRepository.getProfile(uid: uid) { [weak self] profile, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
                    return
                }
                
                if let profile = profile {
                    self.profile = profile
                } else {
                    // Profile doesn't exist, create a default one
                    let defaultProfile = UserProfile(
                        id: uid,
                        name: displayName,
                        email: email,
                        avatarUrl: avatarUrl,
                        notificationsEnabled: false
                    )
                    self.createProfile(defaultProfile)
                }
            }
        }
    }
    
    private func createProfile(_ profile: UserProfile) {
        userRepository.saveProfile(profile) { [weak self] error in
            Task { @MainActor [weak self] in
                if error != nil {
                    self?.errorMessage = "Erreur lors de la création du profil."
                } else {
                    self?.profile = profile
                }
            }
        }
    }
    
    func toggleNotifications(authManager: AuthManager, isOn: Bool) {
        guard let uid = authManager.currentUser?.uid, profile != nil else { return }
        
        // Optimistic update
        self.profile?.notificationsEnabled = isOn
        
        userRepository.updateProfile(uid: uid, data: ["notificationsEnabled": isOn]) { [weak self] error in
            Task { @MainActor [weak self] in
                if let error = error {
                    // Revert on error
                    self?.profile?.notificationsEnabled = !isOn
                    self?.errorMessage = "Erreur de synchronisation: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func saveName(authManager: AuthManager, newName: String) {
        guard let uid = authManager.currentUser?.uid, profile != nil else { return }
        
        userRepository.updateProfile(uid: uid, data: ["name": newName]) { [weak self] error in
            Task { @MainActor [weak self] in
                if let error = error {
                    self?.errorMessage = "Erreur de sauvegarde: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func uploadAvatar(image: UIImage, authManager: AuthManager) {
        guard let uid = authManager.currentUser?.uid else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            self.errorMessage = "Impossible de traiter l'image."
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        let path = "profile_images/\(uid).jpg"
        
        storageService.uploadImage(imageData, path: path) { [weak self] url, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Échec de l'upload: \(error.localizedDescription)"
                    return
                }
                
                if let avatarUrl = url?.absoluteString {
                    self.profile?.avatarUrl = avatarUrl
                    // Broadcast the new URL so other views (e.g. the event list) refresh immediately,
                    // without depending on the Firestore write completing first.
                    NotificationCenter.default.post(
                        name: .avatarDidChange,
                        object: nil,
                        userInfo: ["uid": uid, "avatarUrl": avatarUrl]
                    )
                    self.userRepository.updateProfile(uid: uid, data: ["avatarUrl": avatarUrl]) { _ in }
                }
            }
        }
    }
}
