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
                    
                    Text(event.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text(event.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            
            // Right content: Cover Image
            if let imageUrl = event.coverImageUrl, let url = URL(string: imageUrl) {
                if let cachedImage = LocalImageCache.shared.getImage(for: imageUrl) {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120)
                        .clipped()
                } else {
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
                }
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
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if avatarUrl != nil {
                placeholder.overlay(ProgressView())
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: creatorId) { loadAvatarIfNeeded() }
        .onReceive(NotificationCenter.default.publisher(for: .avatarDidChange)) { notification in
            guard let uid = notification.userInfo?["uid"] as? String, uid == creatorId else { return }
            if let newUrl = notification.userInfo?["avatarUrl"] as? String {
                avatarUrl = newUrl
                loadImage(from: newUrl)
            } else {
                hasLoaded = false
                loadAvatarIfNeeded()
            }
        }
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
            if let newUrl = profile?.avatarUrl {
                self.avatarUrl = newUrl
                self.loadImage(from: newUrl)
            }
        }
    }

    private func loadImage(from urlString: String) {
        if let cached = LocalImageCache.shared.getImage(for: urlString) {
            self.uiImage = cached
            return
        }
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                LocalImageCache.shared.setImage(image, for: urlString)
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
        }.resume()
    }
}

#Preview {
    EventRowView(event: Event(title: "Music festival", description: "Awesome music", date: Date(), address: "123 Street", creatorId: "user1", coverImageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&q=80&w=400"))
        .padding()
        .background(Color.black)
}

final class LocalImageCache {
    static let shared = LocalImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    func setImage(_ image: UIImage, for urlString: String) {
        cache.setObject(image, forKey: urlString as NSString)
    }
    
    func getImage(for urlString: String) -> UIImage? {
        return cache.object(forKey: urlString as NSString)
    }
}
