import SwiftUI

/// Card-style companion picker used by onboarding and the existing-user sheet.
struct CompanionPickerView: View {
    let selected: CompanionSpecies?
    let suggested: CompanionSpecies?
    let previewLevel: Int
    let onSelect: (CompanionSpecies) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(CompanionSpecies.allCases) { species in
                CompanionPickerCard(
                    species: species,
                    isSelected: selected == species,
                    isSuggested: suggested == species,
                    previewLevel: previewLevel,
                    onSelect: { onSelect(species) }
                )
            }
        }
    }
}

struct CompanionPickerCard: View {
    let species: CompanionSpecies
    let isSelected: Bool
    let isSuggested: Bool
    let previewLevel: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
                CompanionAvatarView(
                    species: species,
                    stage: CompanionStage.current(forLevel: previewLevel),
                    tier: ProgressionTier.current(forLevel: previewLevel),
                    size: 64
                )
                .frame(width: 72, height: 80)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(species.displayName)
                            .font(.headline)
                            .foregroundColor(EmberColors.cream)
                        if isSuggested {
                            Text("Closest")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(EmberColors.ember)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(EmberColors.ember.opacity(0.14))
                                )
                        }
                    }
                    Text(species.tagline)
                        .font(.subheadline)
                        .foregroundColor(EmberColors.cream.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(EmberColors.ember)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(EmberColors.lightPlum)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? EmberColors.ember : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [species.displayName, species.tagline]
        if isSuggested { parts.append("closest match") }
        if isSelected { parts.append("selected") }
        return parts.joined(separator: ". ")
    }
}

/// Non-blocking sheet for existing users who have not chosen a companion yet.
struct CompanionChoiceSheet: View {
    @EnvironmentObject var companionManager: CompanionManager
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    @Binding var isPresented: Bool
    let allowsSkip: Bool

    @State private var draft: CompanionSpecies?

    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Ember is a companion that evolves as you level. You can rename it any time. Pick one now, or later — XP stays.")
                            .font(.subheadline)
                            .foregroundColor(EmberColors.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        CompanionPickerView(
                            selected: draft,
                            suggested: suggestedSpecies,
                            previewLevel: levelManager.level,
                            onSelect: { species in
                                draft = species
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Choose your Ember")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if allowsSkip {
                        Button("Later") {
                            isPresented = false
                        }
                        .foregroundColor(EmberColors.cream)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let draft {
                            companionManager.selectSpecies(draft, level: levelManager.level)
                            isPresented = false
                        }
                    }
                    .foregroundColor(draft == nil ? EmberColors.muted : EmberColors.ember)
                    .disabled(draft == nil)
                }
            }
            .onAppear {
                draft = companionManager.selectedSpecies ?? suggestedSpecies
            }
        }
    }

    private var suggestedSpecies: CompanionSpecies {
        CompanionSpecies.suggested(fromAvatarId: avatarManager.selectedAvatarId)
    }
}
