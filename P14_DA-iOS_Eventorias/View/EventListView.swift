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
            Color(red: 0.12, green: 0.12, blue: 0.14)
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
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sorting")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(white: 0.3))
                        .foregroundColor(.white)
                        .cornerRadius(20)
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
                    ErrorStateView {
                        viewModel.fetchEvents()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.events.isEmpty {
                    VStack(spacing: 20) {
                        Text("Aucun événement trouvé.")
                            .foregroundColor(.gray)
                        

                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.events) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
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
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(red: 0.85, green: 0.1, blue: 0.15))
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
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Add Mock Data") {
                    viewModel.addMockData()
                }
            }
            #endif
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search")
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.fetchEvents()
        }
        .onAppear {
            viewModel.fetchEvents()
        }
        .navigationDestination(isPresented: $showCreateEvent) {
            EventCreationView()
        }
    }
}

/// Full-screen error placeholder shown when event loading fails, with a retry action.
struct ErrorStateView: View {
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 90, height: 90)
                .background(Color(white: 0.35))
                .clipShape(Circle())

            Text("Error")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("An error has occured,\nplease try again later")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button(action: retryAction) {
                Text("Try again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.85, green: 0.1, blue: 0.15))
                    .cornerRadius(8)
            }
            .accessibilityIdentifier("error_retry_button")
            .padding(.top, 8)
        }
        .padding()
        .accessibilityIdentifier("error_state_view")
    }
}

#Preview {
    NavigationStack {
        EventListView()
    }
}

#Preview("Error State") {
    ErrorStateView {}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
}
