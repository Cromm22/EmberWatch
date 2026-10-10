import SwiftUI

/// Inventory by slot.
struct EquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var companionManager: CompanionManager
    @EnvironmentObject var sparksManager: SparksManager
    @EnvironmentObject var levelManager: LevelManager
    @EnvironmentObject var avatarManager: AvatarManager
    @EnvironmentObject var characterManager: CharacterManager

    @State private var selectedSlot: EquipmentSlot = .head
    @State private var previewSubject: ShopPreviewSubject?

    var body: some View {
        ZStack {
            GalleryPalette.sky.ignoresSafeArea()

            VStack(spacing: 0) {
                galleryHeader(
                    title: "Equipment",
                    onBack: { dismiss() },
                    onDone: { dismiss() }
                )

                galleryBalanceBar(
                    coins: sparksManager.coins,
                    crystals: sparksManager.balance
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)

                previewCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                slotPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(EquipmentCatalog.items(for: selectedSlot)) { item in
                            EquipmentRow(
                                item: item,
                                isOwned: companionManager.isItemOwned(item.id),
                                isEquipped: companionManager.isEquipped(item.id),
                                canUnlockFree: item.isGranted(atLevel: levelManager.level),
                                onAction: { previewSubject = .equipment(item.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            companionManager.grantFreeUnlocks(level: levelManager.level)
        }
        .sheet(item: $previewSubject) { subject in
            ShopItemPreviewSheet(
                subject: subject,
                look: currentHeroLook.applying(subject),
                isOwned: isPreviewOwned(subject),
                isEquipped: isPreviewEquipped(subject),
                coins: sparksManager.coins,
                crystals: sparksManager.balance,
                onConfirm: { confirmPreview(subject) },
                onCancel: { previewSubject = nil }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var currentHeroLook: HomeHeroLook {
        HomeHeroLook.snapshot(
            avatar: avatarManager,
            companion: companionManager,
            sparks: sparksManager,
            level: levelManager,
            character: characterManager
        )
    }

    private func isPreviewOwned(_ subject: ShopPreviewSubject) -> Bool {
        switch subject {
        case .equipment(let id):
            return companionManager.isItemOwned(id)
        case .cosmetic, .avatar:
            return false
        }
    }

    private func isPreviewEquipped(_ subject: ShopPreviewSubject) -> Bool {
        switch subject {
        case .equipment(let id):
            return companionManager.isEquipped(id)
        case .cosmetic, .avatar:
            return false
        }
    }

    private func confirmPreview(_ subject: ShopPreviewSubject) {
        guard case .equipment(let id) = subject,
              let item = EquipmentCatalog.item(id: id) else { return }
        if handle(item) {
            previewSubject = nil
        }
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            CompanionAvatarView(
                species: companionManager.resolvedSpecies,
                stage: companionManager.stage(forLevel: levelManager.level),
                tier: companionManager.tier(forLevel: levelManager.level),
                size: 96,
                extraGlow: sparksManager.hasGlow,
                equipped: currentEquipped,
                effectId: companionManager.activeEffectId,
                prestigeSkinId: companionManager.activePrestigeSkinId
            )
            .frame(width: 104, height: 116)

            VStack(alignment: .leading, spacing: 6) {
                Text(companionManager.tier(forLevel: levelManager.level).gearLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(GalleryPalette.title)
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

    private var slotPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EquipmentSlot.allCases) { slot in
                    Button {
                        selectedSlot = slot
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: slot.iconName)
                                .font(.caption.weight(.semibold))
                            Text(slot.displayName)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(selectedSlot == slot ? .white : GalleryPalette.title)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(selectedSlot == slot ? GalleryPalette.accent : Color.white)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var currentEquipped: [EquipmentSlot: EquipmentItem] {
        var map: [EquipmentSlot: EquipmentItem] = [:]
        for slot in EquipmentSlot.allCases {
            if let item = companionManager.equippedItem(for: slot) {
                map[slot] = item
            }
        }
        return map
    }

    @discardableResult
    private func handle(_ item: EquipmentItem) -> Bool {
        if companionManager.isItemOwned(item.id) {
            companionManager.equip(item)
            return true
        }
        guard companionManager.purchaseEquipment(
            item,
            wallet: sparksManager,
            level: levelManager.level
        ) else {
            return false
        }
        companionManager.equip(item)
        return true
    }
}

private struct EquipmentRow: View {
    let item: EquipmentItem
    let isOwned: Bool
    let isEquipped: Bool
    let canUnlockFree: Bool
    let onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(item.rarity.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(item.rarity.color, lineWidth: 2)
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: item.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(item.rarity.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(GalleryPalette.title)
                    Text(item.rarity.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(item.rarity.color)
                    Text(item.detail)
                        .font(.caption)
                        .foregroundColor(GalleryPalette.subtitle)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                ShopRowStatusChip(
                    isOwned: isOwned || canUnlockFree,
                    isActive: isEquipped,
                    price: item.price,
                    currency: item.currency
                )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isEquipped ? item.rarity.color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
    }
}
