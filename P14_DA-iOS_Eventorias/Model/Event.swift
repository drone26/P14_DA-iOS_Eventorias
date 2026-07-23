//
//  Event.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var date: Date
    var address: String
    var creatorId: String
    var coverImageUrl: String?
    var attachmentsUrls: [String]?
    @ServerTimestamp var createdAt: Date?
    
    var titleLower: String?
    var searchTokens: [String]?
    
    init(id: String? = nil, title: String, description: String, date: Date, address: String, creatorId: String, coverImageUrl: String? = nil, attachmentsUrls: [String]? = nil, createdAt: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.address = address
        self.creatorId = creatorId
        self.coverImageUrl = coverImageUrl
        self.attachmentsUrls = attachmentsUrls
        self.createdAt = createdAt
        self.titleLower = title.lowercased()
        self.searchTokens = Event.generateSearchTokens(for: title)
    }
    
    static func generateSearchTokens(for text: String) -> [String] {
        var tokens = Set<String>()
        let lowerText = text.lowercased()
        let chars = Array(lowerText)
        let length = chars.count

        for i in 0..<length {
            var token = ""
            for j in i..<length {
                token.append(chars[j])
                if token.count <= 30 {
                    tokens.insert(token)
                }
            }
        }
        return Array(tokens)
    }
}

extension Event: Hashable {
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
