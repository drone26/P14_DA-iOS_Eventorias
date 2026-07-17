//
//  EventCreationViewModel.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import Foundation
import SwiftUI
import CoreLocation
import FirebaseFirestore
import FirebaseStorage
import Observation
import FirebaseAuth
import MapKit

final class DefaultGeocodingService: @unchecked Sendable, GeocodingServiceProtocol {
    func validateAddress(_ address: String, completion: @escaping (String?, Error?) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            if let mapItem = response?.mapItems.first {
                completion(mapItem.name ?? address, nil)
            } else {
                completion(nil, nil)
            }
        }
    }
}

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
    
    private let eventRepository: EventRepositoryProtocol
    private let storageService: ImageStorageServiceProtocol
    private let geocodingService: GeocodingServiceProtocol
    
    init(eventRepository: EventRepositoryProtocol? = nil,
         storageService: ImageStorageServiceProtocol? = nil,
         geocodingService: GeocodingServiceProtocol? = nil) {
        self.eventRepository = eventRepository ?? FirebaseEventRepository()
        self.storageService = storageService ?? FirebaseImageStorageService()
        self.geocodingService = geocodingService ?? DefaultGeocodingService()
    }
    
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
        
        geocodingService.validateAddress(address) { [weak self] validatedAddress, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Address not found: \(error.localizedDescription)"
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                guard let validatedAddress = validatedAddress else {
                    self.errorMessage = "Could not validate address."
                    self.isLoading = false
                    completion(false)
                    return
                }
                
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
            
            let path = "event_images/\(UUID().uuidString).jpg"
            
            storageService.uploadImage(imageData, path: path) { [weak self] url, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                        self.isLoading = false
                        completion(false)
                        return
                    }
                    
                    self.saveEventToFirestore(title: title, description: description, date: date, address: address, creatorId: creatorId, imageUrl: url?.absoluteString, completion: completion)
                }
            }
        } else {
            saveEventToFirestore(title: title, description: description, date: date, address: address, creatorId: creatorId, imageUrl: nil, completion: completion)
        }
    }
    
    private func saveEventToFirestore(title: String, description: String, date: Date, address: String, creatorId: String, imageUrl: String?, completion: @escaping (Bool) -> Void) {
        let event = Event(
            title: title,
            description: description,
            date: date,
            address: address,
            creatorId: creatorId,
            coverImageUrl: imageUrl
        )
        
        eventRepository.addEvent(event) { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    self?.errorMessage = "Failed to save event: \(error.localizedDescription)"
                    self?.isLoading = false
                    completion(false)
                } else {
                    self?.isLoading = false
                    completion(true)
                }
            }
        }
    }
}
