//
//  NewsViewModel.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import Foundation

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let client = NewsAPIClient()
    private var lastFetchDate: Date? = nil

    func loadInitial() async {
        // Simple: always fetch on first load
        if articles.isEmpty {
            await refreshIfAllowed(ignoreCooldown: true)
        }
    }

    func refreshIfAllowed(ignoreCooldown: Bool = false) async {
        if let last = lastFetchDate, !ignoreCooldown {
            let diff = Date().timeIntervalSince(last)
            if diff < 10 * 60 {
                return
            }
        }

        await fetchArticles()
    }

    func fetchArticles() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await client.fetchArticles()
            // For now, no sorting or recommendation; just show latest
            self.articles = fetched
            self.lastFetchDate = Date()
        } catch {
            self.errorMessage = "Failed to load news: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // For later swipe/save logic, stubs:
    func like(_ article: Article) {}
    func dislike(_ article: Article) {}
    func toggleSaved(_ article: Article) {}
}
