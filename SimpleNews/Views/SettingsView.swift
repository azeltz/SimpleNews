//
// SettingsView.swift
// SimpleNews
//
// Created by Amir Zeltzer on 2/13/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: NewsViewModel
    @State private var draftSettings: AppSettings = AppSettings.load()
    @State private var newTagText: String = ""
    @State private var newSourceDomain: String = ""

    var body: some View {
        Form {
            displaySection
            languageAndCountrySection
            sourceQualitySection
            interestsSection
        }
        .navigationTitle("Settings")
        .onAppear {
            draftSettings = viewModel.settings
        }
        .onDisappear {
            applyChanges()
        }
    }

    // MARK: - Stuff to show on the app
    
    private var displaySection: some View {
        Section("Display") {
            Toggle("Include Newsdata articles", isOn: $draftSettings.enableNewsdata)
            Toggle("Include RSS articles", isOn: $draftSettings.enableRSS)
            Toggle("Show images in list", isOn: $draftSettings.showImages)
            Toggle("Show descriptions in list", isOn: $draftSettings.showDescriptions)
            Toggle("Ask before removing saved articles", isOn: $draftSettings.confirmUnsaveInSavedTab) // NEW
        }
    }
    
    // MARK: - Combined languages + countries

    private var languageAndCountrySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Languages (max 5)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(NewsLanguage.allCases) { lang in
                    let isOn = draftSettings.languages.contains(lang)
                    Toggle(isOn: Binding(
                        get: { isOn },
                        set: { newValue in
                            if newValue {
                                if !draftSettings.languages.contains(lang),
                                   draftSettings.languages.count < 5 {
                                    draftSettings.languages.append(lang)
                                }
                            } else {
                                draftSettings.languages.removeAll { $0 == lang }
                            }
                        })
                    ) {
                        Text(lang.displayName)
                    }
                }

                Divider()

                Text("Countries (max 5)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(NewsCountry.allCases) { country in
                    let isOn = draftSettings.countries.contains(country)
                    Toggle(isOn: Binding(
                        get: { isOn },
                        set: { newValue in
                            if newValue {
                                if !draftSettings.countries.contains(country),
                                   draftSettings.countries.count < 5 {
                                    draftSettings.countries.append(country)
                                }
                            } else {
                                draftSettings.countries.removeAll { $0 == country }
                            }
                        })
                    ) {
                        Text(country.displayName)
                    }
                }
            }
        } header: {
            Text("Regions & languages")
        }
    }

    // MARK: - Source quality + preferred sources

    private var sourceQualitySection: some View {
        Section("Source quality & preference") {
            Toggle("Quality mode (use only preferred / top sources)", isOn: $draftSettings.qualityMode)

            Text("When on, results are limited to your preferred domains if set, or a small set of top outlets, with less variety but higher consistency.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if draftSettings.preferredSources.isEmpty {
                Text("Preferred domains (optional): add sources like nytimes.com, apnews.com, haaretz.com. In quality mode, only these will be used if set.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(draftSettings.preferredSources, id: \.self) { domain in
                    Text(domain)
                        .swipeActions {
                            Button(role: .destructive) {
                                draftSettings.preferredSources.removeAll { $0 == domain }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }

            HStack {
                TextField("Add domain (e.g. reuters.com)", text: $newSourceDomain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Button("Add") {
                    let trimmed = newSourceDomain
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    guard !trimmed.isEmpty else { return }
                    if !draftSettings.preferredSources.contains(trimmed) {
                        draftSettings.preferredSources.append(trimmed)
                    }
                    newSourceDomain = ""
                }
            }
        }
    }

    // MARK: - Interests

    private var interestsSection: some View {
        Section("Your interests") {
            if viewModel.tagWeights.isEmpty {
                Text("No preferences yet. Swipe on articles to like or dislike them.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                ForEach(
                    viewModel.tagWeights
                        .sorted(by: { $0.value > $1.value }),
                    id: \.key
                ) { tag, weight in
                    HStack {
                        Text(tag)
                        Spacer()
                        Stepper(
                            value: Binding(
                                get: { Int(weight) },
                                set: { newValue in
                                    viewModel.setWeight(Double(newValue), for: tag)
                                }
                            ),
                            in: -10...10
                        ) {
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

    // MARK: - Helpers

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

    private func applyChanges() {
        viewModel.settings = draftSettings
        viewModel.settings.save()
        Task {
            await viewModel.refreshIfAllowed(ignoreCooldown: true)
        }
    }
}
