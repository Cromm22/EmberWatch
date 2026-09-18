import SwiftUI

/// Shared layout for celebration toasts that sit above the tab bar.
enum CelebrationToastLayout {
    /// Standard `UITabBar` item-row height. The home indicator is handled by safe-area padding.
    static let tabBarHeight: CGFloat = 49
    static let gapAboveTabBar: CGFloat = 10
    static let horizontalPadding: CGFloat = 16
    
    static var bottomInset: CGFloat { tabBarHeight + gapAboveTabBar }
}

/// Compact, non-blocking toast chrome used by Ember talk, level-up, and similar celebrations.
struct CelebrationToastCard<Content: View>: View {
    var accent: Color
    var secondaryAccent: Color? = nil
    @ViewBuilder var content: () -> Content
    
    init(accent: Color, secondaryAccent: Color? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.accent = accent
        self.secondaryAccent = secondaryAccent
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent, secondaryAccent ?? accent.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: accent.opacity(0.45), radius: 14, y: 6)
                    .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// Bottom padding for a celebration toast.
/// Set `sitsOutsideTabView` when the toast is a sibling of `TabView` (or higher)
/// so it clears the tab bar. In-tab views are already inset and only need a gap.
/// Pair with `.overlay(alignment: .bottom)` so the toast does not block the UI.
struct CelebrationToastAnchor<Content: View>: View {
    var sitsOutsideTabView: Bool = false
    @ViewBuilder var content: () -> Content
    
    init(sitsOutsideTabView: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.sitsOutsideTabView = sitsOutsideTabView
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(.horizontal, CelebrationToastLayout.horizontalPadding)
            .padding(.bottom, sitsOutsideTabView ? CelebrationToastLayout.bottomInset : CelebrationToastLayout.gapAboveTabBar)
    }
}
