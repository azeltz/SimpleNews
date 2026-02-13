//
//  ArticleDetailView.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import SwiftUI

fileprivate let articleDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f
}()

struct ArticleDetailView: View {
    let article: Article
    let showImages: Bool
    let onToggleSaved: () -> Void
    
    // Helper to decide what text to show
    private func bodyText(for article: Article) -> String? {
        // If content exists but is just the paid-plan placeholder, treat as nil
        if let content = article.content,
           !content.isEmpty,
           content != "ONLY AVAILABLE IN PAID PLANS" {
            return content
        }

        if let description = article.description, !description.isEmpty {
            return description
        }

        return nil
    }


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if showImages, let url = article.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.1)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Color.gray.opacity(0.1)
                        @unknown default:
                            Color.gray.opacity(0.1)
                        }
                    }
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(12)
                }

                Text(article.title)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.leading)

                if let publishedAt = article.publishedAt {
                    Text(articleDateFormatter.string(from: publishedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let source = article.source {
                    Text(source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                if let text = bodyText(for: article) {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("No content available.")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        //.navigationTitle("Article")
        .navigationTitle(article.source ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: onToggleSaved) {
                    Image(systemName: article.isSaved ? "bookmark.fill" : "bookmark")
                }
            }
        }
    }
}
