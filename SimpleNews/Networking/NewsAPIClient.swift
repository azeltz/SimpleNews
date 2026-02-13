//
//  NewsAPIClient.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import Foundation

struct NewsdataResponse: Codable {
    let results: [NewsdataArticle]
}

struct NewsdataArticle: Codable {
    let title: String?
    let description: String?
    let content: String?
    let image_url: String?
    let category: [String]?
    let source_id: String?
    let pubDate: String?
    let link: String?

    func toArticle() -> Article {
        Article(
            id: UUID().uuidString,
            title: title ?? "Untitled",
            description: description,
            content: content,
            imageURL: URL(string: image_url ?? ""),
            source: source_id,
            category: category?.first,
            publishedAt: nil, // parse if you want
            url: URL(string: link ?? ""),
            isSaved: false,
            liked: nil
        )
    }
}

final class NewsAPIClient {
    private let apiKey = "<YOUR_NEWSDATA_API_KEY>"
    private let baseURL = URL(string: "https://newsdata.io/api/1/news")!

    func fetchArticles() async throws -> [Article] {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "country", value: "us"),
            URLQueryItem(name: "language", value: "en")
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let decoded = try JSONDecoder().decode(NewsdataResponse.self, from: data)
        return decoded.results.map { $0.toArticle() }
    }
}
