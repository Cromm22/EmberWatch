import SwiftUI
import Contacts
import ContactsUI

enum AddFriendPath {
    case contacts
    case inviteCode
}

struct AddFriendView: View {
    @EnvironmentObject var friendsManager: FriendsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPath: AddFriendPath?
    @State private var inviteCode = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showContactPicker = false
    @State private var contactsPermissionDenied = false
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if !friendsManager.isCloudKitAvailable {
                            cloudKitWarning
                        }
                        
                        if selectedPath == nil {
                            pathSelection
                        } else if selectedPath == .contacts {
                            contactsPath
                        } else if selectedPath == .inviteCode {
                            inviteCodePath
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(EmberColors.ember)
                }
            }
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(
                    onContactSelected: handleContactSelected,
                    onDismiss: { showContactPicker = false }
                )
            }
        }
    }
    
    private var cloudKitWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.icloud.fill")
                .foregroundColor(EmberColors.ember)
            Text(friendsManager.cloudKitError ?? "iCloud unavailable")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var pathSelection: some View {
        VStack(spacing: 20) {
            Text("How would you like to add a friend?")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
            
            VStack(spacing: 12) {
                // Contacts path
                Button {
                    selectedPath = .contacts
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .font(.title2)
                            .foregroundColor(EmberColors.ember)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("From Contacts")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            Text("Find friends already using Ember")
                                .font(.caption)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(EmberColors.cream.opacity(0.5))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(EmberColors.lightPlum)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!friendsManager.isCloudKitAvailable)
                .opacity(friendsManager.isCloudKitAvailable ? 1.0 : 0.5)
                
                // Invite code path
                Button {
                    selectedPath = .inviteCode
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "number.circle.fill")
                            .font(.title2)
                            .foregroundColor(EmberColors.gold)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Invite Code")
                                .font(.headline)
                                .foregroundColor(EmberColors.cream)
                            Text("Enter a friend's 8-character code")
                                .font(.caption)
                                .foregroundColor(EmberColors.cream.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(EmberColors.cream.opacity(0.5))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(EmberColors.lightPlum)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!friendsManager.isCloudKitAvailable)
                .opacity(friendsManager.isCloudKitAvailable ? 1.0 : 0.5)
            }
        }
    }
    
    private var contactsPath: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    selectedPath = nil
                    errorMessage = nil
                    contactsPermissionDenied = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(EmberColors.ember)
                }
                Spacer()
            }
            
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(EmberColors.ember.opacity(0.7))
                
                Text("Add from Contacts")
                    .font(.title2.weight(.bold))
                    .foregroundColor(EmberColors.cream)
                
                Text("Select a contact to check if they're on Ember. We'll only look up the contact you choose—your full address book stays private.")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.cream.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical)
            
            if contactsPermissionDenied {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(EmberColors.ember)
                        Text("Contacts access denied")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(EmberColors.cream)
                        Spacer()
                    }
                    
                    Text("Please enable Contacts access in Settings to find friends from your contacts.")
                        .font(.caption)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(EmberColors.ember)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(EmberColors.lightPlum)
                )
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                checkContactsPermissionAndPick()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(EmberColors.cream)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Choose from Contacts")
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(EmberColors.ember)
            )
            .disabled(isLoading || !friendsManager.isCloudKitAvailable)
            
            Spacer()
        }
    }
    
    private var inviteCodePath: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    selectedPath = nil
                    inviteCode = ""
                    errorMessage = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(EmberColors.ember)
                }
                Spacer()
            }
            
            Text("Enter your friend's 8-character code to add them")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 16)
            
            TextField("Friend Code", text: $inviteCode)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(EmberColors.cream)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(EmberColors.lightPlum)
                )
                .disabled(isLoading)
                .onChange(of: inviteCode) { _, newValue in
                    // Normalize: trim and uppercase
                    let normalized = newValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    if normalized != newValue && !normalized.isEmpty {
                        inviteCode = normalized
                    }
                }
            
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                addFriendByCode()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(EmberColors.cream)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Add Friend")
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isAddFriendEnabled ? EmberColors.ember : EmberColors.ember.opacity(0.5))
            )
            .disabled(!isAddFriendEnabled)
            
            Spacer()
        }
    }
    
    private var isAddFriendEnabled: Bool {
        let trimmed = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !isLoading && friendsManager.isCloudKitAvailable
    }
    
    private func checkContactsPermissionAndPick() {
        let store = CNContactStore()
        
        Task {
            let status = CNContactStore.authorizationStatus(for: .contacts)
            
            switch status {
            case .authorized:
                await MainActor.run {
                    contactsPermissionDenied = false
                    showContactPicker = true
                }
            case .notDetermined:
                do {
                    let granted = try await store.requestAccess(for: .contacts)
                    await MainActor.run {
                        if granted {
                            contactsPermissionDenied = false
                            showContactPicker = true
                        } else {
                            contactsPermissionDenied = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        contactsPermissionDenied = true
                        errorMessage = "Could not request contacts permission"
                    }
                }
            case .denied, .restricted:
                await MainActor.run {
                    contactsPermissionDenied = true
                }
            @unknown default:
                await MainActor.run {
                    contactsPermissionDenied = true
                }
            }
        }
    }
    
    private func handleContactSelected(_ contact: CNContact) {
        errorMessage = nil
        isLoading = true
        
        Task {
            // Try email first
            if !contact.emailAddresses.isEmpty {
                let email = contact.emailAddresses[0].value as String
                
                do {
                    let friend = try await friendsManager.addFriend(email: email)
                    await MainActor.run {
                        isLoading = false
                        friendsManager.toast = "Added \(friend.name)!"
                        dismiss()
                    }
                    return
                } catch {
                    // Try phone if email fails
                }
            }
            
            // Try phone
            if !contact.phoneNumbers.isEmpty {
                let phone = contact.phoneNumbers[0].value.stringValue
                
                do {
                    let friend = try await friendsManager.addFriend(phone: phone)
                    await MainActor.run {
                        isLoading = false
                        friendsManager.toast = "Added \(friend.name)!"
                        dismiss()
                    }
                    return
                } catch {
                    // Continue to error handling
                }
            }
            
            // Not found
            await MainActor.run {
                isLoading = false
                let contactName = CNContactFormatter.string(from: contact, style: .fullName) ?? "This contact"
                errorMessage = "\(contactName) isn't on Ember yet. Try sharing your invite code with them!"
            }
        }
    }
    
    private func addFriendByCode() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                try await friendsManager.addFriend(code: inviteCode)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Contact Picker

struct ContactPickerView: UIViewControllerRepresentable {
    let onContactSelected: (CNContact) -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onContactSelected: onContactSelected, onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactSelected: (CNContact) -> Void
        let onDismiss: () -> Void
        
        init(onContactSelected: @escaping (CNContact) -> Void, onDismiss: @escaping () -> Void) {
            self.onContactSelected = onContactSelected
            self.onDismiss = onDismiss
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onContactSelected(contact)
            onDismiss()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onDismiss()
        }
    }
}
