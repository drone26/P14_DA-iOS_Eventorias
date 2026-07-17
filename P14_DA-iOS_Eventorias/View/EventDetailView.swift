//
//  EventDetailView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI
import Observation

struct EventDetailView: View {
    let event: Event
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = EventDetailViewModel()
    @State private var showDeleteConfirmation = false
    
    /// Only the user who created the event may delete it.
    private var isOwner: Bool {
        guard let uid = authManager.currentUser?.uid else { return false }
        return event.creatorId == uid
    }
    
    private var staticMapUrl: URL? {
        guard let encodedAddress = event.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        let urlString = "https://maps.googleapis.com/maps/api/staticmap?center=\(encodedAddress)&zoom=15&size=400x200&markers=color:red%7C\(encodedAddress)&key=\(Secrets.googleMapsApiKey)"
        return URL(string: urlString)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.14).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Image Principale
                    if let imageUrl = event.coverImageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(1, contentMode: .fill) // Carré approximatif
                                    .overlay(ProgressView())
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .cornerRadius(16)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(16)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    }
                    
                    // Informations (Date, Heure, Avatar)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "calendar")
                                    .frame(width: 20)
                                Text(event.date, style: .date)
                            }
                            HStack {
                                Image(systemName: "clock")
                                    .frame(width: 20)
                                Text(event.date, style: .time)
                            }
                        }
                        .font(.title3)
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Creator avatar
                        CreatorAvatarView(creatorId: event.creatorId, size: 60)
                    }
                    .padding(.top, 8)
                    
                    // Description
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                        .padding(.top, 8)
                        .accessibilityIdentifier("event_detail_description")
                    
                    // Adresse & Carte statique
                    HStack(alignment: .top, spacing: 16) {
                        Text(event.address)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("event_detail_address")
                        
                        if let mapUrl = staticMapUrl {
                            AsyncImage(url: mapUrl) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(ProgressView())
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(Text("Map Error").font(.caption).foregroundColor(.gray))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 140, height: 80)
                            .cornerRadius(12)
                            .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 140, height: 80)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Delete event (owner only)
                    if isOwner {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 24)
                        }
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                if viewModel.isDeleting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "trash")
                                    Text("Delete event")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.85, green: 0.1, blue: 0.15))
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.isDeleting)
                        .accessibilityIdentifier("delete_event_button")
                        .padding(.top, viewModel.errorMessage == nil ? 24 : 8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this event?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Delete event", role: .destructive) {
                viewModel.deleteEvent(event) { success in
                    if success { dismiss() }
                }
            }
            .accessibilityIdentifier("confirm_delete_event_button")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
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

