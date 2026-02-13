//
//  Article.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import Foundation

struct Article: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String?
    let content: String?
    let imageURL: URL?
    let source: String?
    let category: String?
    let publishedAt: Date?
    let url: URL?

    var isSaved: Bool = false
    var liked: Bool? = nil
}
