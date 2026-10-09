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

/// Shop wallet pills (Coins / Crystals). File-level so these tokens are not
/// MainActor-isolated with the SwiftUI views.
private enum GalleryBalancePalette {
    static let ink = Color(hex: "#1F1F24")

    static let coinFillTop = Color(hex: "#FFF6DC")
    static let coinFillBottom = Color(hex: "#FDEBC0")
    static let coinBorder = Color(hex: "#F3D58A")
    static let coinGlow = Color(hex: "#F3D58A")
    static let coinRim = Color(hex: "#C07A10")
    static let coinMetalTop = Color(hex: "#F9C94A")
    static let coinMetalBottom = Color(hex: "#E39A17")
    static let coinStarTop = Color(hex: "#FFF6C4")
    static let coinStarBottom = Color(hex: "#E8B830")

    static let crystalFillTop = Color(hex: "#F6EEFF")
    static let crystalFillBottom = Color(hex: "#EBDDFD")
    static let crystalBorder = Color(hex: "#D9C3F7")
    static let crystalGlow = Color(hex: "#D9C3F7")
    static let gemOrange = Color(hex: "#FFB36B")
    static let gemPink = Color(hex: "#F2557A")
    static let gemMagenta = Color(hex: "#C04BD8")
}

private enum GalleryBalanceMetrics {
    static let pillHeight: CGFloat = 44
    static let horizontalPadding: CGFloat = 10
    static let iconTextSpacing: CGFloat = 8
    static let pillSpacing: CGFloat = 12
    static let iconSize: CGFloat = 24
    static let textSize: CGFloat = 15
    static let borderWidth: CGFloat = 1
}

private enum GalleryCurrencyKind {
    case coins
    case crystals
}

/// Live Coins + Crystals wallet. Two capsule pills, centered as a pair.
func galleryBalanceBar(coins: Int, crystals: Int) -> some View {
    HStack(spacing: GalleryBalanceMetrics.pillSpacing) {
        Spacer(minLength: 0)
        GalleryCurrencyPill(
            amountText: XPRules.groupedNumber(max(0, coins)),
            unitText: "Coins",
            kind: .coins
        )
        GalleryCurrencyPill(
            amountText: XPRules.groupedNumber(max(0, crystals)),
            unitText: "Crystals",
            kind: .crystals
        )
        Spacer(minLength: 0)
    }
}

private struct GalleryCurrencyPill: View {
    let amountText: String
    let unitText: String
    let kind: GalleryCurrencyKind

    var body: some View {
        HStack(spacing: GalleryBalanceMetrics.iconTextSpacing) {
            icon
            GalleryCurrencyPillLabel(amountText: amountText, unitText: unitText)
        }
        .padding(.horizontal, GalleryBalanceMetrics.horizontalPadding)
        .frame(height: GalleryBalanceMetrics.pillHeight)
        .background(GalleryCurrencyPillChrome(kind: kind))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(amountText) \(unitText)")
    }

    @ViewBuilder
    private var icon: some View {
        switch kind {
        case .coins:
            GalleryCoinIcon()
        case .crystals:
            GalleryCrystalIcon()
        }
    }
}

private struct GalleryCurrencyPillLabel: View {
    let amountText: String
    let unitText: String

