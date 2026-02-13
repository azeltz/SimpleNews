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

            // Apply saved flags from IDs
            let withSavedFlags = fetched.map { article -> Article in
                var copy = article
                if savedArticleIDs.contains(article.id) {
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
                        score += 2.0   // boost preferred domains
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

    // MARK: - Query params

    func queryParams() -> [String: String] {
        var params: [String: String] = [:]

        // Languages (up to 5)
        if !settings.languages.isEmpty {
            let codes = settings.languages.map { $0.rawValue }.prefix(5)
            params["language"] = codes.joined(separator: ",")
        }

        // Countries (up to 5)
        if !settings.countries.isEmpty {
            let codes = settings.countries.map { $0.rawValue }.prefix(5)
            params["country"] = codes.joined(separator: ",")
        }

        // Sort: relevancy by default
        params["sort"] = "relevancy"

        // Interests → category + qInTitle
        let positiveTags = tagWeights
            .filter { $0.value > 0.5 }
            .sorted(by: { $0.value > $1.value })
            .map { $0.key }

        let categoryTags = positiveTags.filter { knownCategories.contains($0.lowercased()) }
        let keywordTags  = positiveTags.filter { !knownCategories.contains($0.lowercased()) }

        if !categoryTags.isEmpty {
            params["category"] = categoryTags.prefix(5).joined(separator: ",")
        }

        if !keywordTags.isEmpty {
            let q = keywordTags.prefix(5).joined(separator: " OR ")
            params["qInTitle"] = q   // keep it short/strong
        }

        // Remove duplicates on API side
        params["removeduplicate"] = "1"

        // Quality mode: restrict to top outlets
        if settings.qualityMode {
            let coreDomains = [
                "bbc.com",
                "nytimes.com",
                "reuters.com",
                "apnews.com",
                "cnn.com"
            ]
            params["prioritydomain"] = "top"
            params["domain"] = coreDomains.joined(separator: ",")
        }

        return params
    }

    // MARK: - Saved

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
