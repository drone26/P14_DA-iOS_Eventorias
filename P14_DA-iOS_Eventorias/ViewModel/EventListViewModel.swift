//
//  EventListViewModel.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import Foundation
import FirebaseFirestore
import Observation

enum SortOption: String, CaseIterable {
    case dateAsc = "Date (Proche)"
    case dateDesc = "Date (Éloigné)"
    case titleAsc = "Titre (A-Z)"
}

@Observable
class EventListViewModel {
    var events: [Event] = []
    var searchQuery: String = ""
    var sortOption: SortOption = .dateAsc
    var isLoading = false
    var errorMessage: String?
    
    private let eventRepository: EventRepositoryProtocol
    private var listenerRegistration: ListenerRegistrationProtocol?
    
    init(eventRepository: EventRepositoryProtocol? = nil) {
        self.eventRepository = eventRepository ?? FirebaseEventRepository()
    }
    
    func fetchEvents() {
        #if DEBUG
        // UI-test hook: force the error state so its UI can be exercised deterministically.
        if ProcessInfo.processInfo.arguments.contains("-UITestForceEventLoadError") {
            isLoading = false
            events = []
            errorMessage = "An error occurred while loading events."
            return
        }
        
        if ProcessInfo.processInfo.arguments.contains("-UITestEventRowMockData") {
            isLoading = false
            events = [
                Event(id: UUID().uuidString, title: "Valid Event", description: "Desc", date: Date(), address: "123", creatorId: "creator_valid", coverImageUrl: "https://via.placeholder.com/150"),
                Event(id: UUID().uuidString, title: "Invalid Image Event", description: "Desc", date: Date(), address: "123", creatorId: "creator_invalid", coverImageUrl: "invalid_url"),
                Event(id: UUID().uuidString, title: "No Image Event", description: "Desc", date: Date(), address: "123", creatorId: "creator_none", coverImageUrl: nil)
            ]
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-UITestEmptyStateMockData") {
            isLoading = false
            events = []
            return
        }
        #endif
        
        isLoading = true
        errorMessage = nil
        
        listenerRegistration?.remove()
        
        listenerRegistration = eventRepository.fetchEvents(searchQuery: searchQuery, sortOption: sortOption) { [weak self] fetchedEvents, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Erreur de chargement : \(error.localizedDescription)"
                return
            }
            
            if let fetchedEvents = fetchedEvents {
                self.events = fetchedEvents
            } else {
                self.events = []
            }
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func addMockData() {
        let sampleEvents = [
            Event(title: "Music festival", description: "A great music festival.", date: Date().addingTimeInterval(86400 * 10), address: "123 Music Ave", creatorId: "mockId", coverImageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&q=80&w=400"),
            Event(title: "Art exhibition", description: "Modern art exhibition.", date: Date().addingTimeInterval(86400 * 40), address: "456 Art St", creatorId: "mockId", coverImageUrl: "https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?auto=format&fit=crop&q=80&w=400"),
            Event(title: "Tech conference", description: "Latest in tech.", date: Date().addingTimeInterval(86400 * 60), address: "789 Tech Blvd", creatorId: "mockId", coverImageUrl: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&q=80&w=400"),
            Event(title: "Food fair", description: "Delicious food from around the world.", date: Date().addingTimeInterval(86400 * 80), address: "101 Food St", creatorId: "mockId", coverImageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&q=80&w=400")
        ]
        
        for event in sampleEvents {
            eventRepository.addEvent(event) { error in
                if let error = error {
                    print("Error adding mock event: \(error)")
                }
            }
        }
    }
}
