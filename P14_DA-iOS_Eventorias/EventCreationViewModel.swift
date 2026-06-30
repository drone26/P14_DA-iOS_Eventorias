import Foundation
import SwiftUI
import CoreLocation
import FirebaseFirestore
import FirebaseStorage
import Observation
import FirebaseAuth
import MapKit

@MainActor
@Observable
class EventCreationViewModel {
    var title = ""
    var description = ""
    var date = Date()
    var time = Date()
    var address = ""
    
    var selectedImage: UIImage?
    
    var isLoading = false
    var errorMessage: String?
    
    func createEvent(authManager: AuthManager, completion: @escaping (Bool) -> Void) {
        guard !title.isEmpty, !description.isEmpty, !address.isEmpty else {
            errorMessage = "Please fill in all fields."
            completion(false)
            return
        }
        
        guard let currentUser = authManager.currentUser else {
            errorMessage = "User not logged in."
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Merge date and time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var mergedComponents = DateComponents()
        mergedComponents.year = dateComponents.year
        mergedComponents.month = dateComponents.month
        mergedComponents.day = dateComponents.day
        mergedComponents.hour = timeComponents.hour
        mergedComponents.minute = timeComponents.minute
        
        guard let finalDate = calendar.date(from: mergedComponents) else {
            errorMessage = "Invalid date/time."
            isLoading = false
            completion(false)
            return
        }
        
        // Geocode address using MKLocalSearch
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        let search = MKLocalSearch(request: request)
        
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    self.errorMessage = "Address not found: \(error.localizedDescription)"
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                guard let mapItem = response?.mapItems.first else {
                    self.errorMessage = "Could not validate address."
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                // Format address properly
                // Since `placemark` is deprecated, we can use the map item's name or fallback to the validated user input.
                let validatedAddress = mapItem.name ?? self.address
                
                self.uploadImageAndSaveEvent(
                    title: self.title,
                    description: self.description,
                    date: finalDate,
                    address: validatedAddress,
                    creatorId: currentUser.uid,
                    completion: completion
                )
            }
        }
    }
    
    private func uploadImageAndSaveEvent(title: String, description: String, date: Date, address: String, creatorId: String, completion: @escaping (Bool) -> Void) {
        if let image = selectedImage {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                errorMessage = "Could not process image."
                isLoading = false
                completion(false)
                return
            }
            
            let storage = Storage.storage(url: "gs://p14-eventorias-3818.firebasestorage.app")
            let storageRef = storage.reference().child("event_images/\(UUID().uuidString).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.putData(imageData, metadata: metadata) { [weak self] uploadedMeta, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                        self.isLoading = false
                        completion(false)
                        return
                    }
                    
                    storageRef.downloadURL { url, error in
                        Task { @MainActor in
                            if let error = error {
                                self.errorMessage = "Failed to get image URL: \(error.localizedDescription)"
                                self.isLoading = false
                                completion(false)
                                return
                            }
                            
                            self.saveEventToFirestore(title: title, description: description, date: date, address: address, creatorId: creatorId, imageUrl: url?.absoluteString, completion: completion)
                        }
                    }
                }
            }
        } else {
            saveEventToFirestore(title: title, description: description, date: date, address: address, creatorId: creatorId, imageUrl: nil, completion: completion)
        }
    }
    
    private func saveEventToFirestore(title: String, description: String, date: Date, address: String, creatorId: String, imageUrl: String?, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let event = Event(
            title: title,
            description: description,
            date: date,
            address: address,
            creatorId: creatorId,
            coverImageUrl: imageUrl
        )
        
        do {
            let _ = try db.collection("events").addDocument(from: event) { error in
                Task { @MainActor in
                    if let error = error {
                        self.errorMessage = "Failed to save event: \(error.localizedDescription)"
                        self.isLoading = false
                        completion(false)
                    } else {
                        self.isLoading = false
                        completion(true)
                    }
                }
            }
        } catch {
            self.errorMessage = "Failed to encode event: \(error.localizedDescription)"
            self.isLoading = false
            completion(false)
        }
    }
}
