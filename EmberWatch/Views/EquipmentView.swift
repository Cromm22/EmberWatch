import SwiftUI

/// Inventory by slot.
struct EquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var companionManager: CompanionManager
    @EnvironmentObject var sparksManager: SparksManager
    @EnvironmentObject var levelManager: LevelManager

    @State private var selectedSlot: EquipmentSlot = .head

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
                                onAction: { handle(item) }
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

    private func handle(_ item: EquipmentItem) {
        if companionManager.isItemOwned(item.id) {
            companionManager.toggleEquip(item)
            return
        }
        if companionManager.purchaseEquipment(item, wallet: sparksManager, level: levelManager.level) {
            companionManager.equip(item)
        }
    }
}

private struct EquipmentRow: View {
    let item: EquipmentItem
    let isOwned: Bool
    let isEquipped: Bool
    let canUnlockFree: Bool
    let onAction: () -> Void

    var body: some View {
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

            Button(action: onAction) {
                Text(buttonTitle)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(buttonFill))
            }
            .buttonStyle(.plain)
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

    private var buttonTitle: String {
        if isEquipped { return "Unequip" }
        if isOwned { return "Equip" }
        if canUnlockFree { return "Claim" }
        if item.currency == .crystals {
            return "\(item.price)"
        }
        return "\(item.price)"
    }

    private var buttonFill: Color {
        if isEquipped { return EmberColors.muted }
        if isOwned || canUnlockFree { return EmberColors.ember }
        return item.currency == .crystals ? EmberColors.ember : GalleryPalette.price
    }
}