    var body: some View {
        HStack(spacing: 4) {
            Text(amountText)
                .font(.system(size: GalleryBalanceMetrics.textSize, weight: .bold))
                .monospacedDigit()
            Text(unitText)
                .font(.system(size: GalleryBalanceMetrics.textSize, weight: .semibold))
        }
        .foregroundStyle(GalleryBalancePalette.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

private struct GalleryCurrencyPillChrome: View {
    let kind: GalleryCurrencyKind

    var body: some View {
        Capsule()
            .fill(fill)
            .overlay(border)
            .shadow(color: glow, radius: 8, y: 1)
    }

    private var fill: LinearGradient {
        switch kind {
        case .coins:
            return LinearGradient(
                colors: [
                    GalleryBalancePalette.coinFillTop,
                    GalleryBalancePalette.coinFillBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .crystals:
            return LinearGradient(
                colors: [
                    GalleryBalancePalette.crystalFillTop,
                    GalleryBalancePalette.crystalFillBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var border: some View {
        Capsule()
            .strokeBorder(borderColor, lineWidth: GalleryBalanceMetrics.borderWidth)
    }

    private var borderColor: Color {
        switch kind {
        case .coins:
            return GalleryBalancePalette.coinBorder
        case .crystals:
            return GalleryBalancePalette.crystalBorder
        }
    }

    private var glow: Color {
        switch kind {
        case .coins:
            return GalleryBalancePalette.coinGlow.opacity(0.55)
        case .crystals:
            return GalleryBalancePalette.crystalGlow.opacity(0.45)
        }
    }
}

/// Glossy 3D gold coin with an embossed star.
private struct GalleryCoinIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(GalleryBalancePalette.coinRim)
            Circle()
                .fill(metal)
                .padding(1.8)
            gloss
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(starFill)
                .shadow(color: Color.black.opacity(0.22), radius: 0.4, y: 0.5)
        }
        .frame(width: GalleryBalanceMetrics.iconSize, height: GalleryBalanceMetrics.iconSize)
        .accessibilityHidden(true)
    }

    private var metal: LinearGradient {
        LinearGradient(
            colors: [
                GalleryBalancePalette.coinMetalTop,
                GalleryBalancePalette.coinMetalBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var starFill: LinearGradient {
        LinearGradient(
            colors: [
                GalleryBalancePalette.coinStarTop,
                GalleryBalancePalette.coinStarBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var gloss: some View {
        Ellipse()
            .fill(Color.white.opacity(0.48))
            .frame(width: 11, height: 5)
            .offset(x: -1.2, y: -5)
    }
}

/// Faceted orange → pink → magenta gem with white sparkles.
private struct GalleryCrystalIcon: View {
    var body: some View {
        ZStack {
            gemBody
            gemSheen
            facets
            GalleryCrystalSparkles()
        }
        .frame(width: GalleryBalanceMetrics.iconSize, height: GalleryBalanceMetrics.iconSize)
        .accessibilityHidden(true)
    }

    private var gemBody: some View {
        GalleryCrystalGemShape()
            .fill(gemFill)
            .shadow(color: Color.black.opacity(0.14), radius: 0.6, y: 0.6)
    }

    private var gemSheen: some View {
        GalleryCrystalGemShape()
            .fill(sheen)
    }

    private var facets: some View {
        GalleryCrystalFacetLines()
            .stroke(Color.white.opacity(0.38), lineWidth: 0.7)
    }

    private var gemFill: LinearGradient {
        LinearGradient(
            colors: [
                GalleryBalancePalette.gemOrange,
                GalleryBalancePalette.gemPink,
                GalleryBalancePalette.gemMagenta
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var sheen: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.42), Color.white.opacity(0)],
            startPoint: .top,
            endPoint: .center
        )
    }
}

private struct GalleryCrystalGemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: width * 0.50, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.38))
        path.addLine(to: CGPoint(x: width * 0.50, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.38))
        path.closeSubpath()
        return path
    }
}

private struct GalleryCrystalFacetLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let girdleY = height * 0.38
        path.move(to: CGPoint(x: 0, y: girdleY))
        path.addLine(to: CGPoint(x: width, y: girdleY))
        path.move(to: CGPoint(x: width * 0.50, y: 0))
        path.addLine(to: CGPoint(x: width * 0.50, y: height))
        path.move(to: CGPoint(x: width * 0.50, y: 0))
        path.addLine(to: CGPoint(x: width * 0.28, y: girdleY))
        path.move(to: CGPoint(x: width * 0.50, y: 0))
        path.addLine(to: CGPoint(x: width * 0.72, y: girdleY))
        return path
    }
}

private struct GalleryCrystalSparkles: View {
    var body: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 5, weight: .bold))
                .foregroundStyle(Color.white)
                .offset(x: 8, y: -8)
            Image(systemName: "sparkle")
                .font(.system(size: 3.5, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.92))
                .offset(x: -7, y: 6)
        }
        .accessibilityHidden(true)
    }
}

struct AvatarPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var sparksManager: SparksManager
    @EnvironmentObject var companionManager: CompanionManager

    @State private var showingShop = false
    @State private var showingEquipment = false
    @State private var showingCompanionPicker = false
    @State private var showingRename = false
    @State private var nameDraft = ""

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
                            crystals: sparksManager.balance
                        )
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
        .alert("Rename Ember", isPresented: $showingRename) {
            TextField("Name your Ember", text: $nameDraft)
            Button("Save") {
                saveCompanionName()
            }
            Button("Cancel", role: .cancel) {}
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
            Image("CompanionRobot")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(avatarManager.displayName)
                        .font(.headline)
                        .foregroundColor(GalleryPalette.title)
                    Button {
                        nameDraft = avatarManager.emberName
                        showingRename = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(GalleryPalette.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Rename Ember")
                }
                Text(companionManager.resolvedSpecies.displayName)
                    .font(.subheadline)
                    .foregroundColor(GalleryPalette.subtitle)
                Button("Change Companion") {
                    showingCompanionPicker = true
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(GalleryPalette.accent)
                .accessibilityLabel("Change Companion")
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
                    Text("Six slots")
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

    private func saveCompanionName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            avatarManager.emberName = trimmed
        }
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

                    CompanionRobotImage(size: 56)

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
