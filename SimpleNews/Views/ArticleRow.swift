//
//  ArticleRow.swift
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


struct ArticleRow: View {
    let article: Article
    let showImages: Bool
    let isExpanded: Bool
    let onToggleSaved: () -> Void
    let onOpenDetail: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                            Text(article.title)
                                .font(.headline)
                                .lineLimit(3)

                            if let description = article.description {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(isExpanded ? nil : 2)
                            }

                            if let publishedAt = article.publishedAt {
                                Text(articleDateFormatter.string(from: publishedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(spacing: 8) {
                            Button(action: onToggleSaved) {
                                Image(systemName: article.isSaved ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(article.isSaved ? .blue : .secondary)
                            }
                            .buttonStyle(.borderless)

                            Button(action: onOpenDetail) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
