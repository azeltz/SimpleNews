//
// HomeView.swift
// SimpleNews
//
// Created by Amir Zeltzer on 2/13/26.
//

import SwiftUI

struct SafariItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct HomeView: View {
    @ObservedObject var viewModel: NewsViewModel

    @State private var expandedArticleID: String? = nil
    @State private var selectedArticle: Article? = nil
    @State private var safariItem: SafariItem? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.articles.isEmpty {
                    ProgressView("Loading news...")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.refreshIfAllowed(ignoreCooldown: true) }
                        }
                    }
                } else {
                    List(viewModel.articles) { article in
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
                            onOpenLink: {                     // NEW
                                if let url = article.url {
                                    safariItem = SafariItem(url: url)
                                }
                            }
                        )
                        .contentShape(Rectangle()) // make whole row tappable
                        .onTapGesture {
                            if expandedArticleID == article.id {
                                expandedArticleID = nil
                            } else {
                                expandedArticleID = article.id
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.dislike(article)
                            } label: {
                                Label("Less like this", systemImage: "hand.thumbsdown")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.like(article)
                            } label: {
                                Label("More like this", systemImage: "hand.thumbsup")
                            }
                        }
                    }
                }
            }
            .animation(.easeInOut, value: expandedArticleID)
            .sheet(item: $selectedArticle) { article in
                NavigationStack {
                    ArticleDetailView(
                        article: article,
                        showImages: viewModel.settings.showImages,
                        onToggleSaved: {
                            viewModel.toggleSaved(article)
                        }
                    )
                }
            }
            .fullScreenCover(item: $safariItem) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
            .navigationTitle("News")
            .task {
                await viewModel.loadInitial()
            }
            .refreshable {
                await viewModel.refreshIfAllowed()
            }
        }
    }
}
