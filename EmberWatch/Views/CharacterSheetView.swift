import SwiftUI

/// Home header: `LVL 37 — WARRIOR`.
/// Kept in this file so HomeView stays type-checker thin.
struct HomeLevelBuildHeader: View {
    let level: Int
    let buildName: String

    var body: some View {
        Text(headerText)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(EmberColors.cream.opacity(0.7))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityLabel(headerText)
    }

    private var headerText: String {
        if buildName.isEmpty {
            return "LVL \(level)"
        }
        return "LVL \(level) — \(buildName)"
    }
}

/// Full character sheet: stats, build, recommended behaviors, title, next-level XP.
struct CharacterSheetView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var characterManager: CharacterManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var companionManager: CompanionManager
    @EnvironmentObject var sparksManager: SparksManager
    @State private var showingEquipment = false

    var body: some View {
        NavigationView {
            ZStack {
                EmberColors.dusk.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CharacterSheetIdentityCard()
                        CharacterSheetEquipmentCard(showingEquipment: $showingEquipment)
                        CharacterSheetStatsCard()
                        CharacterSheetBuildCard()
                        CharacterSheetProgressCard()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(EmberColors.dusk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(EmberColors.ember)
                }
            }
            .sheet(isPresented: $showingEquipment) {
                EquipmentView()
                    .environmentObject(companionManager)
                    .environmentObject(sparksManager)
                    .environmentObject(levelManager)
            }
        }
    }
}

private struct CharacterSheetIdentityCard: View {
    @EnvironmentObject var characterManager: CharacterManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var companionManager: CompanionManager
    @State private var nameDraft = ""
    @State private var isEditingName = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                identityPortrait

                VStack(alignment: .leading, spacing: 6) {
                    if isEditingName {
                        TextField("Name your Ember", text: $nameDraft)
                            .font(.title3.bold())
                            .foregroundColor(EmberColors.cream)
                            .onSubmit {
                                saveName()
                            }
                    } else {
                        Text(avatarManager.displayName)
                            .font(.title2.bold())
                            .foregroundColor(EmberColors.cream)
                    }

                    Text(headerLine)
                        .font(.headline)
                        .foregroundColor(EmberColors.ember)

                    Text(levelManager.levelTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(EmberColors.cream.opacity(0.75))

                    Text(companionManager.tier(forLevel: levelManager.level).gearLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(EmberColors.muted)
                }
            }

            Button(isEditingName ? "Save name" : "Rename Ember") {
                if isEditingName {
                    saveName()
                } else {
                    nameDraft = avatarManager.emberName
                    isEditingName = true
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(EmberColors.ember)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(EmberColors.lightPlum)
        )
    }

    @ViewBuilder
    private var identityPortrait: some View {
        if let build = characterManager.selectedBuild, let heroName = build.heroImageName {
            BuildHeroPortrait(
                imageName: heroName,
                width: 88,
                cornerRadius: 12,
                accessibilityName: build.displayName
            )
        } else {
            CompanionAvatarView(
                species: companionManager.resolvedSpecies,
                stage: companionManager.stage(forLevel: levelManager.level),
                tier: companionManager.tier(forLevel: levelManager.level),
                size: 72,
                equipped: companionManager.equippedMap(),
                prestigeSkinId: companionManager.activePrestigeSkinId
            )
        }
    }

    private func saveName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            avatarManager.emberName = trimmed
        }
        isEditingName = false
    }

    private var headerLine: String {
        let level = levelManager.level
        let build = characterManager.buildDisplayName
        if build.isEmpty {
            return "LVL \(level)"
        }
        return "LVL \(level) — \(build)"
    }
}

private struct CharacterSheetEquipmentCard: View {
    @Binding var showingEquipment: Bool
    @EnvironmentObject var companionManager: CompanionManager
    @EnvironmentObject var levelManager: LevelManager

