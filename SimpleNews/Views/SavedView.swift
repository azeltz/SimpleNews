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
                        isExpanded: expandedArticleID == article.id,
                        onToggleSaved: {
                            viewModel.toggleSaved(article)
                        },
                        onOpenDetail: {
                            selectedArticle = article
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
            }
        }
    }
}
