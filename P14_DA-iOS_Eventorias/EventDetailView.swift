//
//  EventDetailView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    
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
                    if let imageUrl = event.coverImageUrl, let url = URL(string: imageUrl) {
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
                        
                        // Avatar (Placeholder)
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            )
                    }
                    .padding(.top, 8)
                    
                    // Description
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                        .padding(.top, 8)
                    
                    // Adresse & Carte statique
                    HStack(alignment: .top, spacing: 16) {
                        Text(event.address)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
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
                }
                .padding()
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
