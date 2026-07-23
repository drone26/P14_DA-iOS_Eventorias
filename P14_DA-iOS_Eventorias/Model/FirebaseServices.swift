//
//  FirebaseServices.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

final class FirebaseEventRepository: @unchecked Sendable, EventRepositoryProtocol {
    private let db: FirestoreProtocol
    
    init(db: FirestoreProtocol = DefaultFirestore()) {
        self.db = db
    }
    
    func fetchEvents(searchQuery: String, sortOption: SortOption, completion: @escaping ([Event]?, Error?) -> Void) -> ListenerRegistrationProtocol {
        var query: QueryProtocol = db.collection("events")
        let isSearching = !searchQuery.isEmpty
        
        if isSearching {
            let lowerQuery = searchQuery.lowercased()
            query = query.whereField("searchTokens", arrayContains: lowerQuery)
        } else {
            switch sortOption {
            case .dateAsc:
                query = query.order(by: "date", descending: false)
            case .dateDesc:
                query = query.order(by: "date", descending: true)
            case .titleAsc:
                query = query.order(by: "titleLower", descending: false)
            }
        }
        
        let listener = query.addSnapshotListener { snapshot, error in
            Task { @MainActor in
                if let error {
                    completion(nil, error)
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                var fetchedEvents = documents.compactMap { try? $0.data(as: Event.self) }
                
                if isSearching {
                    switch sortOption {
                    case .dateAsc:
                        fetchedEvents.sort { $0.date < $1.date }
                    case .dateDesc:
                        fetchedEvents.sort { $0.date > $1.date }
                    case .titleAsc:
                        fetchedEvents.sort { ($0.titleLower ?? "") < ($1.titleLower ?? "") }
                    }
                }
                completion(fetchedEvents, nil)
            }
        }
        return listener
    }
    
    func addEvent(_ event: Event, completion: @escaping (Error?) -> Void) {
        do {
            _ = try db.collection("events").addDocument(from: event) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
    
    func deleteEvent(_ event: Event, completion: @escaping (Error?) -> Void) {
        guard let id = event.id else {
            completion(NSError(domain: "FirebaseEventRepository", code: -1,
                               userInfo: [NSLocalizedDescriptionKey: "Event has no identifier."]))
            return
        }
        db.collection("events").document(id).delete(completion: completion)
    }
}

final class FirebaseUserRepository: @unchecked Sendable, UserRepositoryProtocol {
    private let db: FirestoreProtocol
    
    init(db: FirestoreProtocol = DefaultFirestore()) {
        self.db = db
    }
    
    func getProfile(uid: String, completion: @escaping (UserProfile?, Error?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            Task { @MainActor in
                if let error {
                    completion(nil, error)
                    return
                }
                if let snapshot, snapshot.exists {
                    do {
                        let profile = try snapshot.data(as: UserProfile.self)
                        completion(profile, nil)
                    } catch {
                        completion(nil, error)
                    }
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    func updateProfile(uid: String, data: [AnyHashable : Any], completion: @escaping (Error?) -> Void) {
        db.collection("users").document(uid).updateData(data, completion: completion)
    }
    
    func saveProfile(_ profile: UserProfile, completion: @escaping (Error?) -> Void) {
        guard let id = profile.id else { return }
        do {
            try db.collection("users").document(id).setData(from: profile)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

final class FirebaseImageStorageService: @unchecked Sendable, ImageStorageServiceProtocol {
    private let storage: StorageProtocol
    
    init(storage: StorageProtocol = DefaultStorage(Storage.storage(url: "gs://p14-eventorias-3818.firebasestorage.app"))) {
        self.storage = storage
    }
    
    func uploadImage(_ imageData: Data, path: String, completion: @escaping (URL?, Error?) -> Void) {
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error {
                completion(nil, error)
                return
            }
            storageRef.downloadURL { url, error in
                completion(url, error)
            }
        }
    }
    
    func deleteImage(url: String, completion: @escaping (Error?) -> Void) {
        storage.reference(forURL: url).delete(completion: completion)
    }
}
