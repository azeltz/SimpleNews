//
//  HomeView.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: NewsViewModel
    @State private var expandedArticleID: String? = nil
    @State private var selectedArticle: Article? = nil

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
                            isExpanded: expandedArticleID == article.id,
                            onToggleSaved: {
                                viewModel.toggleSaved(article)
                            },
                            onOpenDetail: {
                                selectedArticle = article
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
                }
            }
            .navigationTitle("News")
            /*.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView(viewModel: viewModel)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }*/
            .task {
                await viewModel.loadInitial()
            }
            .refreshable {
                await viewModel.refreshIfAllowed()
            }
        }
    }
}
