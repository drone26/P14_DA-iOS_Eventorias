//
//  EventDetailView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI

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
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Image Principale
                    if let imageUrl = event.coverImageUrl, let url = URL(string: imageUrl) {
                        if let cachedImage = LocalImageCache.shared.getImage(for: imageUrl) {
                            Image(uiImage: cachedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .clipped()
                                .clipShape(.rect(cornerRadius: 12))
                                .shadow(radius: 5)
                        } else {
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
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .aspectRatio(1, contentMode: .fill)
                                        .overlay(Image(systemName: "photo").foregroundStyle(.gray))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipped()
                            .clipShape(.rect(cornerRadius: 12))
                            .shadow(radius: 5)
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(.rect(cornerRadius: 16))
                            .overlay(Image(systemName: "photo").foregroundStyle(.gray))
                    }

                    // Informations (Date, Heure, Avatar)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                Text(event.date, style: .date)
                            } icon: {
                                Image(systemName: "calendar")
                                    .frame(width: 20)
                            }
                            Label {
                                Text(event.date, style: .time)
                            } icon: {
                                Image(systemName: "clock")
                                    .frame(width: 20)
                            }
                        }
                        .font(.title3)
                        .foregroundStyle(.white)

                        Spacer()

                        // Creator avatar
                        CreatorAvatarView(creatorId: event.creatorId, size: 60)
                    }
                    .padding(.top, 8)

                    // Description
                    Text(event.description)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(4)
                        .padding(.top, 8)
                        .accessibilityIdentifier("event_detail_description")

                    // Adresse & Carte statique
                    HStack(alignment: .top, spacing: 16) {
                        Text(event.address)
                            .font(.subheadline)
                            .foregroundStyle(.white)
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
                                        .overlay(Text("Map Error").font(.caption).foregroundStyle(.gray))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 140, height: 80)
                            .clipShape(.rect(cornerRadius: 12))
                            .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 140, height: 80)
                                .clipShape(.rect(cornerRadius: 12))
                        }
                    }
                    .padding(.top, 16)
                    
                    // Delete event (owner only)
                    if isOwner {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
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
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accent)
                            .clipShape(.rect(cornerRadius: 8))
                        }
                        .disabled(viewModel.isDeleting)
                        .accessibilityIdentifier("delete_event_button")
                        .padding(.top, viewModel.errorMessage == nil ? 24 : 8)
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
                .padding()
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

