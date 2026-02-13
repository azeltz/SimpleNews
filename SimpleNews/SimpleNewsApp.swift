//
//  SimpleNewsApp.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/1/25.
//

import SwiftUI
import SwiftData

@main
struct YourAppNameApp: App {
    @StateObject private var newsViewModel = NewsViewModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView(viewModel: newsViewModel)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                SavedView(viewModel: newsViewModel)
                    .tabItem {
                        Label("Saved", systemImage: "bookmark")
                    }

                NavigationStack {
                    SettingsView(viewModel: newsViewModel)
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}
