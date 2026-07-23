//
//  EventListView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI

struct EventListView: View {
    @State private var viewModel = EventListViewModel()
    @State private var showCreateEvent = false

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack {
                // Sorting button row
                HStack {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                viewModel.sortOption = option
                                viewModel.fetchEvents()
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                    if viewModel.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Sorting", systemImage: "arrow.up.arrow.down")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.fieldBackground)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 20))
                    }
                    .accessibilityIdentifier("sort_menu")

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.errorMessage != nil {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("An error has occured,\nplease try again later")
                    } actions: {
                        Button("Try again") {
                            viewModel.fetchEvents()
                        }
                        .accessibilityIdentifier("error_retry_button")
                    }
                    .accessibilityIdentifier("error_state_view")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.events.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun événement trouvé.", systemImage: "calendar.badge.exclamationmark")
                    } actions: {
                        Button("Add Mock Data") {
                            viewModel.addMockData()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.events) { event in
                                NavigationLink(value: event) {
                                    EventRowView(event: event)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityIdentifier("event_row_\(event.title)")
                            }
                        }
                        .padding(.bottom, 80) // space for FAB
                    }
                }
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showCreateEvent = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(AppTheme.accent)
                            .clipShape(Circle())
                            .shadow(radius: 4, x: 0, y: 4)
                    }
                    .accessibilityIdentifier("create_event_fab")
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchQuery, prompt: "Search")
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.fetchEvents()
        }
        .onAppear {
            viewModel.fetchEvents()
        }
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
        .navigationDestination(isPresented: $showCreateEvent) {
            EventCreationView()
        }
    }
}

#Preview {
    NavigationStack {
        EventListView()
    }
}
