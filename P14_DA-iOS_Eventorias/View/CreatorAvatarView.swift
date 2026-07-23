//
//  CreatorAvatarView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI

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
                    .foregroundStyle(.white)
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
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return }
            LocalImageCache.shared.setImage(image, for: urlString)
            self.uiImage = image
        }
    }
}
