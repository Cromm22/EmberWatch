import SwiftUI

/// Shared light-gallery chrome used by Avatar Gallery and Crystal Shop.
enum GalleryPalette {
    static let accent = Color(hex: "#4C82F7")
    static let title = Color(hex: "#111827")
    static let subtitle = Color(hex: "#6B7280")
    static let price = Color(hex: "#FF8A3D")
    static let sky = LinearGradient(
        colors: [Color(hex: "#F2F7FF"), Color.white],
        startPoint: .top,
        endPoint: .bottom
    )
}

@ViewBuilder
func galleryHeader(title: String, onBack: @escaping () -> Void, onDone: @escaping () -> Void) -> some View {
    ZStack {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(GalleryPalette.title)

        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(GalleryPalette.title)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(GalleryPalette.accent))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Done")
        }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .padding(.bottom, 6)
}

@ViewBuilder
func galleryBalanceBar(coins: Int, crystals: Int, onInfo: (() -> Void)?) -> some View {
    HStack(spacing: 10) {
        galleryCurrencyChip(icon: "circle.fill", tint: Color(hex: "#C98A12"), text: "\(XPRules.groupedNumber(max(0, coins))) Coins")
        galleryCurrencyChip(icon: "diamond.fill", tint: EmberColors.ember, text: "\(XPRules.groupedNumber(max(0, crystals))) Crystals")

        Spacer(minLength: 4)

        HStack(spacing: 4) {
            Text("Cosmetics only")
                .font(.caption)
                .foregroundColor(GalleryPalette.subtitle)
            if let onInfo {
                Button(action: onInfo) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(GalleryPalette.subtitle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About Coins and Crystals")
            } else {
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GalleryPalette.subtitle)
            }
        }
    }
}

