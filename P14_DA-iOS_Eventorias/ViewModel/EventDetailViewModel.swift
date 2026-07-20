//
//  EventDetailViewModel.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class EventDetailViewModel {
    var isDeleting = false
    var errorMessage: String?
    
    private let eventRepository: EventRepositoryProtocol
    private let storageService: ImageStorageServiceProtocol
    
    init(eventRepository: EventRepositoryProtocol? = nil,
         storageService: ImageStorageServiceProtocol? = nil) {
        self.eventRepository = eventRepository ?? FirebaseEventRepository()
        self.storageService = storageService ?? FirebaseImageStorageService()
    }
    
    /// Deletes the event and reports whether it succeeded via the completion handler.
    /// The associated cover image is removed on a best-effort basis once the event document
    /// is gone; a failure to clean up the image does not fail the deletion.
    func deleteEvent(_ event: Event, completion: @escaping (Bool) -> Void) {
        guard event.id != nil else {
            errorMessage = "Cannot delete an event without an identifier."
            completion(false)
            return
        }
        
        isDeleting = true
        errorMessage = nil
        
        eventRepository.deleteEvent(event) { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isDeleting = false
                if let error = error {
                    self.errorMessage = "Failed to delete event: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                // Best-effort cleanup of the associated cover image.
                if let imageUrl = event.coverImageUrl, !imageUrl.isEmpty {
                    self.storageService.deleteImage(url: imageUrl) { _ in }
                }
                completion(true)
            }
        }
    }
}