    var body: some View {
        Button {
            showingEquipment = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "shield.fill")
                    .font(.title3)
                    .foregroundColor(EmberColors.ember)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Equipment")
                        .font(.headline)
                        .foregroundColor(EmberColors.cream)
                    Text("Cosmetic slots · \(companionManager.tier(forLevel: levelManager.level).gearLabel)")
                        .font(.caption)
                        .foregroundColor(EmberColors.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(EmberColors.muted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(EmberColors.lightPlum)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CharacterSheetStatsCard: View {
    @EnvironmentObject var characterManager: CharacterManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.headline)
                .foregroundColor(EmberColors.cream)

            ForEach(CharacterStat.allCases) { stat in
                CharacterSheetStatRow(
                    stat: stat,
                    value: characterManager.displayedValue(for: stat),
                    fraction: characterManager.barFraction(for: stat),
                    isPrimary: characterManager.isPrimary(stat)
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(EmberColors.lightPlum)
        )
    }
}

private struct CharacterSheetStatRow: View {
    let stat: CharacterStat
    let value: Int
    let fraction: Double
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stat.shortLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(isPrimary ? EmberColors.ember : EmberColors.cream)
                Text(stat.fullName)
                    .font(.caption)
                    .foregroundColor(EmberColors.muted)
                if isPrimary {
                    Text("PRIMARY")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(EmberColors.ember)
                }
                Spacer()
                Text("\(value)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundColor(EmberColors.cream)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(EmberColors.dusk)
                        .frame(height: 8)
                    Capsule()
                        .fill(isPrimary ? EmberColors.ember : EmberColors.cream.opacity(0.35))
                        .frame(width: max(0, geometry.size.width * fraction), height: 8)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stat.fullName) \(value)\(isPrimary ? ", primary" : "")")
    }
}

private struct CharacterSheetBuildCard: View {
    @EnvironmentObject var characterManager: CharacterManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Build")
                .font(.headline)
                .foregroundColor(EmberColors.cream)

            if let build = characterManager.selectedBuild {
                HStack(spacing: 10) {
                    Image(systemName: build.iconName)
                        .font(.title3)
                        .foregroundColor(EmberColors.ember)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(build.displayName)
                            .font(.headline)
                            .foregroundColor(EmberColors.cream)
                        Text(build.goalLine)
                            .font(.subheadline)
                            .foregroundColor(EmberColors.cream.opacity(0.7))
                    }
                }

                Text(build.summary)
                    .font(.subheadline)
                    .foregroundColor(EmberColors.cream.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                BuildPrimaryStatChips(stats: build.primaryStats, isMage: build == .mage)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(EmberColors.muted)
                    ForEach(build.recommendedBehaviors, id: \.self) { item in
                        Text("• \(item)")
                            .font(.subheadline)
                            .foregroundColor(EmberColors.cream.opacity(0.8))
                    }
                }
            } else {
                Text("Choose a build from Goals or Profile. Stats still grow from your habits.")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(EmberColors.lightPlum)
        )
    }
}

private struct CharacterSheetProgressCard: View {
    @EnvironmentObject var levelManager: LevelManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Level")
                .font(.headline)
                .foregroundColor(EmberColors.cream)

            Text(levelManager.levelTitle)
                .font(.title3.weight(.bold))
                .foregroundColor(EmberColors.ember)

            if levelManager.level >= LevelManager.maxLevel {
                Text("Max level — overflow XP stays as prestige.")
                    .font(.subheadline)
                    .foregroundColor(EmberColors.muted)
            } else {
                progressCopy
                progressBar
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(EmberColors.lightPlum)
        )
    }

    private var progressCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(xpThisLevelText)
                .font(.subheadline)
                .foregroundColor(EmberColors.cream.opacity(0.75))
            Text(xpToNextText)
                .font(.caption)
                .foregroundColor(EmberColors.muted)
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(EmberColors.dusk)
                    .frame(height: 10)
                Capsule()
                    .fill(EmberColors.ember)
                    .frame(width: max(0, geometry.size.width * levelManager.progressFraction), height: 10)
            }
        }
        .frame(height: 10)
    }

    private var xpThisLevelText: String {
        let into = XPRules.groupedNumber(levelManager.xpIntoLevel)
        let need = XPRules.groupedNumber(levelManager.xpForNextLevel)
        return "\(into) / \(need) XP this level"
    }

    private var xpToNextText: String {
        let remaining = max(0, levelManager.xpForNextLevel - levelManager.xpIntoLevel)
        return "\(XPRules.groupedNumber(remaining)) XP to level \(levelManager.level + 1)"
    }
}
