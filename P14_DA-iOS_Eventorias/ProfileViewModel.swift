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

@MainActor
@Observable
class ProfileViewModel {
    var profile: UserProfile?
    var isLoading = false
    var errorMessage: String?
    
    private let db = Firestore.firestore()
    
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
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    do {
                        self.profile = try snapshot.data(as: UserProfile.self)
                    } catch {
                        self.errorMessage = "Erreur de décodage du profil."
                    }
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
        guard let id = profile.id else { return }
        
        do {
            try db.collection("users").document(id).setData(from: profile)
            self.profile = profile
        } catch {
            self.errorMessage = "Erreur lors de la création du profil."
        }
    }
    
    func toggleNotifications(authManager: AuthManager, isOn: Bool) {
        guard let uid = authManager.currentUser?.uid, profile != nil else { return }
        
        // Optimistic update
        self.profile?.notificationsEnabled = isOn
        
        db.collection("users").document(uid).updateData([
            "notificationsEnabled": isOn
        ]) { error in
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
        
        db.collection("users").document(uid).updateData([
            "name": newName
        ]) { error in
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
        
        let storage = Storage.storage(url: "gs://p14-eventorias-3818.firebasestorage.app")
        let storageRef = storage.reference().child("profile_images/\(uid).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { uploadedMeta, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Échec de l'upload: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                storageRef.downloadURL { url, error in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.isLoading = false
                        
                        if let error = error {
                            self.errorMessage = "Échec de la récupération de l'URL: \(error.localizedDescription)"
                            return
                        }
                        
                        if let avatarUrl = url?.absoluteString {
                            self.profile?.avatarUrl = avatarUrl
                            self.db.collection("users").document(uid).updateData(["avatarUrl": avatarUrl])
                        }
                    }
                }
            }
        }
    }
}
