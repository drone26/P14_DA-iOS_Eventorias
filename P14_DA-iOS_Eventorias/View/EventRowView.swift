//
//  EventRowView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 0) {
            // Left content: Avatar, Title, Date
            HStack(spacing: 16) {
                // Creator avatar
                CreatorAvatarView(creatorId: event.creatorId, size: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(event.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            
            // Right content: Cover Image
            if let imageUrl = event.coverImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.3)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.gray.opacity(0.3)
                            .overlay(Image(systemName: "exclamationmark.triangle").foregroundColor(.red))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 120)
                .clipped()
            } else {
                Color.gray.opacity(0.3)
                    .frame(width: 120)
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
            }
        }
        .frame(height: 80)
        .background(Color(white: 0.2))
        .cornerRadius(12)
    }
}

/// Circular avatar for an event's creator, loaded from the creator's user profile.
/// Falls back to a person placeholder while loading or when no avatar is set.
struct CreatorAvatarView: View {
    let creatorId: String
    var size: CGFloat = 40

    @State private var avatarUrl: String?
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if let avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        placeholder.overlay(ProgressView())
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear { loadAvatarIfNeeded() }
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.5))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white)
            )
    }

    private func loadAvatarIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        // Firebase isn't configured in SwiftUI previews; avoid touching it there.
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestMockAvatarValid") {
            avatarUrl = "https://via.placeholder.com/150"
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-UITestMockAvatarInvalid") {
            avatarUrl = "invalid_url"
            return
        }
        #endif

        FirebaseUserRepository().getProfile(uid: creatorId) { profile, _ in
            avatarUrl = profile?.avatarUrl
        }
    }
}

#Preview {
    EventRowView(event: Event(title: "Music festival", description: "Awesome music", date: Date(), address: "123 Street", creatorId: "user1", coverImageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&q=80&w=400"))
        .padding()
        .background(Color.black)
}
