import SwiftUI

struct FeedbackSheetView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var feedbackManager: FeedbackManager
    
    @State private var draft = ""
    @State private var isSending = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        composerCard
                        if showSuccess {
                            successBanner
                        }
                        historySection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { isPresented = false }
                        .foregroundColor(EmberColors.cream)
                }
            }
        }
    }
    
    private var composerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tell us what’s working—or what’s not.")
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.7))
            
            ZStack(alignment: .topLeading) {
                if draft.isEmpty {
                    Text("Your feedback…")
                        .foregroundColor(EmberColors.cream.opacity(0.35))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $draft)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(EmberColors.cream)
                    .frame(minHeight: 120)
                    .padding(8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(EmberColors.dusk)
            )
            
            Button(action: send) {
                HStack {
                    if isSending {
                        ProgressView()
                            .tint(EmberColors.cream)
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Send")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(EmberColors.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(canSend ? EmberColors.ember : EmberColors.ember.opacity(0.35))
                )
            }
            .disabled(!canSend || isSending)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EmberColors.lightPlum)
        )
    }
    
    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Thanks — feedback saved.")
                .foregroundColor(EmberColors.cream)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(EmberColors.lightPlum)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previously sent")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
            
            if feedbackManager.entries.isEmpty {
                Text("No feedback yet. Your notes will show up here.")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.cream.opacity(0.55))
                    .padding(.vertical, 8)
            } else {
                ForEach(feedbackManager.entries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.text)
                            .font(.body)
                            .foregroundColor(EmberColors.cream)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(EmberColors.cream.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(EmberColors.lightPlum)
                    )
                }
            }
        }
    }
    
    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func send() {
        let text = draft
        isSending = true
        Task {
            let ok = await feedbackManager.submit(text)
            await MainActor.run {
                isSending = false
                if ok {
                    draft = ""
                    withAnimation { showSuccess = true }
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run {
                            withAnimation { showSuccess = false }
                        }
                    }
                }
            }
        }
    }
}

/// Floating feedback button (bottom-trailing, above tab bar).
struct FeedbackFAB: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        Button(action: { isPresented = true }) {
            Image(systemName: "megaphone.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(EmberColors.cream)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(EmberColors.ember)
                        .shadow(color: EmberColors.ember.opacity(0.45), radius: 10, y: 4)
                )
                .overlay(
                    Circle()
                        .strokeBorder(EmberColors.dusk2.opacity(0.6), lineWidth: 2)
                )
        }
        .accessibilityLabel("Send feedback")
        .padding(.trailing, 18)
        .padding(.bottom, 8)
    }
}
