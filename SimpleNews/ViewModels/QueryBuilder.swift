//
//  QueryBuilder.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

extension NewsViewModel {
    func queryParams() -> [String: String] {
        var params: [String: String] = [:]

        // language from Settings
        params["language"] = settings.language.rawValue

        // top N positive tags by weight
        let positiveTags = tagWeights
            .filter { $0.value > 0.5 }   // only strong likes
            .sorted(by: { $0.value > $1.value })
            .map { $0.key }

        let categoryTags = positiveTags.filter { knownCategories.contains($0.lowercased()) }
        let keywordTags  = positiveTags.filter { !knownCategories.contains($0.lowercased()) }

        if !categoryTags.isEmpty {
            // up to 5 categories, comma separated
            let cats = categoryTags.prefix(5).joined(separator: ",")
            params["category"] = cats
        }

        if !keywordTags.isEmpty {
            // join into a single q query string
            // e.g. "swiftui OR iphone OR ai"
            let q = keywordTags.joined(separator: " OR ")
            params["q"] = q
            //params["qInTitle"] = q
        }

        // remove duplicate articles
        params["removeduplicate"] = "1"

        return params
    }
}
