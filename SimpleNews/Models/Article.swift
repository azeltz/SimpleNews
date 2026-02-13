//
//  Article.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import Foundation

struct Article: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let content: String?
    let imageURL: URL?
    let source: String?
    let category: String?
    let publishedAt: Date?
    let url: URL?
    var isSaved: Bool
    var liked: Bool?
    var aiTags: [String]
}


extension Article {
    var tags: [String] {
        var result: [String] = []

        if let category = category?.capitalized, !category.isEmpty {
            result.append(category)
        }

        // Append up to 4 AI tags to avoid clutter
        let extra = aiTags.prefix(4).map { $0 }
        result.append(contentsOf: extra)

        return result
    }
}
