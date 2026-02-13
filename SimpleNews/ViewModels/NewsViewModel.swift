//
// NewsViewModel.swift
// SimpleNews
//
// Created by Amir Zeltzer on 2/13/26.
//

import Foundation

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var tagWeights: [String: Double] = TagWeightsStorage.load()
    @Published var settings: AppSettings = AppSettings.load()

    // Persistent saved articles (independent of current feed)
    @Published private(set) var savedArticles: [SavedArticle] = {
        let loaded = SavedArticlesStorage.load()
        return loaded.sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
    }()
    private let client = NewsAPIClient()
    private var lastFetchDate: Date? = nil

    // MARK: - Saved Articles Storage

    private func sortSavedArticles() {
        savedArticles.sort { a, b in
            switch (a.publishedAt, b.publishedAt) {
            case let (da?, db?):
                return da > db            // newer first
            case (nil, nil):
                return a.title < b.title  // fallback stable order
            case (nil, _?):
                return false              // items with date go first
            case (_?, nil):
                return true
            }
        }
    }

    
    // MARK: - Lifecycle

    func loadInitial() async {
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

    // MARK: - Fetching

    func fetchArticles() async {
        isLoading = true
        errorMessage = nil
        do {
            let params = QueryBuilder.queryParams(settings: settings, tagWeights: tagWeights)
            let fetched = try await client.fetchArticles(params: params)

            // Build a set of saved URLs to mark live articles
            let savedURLStrings = Set(
                savedArticles.compactMap { $0.url?.absoluteString }
            )

            // Apply saved flags based on URL match
            let withSavedFlags = fetched.map { article -> Article in
                var copy = article
                if let urlString = article.url?.absoluteString,
                   savedURLStrings.contains(urlString) {
                    copy.isSaved = true
                }
                return copy
            }

            // De-duplicate by URL
            var seen = Set<URL>()
            let deduped = withSavedFlags.filter { article in
                guard let url = article.url else { return true }
                if seen.contains(url) {
                    return false
                } else {
                    seen.insert(url)
                    return true
                }
            }

            // Score and sort by tagWeights (simple relevance)
            let preferred = Set(settings.preferredSources.map { $0.lowercased() })
            let scored = deduped
                .map { article -> (Article, Double) in
                    let tag = article.category?.lowercased() ?? ""
                    var score = tagWeights[tag, default: 0]
                    if let host = article.url?.host?.lowercased(),
                       preferred.contains(host) {
                        score += 2.0 // boost preferred domains
                    }
                    return (article, score)
                }
                .sorted { $0.1 > $1.1 }
                .map { $0.0 }

            self.articles = scored
            self.lastFetchDate = Date()
        } catch {
            self.errorMessage = "Failed to load news: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Saved

    func toggleSaved(_ article: Article) {
        // Update live feed flag
        if let index = articles.firstIndex(of: article) {
            articles[index].isSaved.toggle()
        }

        guard let url = article.url else {
            return
        }

        let urlString = url.absoluteString

        // Check if already saved (by URL)
        if let existingIndex = savedArticles.firstIndex(where: { $0.url?.absoluteString == urlString }) {
            // Remove from saved
            savedArticles.remove(at: existingIndex)
        } else {
            // Add to saved
            let saved = SavedArticle(from: article)
            savedArticles.append(saved)
        }

        sortSavedArticles()
        SavedArticlesStorage.save(savedArticles)
    }

    // MARK: - Like / Dislike

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
