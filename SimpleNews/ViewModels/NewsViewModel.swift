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
    @Published var tagWeights: [String: Double] = TagWeightsStorage.load()
    @Published var settings: AppSettings = AppSettings.load()
    
    private var savedArticleIDs: Set<String> = SavedArticlesStorage.load()

    private let client = NewsAPIClient()
    private var lastFetchDate: Date? = nil

    var savedArticles: [Article] {
        articles.filter { $0.isSaved }
    }
    
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
            let params = queryParams()
            let fetched = try await client.fetchArticles(params: params)

            let scored = fetched.map { article -> (Article, Double) in
                let tag = article.category?.lowercased() ?? ""
                let score = tagWeights[tag, default: 0]
                return (article, score)
            }
            .sorted { $0.1 > $1.1 }   // highest score first
            .map { $0.0 }

            self.articles = scored
            
            // Apply saved state from IDs
            _ = fetched.map { article -> Article in
                var copy = article
                if savedArticleIDs.contains(article.id) {
                    copy.isSaved = true
                }
                return copy
            }
            
            var seen = Set<URL>()
            _ = fetched.filter { article in
                guard let url = article.url else { return true }
                if seen.contains(url) {
                    return false
                } else {
                    seen.insert(url)
                    return true
                }
            }
            
            self.articles = fetched
            self.lastFetchDate = Date()
        } catch {
            self.errorMessage = "Failed to load news: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func toggleSaved(_ article: Article) {
        guard let index = articles.firstIndex(of: article) else { return }

        articles[index].isSaved.toggle()

        if articles[index].isSaved {
            savedArticleIDs.insert(article.id)
        } else {
            savedArticleIDs.remove(article.id)
        }

        SavedArticlesStorage.save(savedArticleIDs)
    }


    func like(_ article: Article) {
            if let index = articles.firstIndex(of: article) {
                articles[index].liked = true
            }
            updateTagWeights(for: article, delta: 1.0)
        }

        func dislike(_ article: Article) {
            if let index = articles.firstIndex(of: article) {
                articles[index].liked = false
            }
            updateTagWeights(for: article, delta: -1.0)
        }

        private func updateTagWeights(for article: Article, delta: Double) {
            guard let tag = article.category else { return }
            tagWeights[tag, default: 0] += delta
            TagWeightsStorage.save(tagWeights)
        }

        // MARK: - Editing tags from Settings

        func removeTag(_ tag: String) {
            tagWeights.removeValue(forKey: tag)
            TagWeightsStorage.save(tagWeights)
        }

        func setWeight(_ weight: Double, for tag: String) {
            tagWeights[tag] = weight
            TagWeightsStorage.save(tagWeights)
        }

        func addTag(_ tag: String) {
            guard !tag.isEmpty else { return }
            if tagWeights[tag] == nil {
                tagWeights[tag] = 1.0
            }
            TagWeightsStorage.save(tagWeights)
        }
}
