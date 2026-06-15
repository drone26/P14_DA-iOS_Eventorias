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
                // Avatar placeholder
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
                
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
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.gray.opacity(0.3)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
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

#Preview {
    EventRowView(event: Event(title: "Music festival", description: "Awesome music", date: Date(), address: "123 Street", creatorId: "user1", coverImageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&q=80&w=400"))
        .padding()
        .background(Color.black)
}
