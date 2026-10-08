import SwiftUI

struct ProfileSettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var friendsManager: FriendsManager
    @EnvironmentObject var characterManager: CharacterManager
    @EnvironmentObject var companionManager: CompanionManager
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    
    @AppStorage("profile.email") private var savedEmail: String = ""
    @AppStorage("profile.phone") private var savedPhone: String = ""
    
    @State private var emailInput: String = ""
    @State private var phoneInput: String = ""
    @State private var isSaving: Bool = false
    @State private var showingBuildPicker = false
    @State private var showingCompanionPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header info
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(EmberColors.ember)
                            
                            Text("Contact Information")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(EmberColors.cream)
                            
                            Text("Used to find you when friends pick you from Contacts. Invite codes still work.")
                                .font(.subheadline)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 12)
                        
                        Button {
                            showingBuildPicker = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: characterManager.selectedBuild?.iconName ?? "shield.fill")
                                    .font(.title3)
                                    .foregroundColor(EmberColors.ember)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Build")
                                        .font(.headline)
                                        .foregroundColor(EmberColors.cream)
                                    Text(characterManager.selectedBuild?.displayName ?? "Choose your build")
                                        .font(.subheadline)
                                        .foregroundColor(EmberColors.cream.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Text("Change")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(EmberColors.ember)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(EmberColors.lightPlum)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        Button {
                            showingCompanionPicker = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: companionManager.resolvedSpecies.iconName)
                                    .font(.title3)
                                    .foregroundColor(EmberColors.ember)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ember")
                                        .font(.headline)
                                        .foregroundColor(EmberColors.cream)
                                    Text(companionManager.selectedSpecies?.displayName ?? "Choose your Ember")
                                        .font(.subheadline)
                                        .foregroundColor(EmberColors.cream.opacity(0.7))
                                }

                                Spacer()

                                Text("Change")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(EmberColors.ember)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(EmberColors.lightPlum)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            
                            TextField("Optional", text: $emailInput)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.body)
                                .foregroundColor(EmberColors.cream)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(EmberColors.lightPlum)
                                )
                            
                            Text("We'll normalize this as lowercase")
                                .font(.caption)
                                .foregroundColor(EmberColors.cream.opacity(0.55))
                        }
                        .padding(.horizontal)
                        
                        // Phone field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            
                            TextField("Optional", text: $phoneInput)
                                .keyboardType(.phonePad)
                                .font(.body)
                                .foregroundColor(EmberColors.cream)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(EmberColors.lightPlum)
                                )
                            
                            Text("Only digits are used for matching")
                                .font(.caption)
                                .foregroundColor(EmberColors.cream.opacity(0.55))
                        }
                        .padding(.horizontal)
                        
                        // Info box
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(EmberColors.ember)
                                Text("Privacy Note")
                                    .font(.headline)
                                    .foregroundColor(EmberColors.cream)
                            }
                            
                            Text("Email and phone are stored in CloudKit and used only for friend discovery. You only need to provide one — either is enough.")
                                .font(.subheadline)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(EmberColors.lightPlum)
                        )
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(EmberColors.cream)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .foregroundColor(EmberColors.ember)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                emailInput = savedEmail
                phoneInput = savedPhone
            }
            .sheet(isPresented: $showingBuildPicker) {
                BuildChoiceSheet(isPresented: $showingBuildPicker, allowsSkip: false)
                    .environmentObject(characterManager)
            }
            .sheet(isPresented: $showingCompanionPicker) {
                CompanionChoiceSheet(isPresented: $showingCompanionPicker, allowsSkip: false)
                    .environmentObject(companionManager)
                    .environmentObject(avatarManager)
                    .environmentObject(levelManager)
            }
        }
    }
    
    private func save() {
        isSaving = true
        
        // Trim inputs
        let email = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = phoneInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save locally
        savedEmail = email
        savedPhone = phone
        
        // Update CloudKit
        Task {
            await friendsManager.updateMyContactInfo(
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone
            )
            
            await MainActor.run {
                isSaving = false
                isPresented = false
                friendsManager.toast = "Profile updated!"
            }
        }
    }
}