@ViewBuilder
private func galleryCurrencyChip(icon: String, tint: Color, text: String) -> some View {
    HStack(spacing: 5) {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(tint)
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(GalleryPalette.title)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

struct AvatarPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var sparksManager: SparksManager
    @EnvironmentObject var companionManager: CompanionManager

    @State private var showingShop = false
    @State private var showingCosmeticsInfo = false
    @State private var showingEquipment = false
    @State private var showingCompanionPicker = false

    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            GalleryPalette.sky.ignoresSafeArea()

            VStack(spacing: 0) {
                galleryHeader(
                    title: "Ember Shop",
                    onBack: { dismiss() },
                    onDone: { dismiss() }
                )

                // Header + shop CTA stay pinned. The grid must take remaining
                // height (not its ideal/content height) or the sheet clips and
                // cannot scroll — a VStack otherwise sizes ScrollView to its
                // full content and nothing moves.
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 18) {
                        galleryBalanceBar(
                            coins: sparksManager.coins,
                            crystals: sparksManager.balance,
                            onInfo: { showingCosmeticsInfo = true }
                        )
                        .padding(.horizontal, 20)

                        VStack(spacing: 6) {
                            Text("Cosmetics only")
                                .font(.title2.weight(.bold))
                                .foregroundColor(GalleryPalette.title)
                                .multilineTextAlignment(.center)
                            Text("Coins and Crystals never buy XP, levels, workouts, or boosters.")
                                .font(.subheadline)
                                .foregroundColor(GalleryPalette.subtitle)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)

                        shopPreview
                            .padding(.horizontal, 16)

                        equipmentCTA
                            .padding(.horizontal, 16)

                        shopSectionTitle("Basic companion skins")

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(AvatarStyle.presets) { style in
                                let unlocked = sparksManager.isAvatarUnlocked(style.id)
                                AvatarThumbnail(
                                    style: style,
                                    isSelected: avatarManager.selectedAvatarId == style.id,
                                    level: levelManager.level,
                                    isLocked: !unlocked,
                                    price: SparksManager.avatarUnlockPrice
                                ) {
                                    if unlocked {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            avatarManager.selectAvatar(style.id)
                                        }
                                    } else if sparksManager.unlockAvatar(style.id) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            avatarManager.selectAvatar(style.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        shopCatalogSection(title: "Profile backgrounds", items: ShopCatalog.backgrounds)
                            .padding(.horizontal, 16)

                        shopCatalogSection(title: "Emotes", items: ShopCatalog.emotes)
                            .padding(.horizontal, 16)

                        shopCatalogSection(title: "Themes", items: ShopCatalog.themes)
                            .padding(.horizontal, 16)

                        shopCatalogSection(title: "Character effects", items: ShopCatalog.effects)
                            .padding(.horizontal, 16)

                        cosmeticsSection
                            .padding(.horizontal, 16)

                        shopCatalogSection(title: "Premium skins", items: ShopCatalog.premium.filter { $0.id.hasPrefix("skin.") })
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.always, axes: .vertical)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                getMoreSparksCard
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.96).ignoresSafeArea(edges: .bottom))
            }

            if let toast = sparksManager.toast {
                VStack {
                    Text(toast)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(EmberColors.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [EmberColors.ember, EmberColors.emberAccent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .padding(.top, 12)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(30)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: sparksManager.toast)
        .alert("Cosmetics only", isPresented: $showingCosmeticsInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Coins unlock standard companion styles. Crystals unlock premium flair. Neither ever gates food, water, HealthKit, workouts, or calorie tracking.")
        }
        .sheet(isPresented: $showingShop) {
            SparksShopView()
                .environmentObject(sparksManager)
        }
        .sheet(isPresented: $showingEquipment) {
            EquipmentView()
                .environmentObject(companionManager)
                .environmentObject(sparksManager)
                .environmentObject(levelManager)
        }
        .sheet(isPresented: $showingCompanionPicker) {
            CompanionChoiceSheet(isPresented: $showingCompanionPicker, allowsSkip: false)
                .environmentObject(companionManager)
                .environmentObject(avatarManager)
                .environmentObject(levelManager)
        }
    }

    private var shopPreview: some View {
        HStack(spacing: 12) {
            CompanionAvatarView(
                species: companionManager.resolvedSpecies,
                stage: companionManager.stage(forLevel: levelManager.level),
                tier: companionManager.tier(forLevel: levelManager.level),
                size: 88,
                extraGlow: sparksManager.hasGlow,
                equipped: companionManager.equippedMap(),
                effectId: companionManager.activeEffectId,
                prestigeSkinId: companionManager.activePrestigeSkinId
            )
            .frame(width: 96, height: 108)

            VStack(alignment: .leading, spacing: 6) {
                Text(avatarManager.displayName)
                    .font(.headline)
                    .foregroundColor(GalleryPalette.title)
                Text(companionManager.resolvedSpecies.displayName)
                    .font(.subheadline)
                    .foregroundColor(GalleryPalette.subtitle)
                Button("Change Ember") {
                    showingCompanionPicker = true
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(GalleryPalette.accent)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 3)
        )
    }

    private var equipmentCTA: some View {
        Button {
            showingEquipment = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "shield.fill")
                    .foregroundColor(EmberColors.ember)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Equipment")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(GalleryPalette.title)
                    Text("Six slots · cosmetic only")
                        .font(.caption)
                        .foregroundColor(GalleryPalette.subtitle)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(GalleryPalette.subtitle)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func shopSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(GalleryPalette.title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }

    private func shopCatalogSection(title: String, items: [CosmeticShopItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(GalleryPalette.title)
            ForEach(items) { item in
                ShopCosmeticRow(
                    item: item,
                    isOwned: isShopOwned(item),
                    isActive: isShopActive(item),
                    onBuy: { buyShopItem(item) },
                    onUse: { useShopItem(item) }
                )
            }
        }
    }

    private func isShopOwned(_ item: CosmeticShopItem) -> Bool {
        if sparksManager.isCosmeticUnlocked(item.id) { return true }
        return companionManager.isCosmeticOwned(item.id)
    }

    private func isShopActive(_ item: CosmeticShopItem) -> Bool {
        switch item.category {
        case .backgrounds:
            return companionManager.activeBackgroundId == item.id
        case .themes:
            return companionManager.activeThemeId == item.id
        case .emotes:
            return companionManager.activeEmoteId == item.id
        case .effects:
            return companionManager.activeEffectId == item.id
        case .premium:
            if item.id.hasPrefix("skin.") {
                return companionManager.activePrestigeSkinId == item.id
            }
            return false
        case .equipment, .skins:
            return false
        }
    }

    private func buyShopItem(_ item: CosmeticShopItem) {
        if item.id == "glow" || item.id.hasPrefix("nameplate_") {
            _ = sparksManager.unlockCosmetic(item.id)
            return
        }
        _ = companionManager.purchaseCosmetic(item, wallet: sparksManager)
    }

    private func useShopItem(_ item: CosmeticShopItem) {
        if item.id == "glow" {
            sparksManager.toggleGlow()
            return
        }
        if item.id.hasPrefix("nameplate_") {
            let active = sparksManager.activeNameplateId == item.id
            sparksManager.selectNameplate(active ? nil : item.id)
            return
        }
        if item.id.hasPrefix("skin.") {
            if companionManager.activePrestigeSkinId == item.id {
                companionManager.clearPrestigeSkin()
            } else {
                companionManager.activateCosmetic(item)
            }
            return
        }
        companionManager.activateCosmetic(item)
    }

    private var getMoreSparksCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#F3E8FF"),
                                Color(hex: "#FDE68A"),
                                Color(hex: "#FECACA")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#C084FC"),
                                Color(hex: "#FB7185"),
                                Color(hex: "#FBBF24")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "#C084FC").opacity(0.35), radius: 4)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Get More Crystals")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(GalleryPalette.title)
                Text("Unlock rare companions and more!")
                    .font(.caption)
                    .foregroundColor(GalleryPalette.subtitle)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                showingShop = true
            } label: {
                Text("View Shop")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(GalleryPalette.accent))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View Shop")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 16, y: 4)
        )
    }

    private var cosmeticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cosmetic unlocks")
                .font(.headline)
                .foregroundColor(GalleryPalette.title)

            Text("Status flair only — never gates tracking.")
                .font(.caption)
                .foregroundColor(GalleryPalette.subtitle)

            ForEach(SparksManager.cosmetics) { item in
                let unlocked = sparksManager.isCosmeticUnlocked(item.id)
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(EmberColors.ember)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(hex: "#FFF4EC")))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(GalleryPalette.title)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundColor(GalleryPalette.subtitle)
                    }

                    Spacer()

                    if unlocked {
                        if item.id == "glow" {
                            Button(sparksManager.glowEnabled ? "On" : "Off") {
                                sparksManager.toggleGlow()
                            }
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(sparksManager.glowEnabled ? EmberColors.ember : EmberColors.muted))
                        } else if item.id.hasPrefix("nameplate_") {
                            let active = sparksManager.activeNameplateId == item.id
                            Button(active ? "Active" : "Use") {
                                sparksManager.selectNameplate(active ? nil : item.id)
                            }
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(active ? EmberColors.gold : EmberColors.ember))
                        } else {
                            Text("Owned")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(GalleryPalette.subtitle)
                        }
                    } else {
                        Button {
                            _ = sparksManager.unlockCosmetic(item.id)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: item.currency == .crystals ? "diamond.fill" : "circle.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text("\(item.price)")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(EmberColors.ember))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                )
            }
        }
    }
}

