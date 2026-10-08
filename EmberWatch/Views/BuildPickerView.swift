import SwiftUI

/// Card-style build picker used by onboarding, the existing-user sheet,
/// Goals, and Profile. Changing a later selection does not reset stats.
struct BuildPickerView: View {
    let selected: BuildKind?
    let onSelect: (BuildKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(BuildKind.allCases) { build in
                BuildPickerCard(
                    build: build,
                    isSelected: selected == build,
                    onSelect: { onSelect(build) }
                )
            }
        }
    }
}

struct BuildPickerCard: View {
    let build: BuildKind
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    BuildPickerIcon(iconName: build.iconName, isSelected: isSelected)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(build.displayName)
                            .font(.headline)
                            .foregroundColor(EmberColors.cream)
                        Text(build.goalLine)
                            .font(.subheadline)
                            .foregroundColor(EmberColors.cream.opacity(0.7))
                    }

                    Spacer(minLength: 8)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(EmberColors.ember)
                    }
                }

                BuildPrimaryStatChips(stats: build.primaryStats, isMage: build == .mage)

                Text(build.recommendedBehaviors.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(EmberColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
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
        let stats: String
        if build == .mage {
            stats = "all stats even"
        } else {
            stats = build.primaryStats.map(\.shortLabel).joined(separator: " ")
        }
        return "\(build.displayName). \(build.goalLine). Primary \(stats)."
    }
}

private struct BuildPickerIcon: View {
    let iconName: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? EmberColors.ember.opacity(0.22) : EmberColors.dusk)
                .frame(width: 44, height: 44)
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(EmberColors.ember)
        }
        .accessibilityHidden(true)
    }
}

struct BuildPrimaryStatChips: View {
    let stats: [CharacterStat]
    let isMage: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isMage {
                BuildStatChip(text: "ALL STATS")
            } else {
                ForEach(stats) { stat in
                    BuildStatChip(text: stat.shortLabel)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct BuildStatChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundColor(EmberColors.ember)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(EmberColors.ember.opacity(0.14))
            )
    }
}

/// Non-blocking sheet for existing users who have not chosen a build yet.
struct BuildChoiceSheet: View {
    @EnvironmentObject var characterManager: CharacterManager
    @Binding var isPresented: Bool
    let allowsSkip: Bool

    @State private var draft: BuildKind?

    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pick a playstyle. You can change it later — XP, level, and stats stay.")
                            .font(.subheadline)
                            .foregroundColor(EmberColors.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        BuildPickerView(selected: draft) { build in
                            draft = build
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Choose your build")
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
                            characterManager.selectBuild(draft)
                            isPresented = false
                        }
                    }
                    .foregroundColor(draft == nil ? EmberColors.muted : EmberColors.ember)
                    .disabled(draft == nil)
                }
            }
            .onAppear {
                draft = characterManager.selectedBuild
            }
        }
    }
}
