//
//  EventCreationView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI
import PhotosUI

struct EventCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) var authManager
    @State private var viewModel = EventCreationViewModel()
    
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            TextField("New event", text: $viewModel.title)
                                .foregroundStyle(.white)
                                .accessibilityIdentifier("event_title_field")
                        }
                        .padding()
                        .background(AppTheme.fieldBackground)
                        .clipShape(.rect(cornerRadius: 8))

                        // Description
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            TextField("Description", text: $viewModel.description, axis: .vertical)
                                .lineLimit(5...)
                                .foregroundStyle(.white)
                                .accessibilityIdentifier("event_description_field")
                        }
                        .padding()
                        .background(AppTheme.fieldBackground)
                        .clipShape(.rect(cornerRadius: 8))

                        // Date and Time
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityIdentifier("event_date_picker")
                            }
                            .padding()
                            .background(AppTheme.fieldBackground)
                            .clipShape(.rect(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                DatePicker("", selection: $viewModel.time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityIdentifier("event_time_picker")
                            }
                            .padding()
                            .background(AppTheme.fieldBackground)
                            .clipShape(.rect(cornerRadius: 8))
                        }

                        // Address
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            TextField("Enter full address", text: $viewModel.address)
                                .foregroundStyle(.white)
                                .accessibilityIdentifier("event_address_field")
                        }
                        .padding()
                        .background(AppTheme.fieldBackground)
                        .clipShape(.rect(cornerRadius: 8))

                        // Image selection buttons
                        HStack(spacing: 16) {
                            Button("Take Photo", systemImage: "camera", action: {
                                showCamera = true
                            })
                            .labelStyle(.iconOnly)
                            .font(.system(size: 24))
                            .foregroundStyle(.black)
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .clipShape(.rect(cornerRadius: 16))
                            .accessibilityIdentifier("camera_button")

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("Choose from Library", systemImage: "paperclip")
                                    .labelStyle(.iconOnly)
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                                    .frame(width: 60, height: 60)
                                    .background(AppTheme.accent)
                                    .clipShape(.rect(cornerRadius: 16))
                            }
                            .accessibilityIdentifier("photo_library_button")
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        viewModel.selectedImage = image
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                        
                        // Image preview
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(.rect(cornerRadius: 16))
                                .padding(.top, 16)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                }
                
                // Validate Button
                Button(action: {
                    viewModel.createEvent(authManager: authManager) { success in
                        if success {
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Validate")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent)
                    .clipShape(.rect(cornerRadius: 8))
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("save_event_button")
                .padding()
            }
        }
        .navigationTitle("Creation of an event")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    NavigationStack {
        EventCreationView()
    }
}
