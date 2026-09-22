import SwiftUI
import StoreKit

struct SparksShopView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sparksManager: SparksManager
    @StateObject private var store = SparksShopStore()

    var body: some View {
        ZStack {
            GalleryPalette.sky.ignoresSafeArea()

            VStack(spacing: 0) {
                galleryHeader(
                    title: "Sparks Shop",
                    onBack: { dismiss() },
                    onDone: { dismiss() }
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        galleryBalanceBar(
                            balance: sparksManager.balance,
                            onInfo: nil
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Get more Sparks")
                                .font(.title2.weight(.bold))
                                .foregroundColor(GalleryPalette.title)
                            Text("Unlock rare companions and cosmetic flair. Sparks never gate tracking.")
                                .font(.subheadline)
                                .foregroundColor(GalleryPalette.subtitle)
                        }

                        availabilityBanner

                        VStack(spacing: 12) {
                            ForEach(SparksManager.sparkPacks) { pack in
                                SparkPackRow(
                                    pack: pack,
                                    product: store.product(for: pack),
                                    isPurchasing: store.purchasingProductID == pack.productID
                                ) {
                                    Task { await store.purchase(pack) }
                                }
                            }
                        }

                        Text("Buying never grants Sparks unless Apple confirms the purchase. Placeholder prices are not charges.")
                            .font(.caption)
                            .foregroundColor(GalleryPalette.subtitle)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }

            if let toast = sparksManager.toast ?? store.statusMessage {
                VStack {
                    Text(toast)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(EmberColors.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(
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
                .onTapGesture { store.statusMessage = nil }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: sparksManager.toast)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: store.statusMessage)
        .task {
            store.bind(sparksManager)
            await store.loadProducts()
        }
    }

    @ViewBuilder
    private var availabilityBanner: some View {
        if store.isLoading {
            HStack(spacing: 8) {
                ProgressView()
                Text("Loading App Store prices…")
                    .font(.caption)
                    .foregroundColor(GalleryPalette.subtitle)
            }
        } else if store.storeProducts.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(GalleryPalette.accent)
                Text("In-app purchases aren’t available on this build. Packs are listed so you can see the tiers — buy stays disabled until App Store products are configured.")
                    .font(.caption)
                    .foregroundColor(GalleryPalette.subtitle)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
            )
        }
    }
}

private struct SparkPackRow: View {
    let pack: SparkPack
    let product: Product?
    let isPurchasing: Bool
    let onBuy: () -> Void

    private var canBuy: Bool { product != nil && !isPurchasing }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GalleryPalette.accent.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: pack.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(GalleryPalette.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(pack.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(GalleryPalette.title)
                    if let badge = pack.badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(badgeFill))
                    }
                }
                Text("\(pack.sparks.formatted()) Sparks")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(EmberColors.ember)
                Text(pack.detail)
                    .font(.caption)
                    .foregroundColor(GalleryPalette.subtitle)
            }

            Spacer(minLength: 8)

            Button(action: onBuy) {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else if let product {
                        Text(product.displayPrice)
                    } else {
                        Text(pack.placeholderPrice)
                    }
                }
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(canBuy ? GalleryPalette.accent : GalleryPalette.accent.opacity(0.4))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canBuy)
            .accessibilityLabel(canBuy ? "Buy \(pack.name) for \(product?.displayPrice ?? pack.placeholderPrice)" : "\(pack.name) unavailable")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 3)
        )
    }

    private var badgeFill: Color {
        switch pack.badge {
        case "Best Value": return EmberColors.ember
        case "Mega": return Color(hex: "#7c3aed")
        default: return GalleryPalette.accent
        }
    }
}

#Preview {
    SparksShopView()
        .environmentObject(SparksManager())
}
