//
//  SavedView.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import SwiftUI

struct SavedView: View {
    @ObservedObject var viewModel: NewsViewModel
    @State private var expandedArticleID: String? = nil
    @State private var selectedArticle: Article? = nil
    @State private var safariItem: SafariItem? = nil

    var body: some View {
        NavigationStack {
            if viewModel.savedArticles.isEmpty {
                Text("No saved articles yet.")
                    .foregroundColor(.secondary)
                    .padding()
                    .navigationTitle("Saved")
            } else {
                List(viewModel.savedArticles) { article in
                    ArticleRow(
                        article: article,
                        showImages: viewModel.settings.showImages,
                        showDescription: viewModel.settings.showDescriptions,
                        isExpanded: expandedArticleID == article.id,
                        onToggleSaved: {
                            viewModel.toggleSaved(article)
                        },
                        onOpenDetail: {
                            selectedArticle = article
                        },
                        onOpenLink: {
                                if let url = article.url {
                                    safariItem = SafariItem(url: url)
                                }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if expandedArticleID == article.id {
                            expandedArticleID = nil
                        } else {
                            expandedArticleID = article.id
                        }
                    }
                }
                .navigationTitle("Saved")
                .fullScreenCover(item: $safariItem) { item in
                    SafariView(url: item.url)
                        .ignoresSafeArea()
                }
            }
        }
    }
}
