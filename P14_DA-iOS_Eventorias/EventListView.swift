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
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.events.isEmpty {
                    VStack(spacing: 20) {
                        Text("Aucun événement trouvé.")
                            .foregroundColor(.gray)
                        
                        Button("Générer des données de test") {
                            viewModel.addMockData()
                        }
                        .padding()
                        .background(Color(red: 0.85, green: 0.1, blue: 0.15))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.events) { event in
                                EventRowView(event: event)
                                    .padding(.horizontal)
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
        .sheet(isPresented: $showCreateEvent) {
            ZStack {
                Color(red: 0.12, green: 0.12, blue: 0.14).ignoresSafeArea()
                Text("Écran de création (à venir)")
                    .foregroundColor(.white)
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    NavigationView {
        EventListView()
    }
}