private struct ShopCosmeticRow: View {
    let item: CosmeticShopItem
    let isOwned: Bool
    let isActive: Bool
    let onBuy: () -> Void
    let onUse: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(EmberColors.ember)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color(hex: "#FFF4EC")))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(GalleryPalette.title)
                Text(item.detail)
                    .font(.caption)
                    .foregroundColor(GalleryPalette.subtitle)
            }

            Spacer(minLength: 8)

            if isOwned {
                Button(isActive ? "Active" : "Use") {
                    onUse()
                }
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(isActive ? EmberColors.gold : EmberColors.ember))
            } else if item.price <= 0 {
                Button("Claim") {
                    onBuy()
                }
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(EmberColors.ember))
            } else {
                Button(action: onBuy) {
                    HStack(spacing: 4) {
                        Image(systemName: item.currency == .crystals ? "diamond.fill" : "circle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(item.price)")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(EmberColors.ember))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
    }
}

struct AvatarThumbnail: View {
    let style: AvatarStyle
    let isSelected: Bool
    let level: Int
    var isLocked: Bool = false
    var price: Int = 100
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(hex: style.auraColor).opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(isSelected ? GalleryPalette.accent : Color.clear, lineWidth: 2.5)
                        )
                        .shadow(
                            color: Color(hex: style.auraColor).opacity(isSelected ? 0.35 : 0.18),
                            radius: isSelected ? 10 : 6,
                            y: 2
                        )

                    EmberFlameAvatar(level: level, size: 56, style: style)

                    if isSelected && !isLocked {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, GalleryPalette.accent)
                                    .padding(6)
                            }
                            Spacer()
                        }
                    }

                    if isLocked {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 8, weight: .bold))
                                    Text("\(price)")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(GalleryPalette.price))
                                .padding(5)
                            }
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)

                Text(style.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? GalleryPalette.title : GalleryPalette.subtitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(height: 28)
            }
        }
        .buttonStyle(GalleryCardPressStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [style.name]
        if isSelected { parts.append("selected") }
        if isLocked { parts.append("locked, \(price) Coins") }
        return parts.joined(separator: ", ")
    }
}

/// Press scale without a competing DragGesture (which steals pans from ScrollView).
private struct GalleryCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    AvatarPickerView()
        .environmentObject(AvatarManager())
        .environmentObject(LevelManager())
        .environmentObject(SparksManager())
        .environmentObject(CompanionManager())
}
