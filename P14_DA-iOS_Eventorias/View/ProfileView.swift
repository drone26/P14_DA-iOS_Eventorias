//
//  ProfileView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AuthManager.self) var authManager
    @State private var viewModel = ProfileViewModel()
    @FocusState private var isNameFocused: Bool
    
    @State private var showSourceSelector = false
    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    
    var body: some View {
        @Bindable var viewModel = viewModel
        @Bindable var authManager = authManager
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
                .onTapGesture {
                    isNameFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(alignment: .leading, spacing: 24) {
                // Header: Title and Avatar
                HStack {
                    Text("User profile")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.white)

                    Spacer()

                    // Avatar
                    Button(action: {
                        showSourceSelector = true
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            if let avatarUrl = viewModel.profile?.avatarUrl, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(ProgressView())
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(Image(systemName: "person.fill").foregroundStyle(.gray))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(Image(systemName: "person.fill").foregroundStyle(.gray))
                            }

                            // Edit icon badge
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Image(systemName: "pencil")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 4, y: 4)
                        }
                    }
                    .accessibilityLabel("Change profile photo")
                    .accessibilityIdentifier("profile_avatar_button")
                    .confirmationDialog("Choose Avatar", isPresented: $showSourceSelector, titleVisibility: .visible) {
                        Button("Camera") {
                            imageSource = .camera
                            showImagePicker = true
                        }
                        Button("Photo Library") {
                            imageSource = .photoLibrary
                            showImagePicker = true
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                    .fullScreenCover(isPresented: $showImagePicker) {
                        #if DEBUG
                        if ProcessInfo.processInfo.arguments.contains("-UITestMockImagePicker") {
                            Color.clear
                                .onAppear {
                                    // Instantly "pick" a mock image to trigger onChange
                                    selectedImage = UIImage(systemName: "star")
                                    showImagePicker = false
                                }
                        } else {
                            ImagePicker(selectedImage: $selectedImage, sourceType: imageSource)
                                .ignoresSafeArea()
                        }
                        #else
                        ImagePicker(selectedImage: $selectedImage, sourceType: imageSource)
                            .ignoresSafeArea()
                        #endif
                    }
                    .onChange(of: selectedImage) { _, newImage in
                        if let image = newImage {
                            viewModel.uploadAvatar(image: image, authManager: authManager)
                        }
                    }
                }
                .padding(.top, 16)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else if let profileBinding = Binding($viewModel.profile) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        TextField("Name", text: profileBinding.name)
                            .focused($isNameFocused)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .submitLabel(.done)
                            .accessibilityIdentifier("profile_name_field")
                            .onSubmit {
                                isNameFocused = false
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                            .onChange(of: isNameFocused) { oldValue, newValue in
                                if oldValue && !newValue {
                                    viewModel.saveName(authManager: authManager, newName: profileBinding.wrappedValue.name)
                                }
                            }
                    }
                    .padding()
                    .background(AppTheme.fieldBackground)
                    .clipShape(.rect(cornerRadius: 8))

                    // Email Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("E-mail")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(profileBinding.wrappedValue.email)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("profile_email_text")
                    }
                    .padding()
                    .background(AppTheme.fieldBackground)
                    .clipShape(.rect(cornerRadius: 8))

                    // Notifications Toggle
                    Toggle(isOn: profileBinding.notificationsEnabled) {
                        Text("Notifications")
                            .foregroundStyle(.white)
                    }
                    .tint(AppTheme.accent)
                    .padding(.top, 8)
                    .accessibilityIdentifier("profile_notifications_toggle")
                    .onChange(of: profileBinding.wrappedValue.notificationsEnabled) { _, newValue in
                        viewModel.toggleNotifications(authManager: authManager, isOn: newValue)
                    }

                    Spacer()

                    // Sign Out Button
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accent)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    .accessibilityIdentifier("sign_out_button")
                    .padding(.bottom, 20)
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.fetchProfile(authManager: authManager)
        }
        .alert("Error", isPresented: $authManager.isShowingSignOutError) {
        } message: {
            Text(authManager.signOutErrorMessage ?? "")
        }
    }
}

#Preview {
    let mockAuth = AuthManager()
    return ProfileView()
        .environment(mockAuth)
}
