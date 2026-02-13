//
//  HomeView.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: NewsViewModel

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
                        ArticleRow(article: article)
                    }
                }
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
