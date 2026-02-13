//
//  SettingsView.swift
//  SimpleNews
//
//  Created by Amir Zeltzer on 2/13/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: NewsViewModel

    @State private var draftSettings: AppSettings = AppSettings.load()

    @State private var newTagText: String = ""

    private var addTagRow: some View {
        HStack {
            TextField("Add topic (e.g. technology)", text: $newTagText)
            Button("Add") {
                let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                viewModel.addTag(trimmed)
                newTagText = ""
            }
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        let sortedKeys = viewModel.tagWeights
            .sorted(by: { $0.value > $1.value })
            .map { $0.key }
        for index in offsets {
            let tag = sortedKeys[index]
            viewModel.removeTag(tag)
        }
    }
    
    var body: some View {
        Form {
            Section("Language") {
                Picker("News language", selection: $draftSettings.language) {
                    ForEach(NewsLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            }

            Section("Display") {
                Toggle("Show images in list", isOn: $draftSettings.showImages)
            }
            
            Section("Your interests") {
                if viewModel.tagWeights.isEmpty {
                    Text("No preferences yet. Swipe on articles to like or dislike them.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    // Sorted by weight descending
                    ForEach(viewModel.tagWeights.sorted(by: { $0.value > $1.value }), id: \.key) { tag, weight in
                        HStack {
                            Text(tag)
                            Spacer()
                            // Simple editable weight with a Stepper
                            Stepper(value: Binding(
                                get: { Int(weight) },
                                set: { newValue in
                                    viewModel.setWeight(Double(newValue), for: tag)
                                }
                            ), in: -10...10) {
                                Text(String(format: "%.0f", weight))
                                    .monospacedDigit()
                            }
                            .frame(width: 120)
                        }
                    }
                    .onDelete(perform: deleteTags)
                }

                addTagRow
            }

        }
        .navigationTitle("Settings")
        .onAppear {
            draftSettings = viewModel.settings
        }
        .onDisappear {
            applyChanges()
        }
    }

    private func applyChanges() {
        viewModel.settings = draftSettings
        viewModel.settings.save()
        Task {
            await viewModel.refreshIfAllowed(ignoreCooldown: true)
        }
    }
}
