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
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func fetchEvents() {
        isLoading = true
        errorMessage = nil
        
        listener?.remove()
        
        var query: Query = db.collection("events")
        
        // Firestore requires composite indexes for complex queries.
        // For simplicity, we use only one orderBy if there is no range filter.
        // However, a range filter on titleLower requires the first orderBy to be titleLower.
        
        let isSearching = !searchQuery.isEmpty
        
        if isSearching {
            let lowerQuery = searchQuery.lowercased()
            query = query.whereField("searchTokens", arrayContains: lowerQuery)
        } else {
            // Sorting is only applied in Firestore when not searching
            // to avoid complex composite index requirements.
            switch sortOption {
            case .dateAsc:
                query = query.order(by: "date", descending: false)
            case .dateDesc:
                query = query.order(by: "date", descending: true)
            case .titleAsc:
                query = query.order(by: "titleLower", descending: false)
            }
        }
        
        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Erreur de chargement : \(error.localizedDescription)"
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.events = []
                return
            }
            
            var fetchedEvents = documents.compactMap { doc -> Event? in
                try? doc.data(as: Event.self)
            }
            
            if isSearching {
                switch self.sortOption {
                case .dateAsc:
                    fetchedEvents.sort { $0.date < $1.date }
                case .dateDesc:
                    fetchedEvents.sort { $0.date > $1.date }
                case .titleAsc:
                    fetchedEvents.sort { ($0.titleLower ?? "") < ($1.titleLower ?? "") }
                }
            }
            
            self.events = fetchedEvents
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    func addMockData() {
        let sampleEvents = [
            Event(title: "Music festival", description: "A great music festival.", date: Date().addingTimeInterval(86400 * 10), address: "123 Music Ave", creatorId: "mockId", coverImageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&q=80&w=400"),
            Event(title: "Art exhibition", description: "Modern art exhibition.", date: Date().addingTimeInterval(86400 * 40), address: "456 Art St", creatorId: "mockId", coverImageUrl: "https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?auto=format&fit=crop&q=80&w=400"),
            Event(title: "Tech conference", description: "Latest in tech.", date: Date().addingTimeInterval(86400 * 60), address: "789 Tech Blvd", creatorId: "mockId", coverImageUrl: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&q=80&w=400"),
            Event(title: "Food fair", description: "Delicious food from around the world.", date: Date().addingTimeInterval(86400 * 80), address: "101 Food St", creatorId: "mockId", coverImageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&q=80&w=400")
        ]
        
        for event in sampleEvents {
            do {
                _ = try db.collection("events").addDocument(from: event)
            } catch {
                print("Error adding mock event: \(error)")
            }
        }
    }
}
