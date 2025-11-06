import SwiftUI

private let accentGlowShadow = Shadow(
    color: DesignSystem.Colors.primary.opacity(0.3),
    radius: 12,
    x: 0,
    y: 6
)

/// `StyleGuide` is the entry-point for the revamped design system.
/// It wraps existing `DesignSystem` tokens to provide a future-proof layer
/// that can evolve independently while keeping the current UI functional.
enum StyleGuide {
    
    enum Color {
        static let canvas = DesignSystem.Colors.background
        static let surface = DesignSystem.Colors.surface
        static let surfaceSecondary = DesignSystem.Colors.surfaceSecondary
        static let surfaceRaised = DesignSystem.Colors.surfaceElevated
        static let surfaceMuted = DesignSystem.Colors.surfaceSecondary
        static let backgroundSecondary = DesignSystem.Colors.backgroundSecondary
        static let outline = DesignSystem.Colors.border
        static let outlineMuted = DesignSystem.Colors.border.opacity(0.5)
        static let accent = DesignSystem.Colors.primary
        static let accentMuted = DesignSystem.Colors.primaryLight
        static let textPrimary = DesignSystem.Colors.textPrimary
        static let textSecondary = DesignSystem.Colors.textSecondary
        static let textTertiary = DesignSystem.Colors.textTertiary
        static let success = DesignSystem.Colors.success
        static let warning = DesignSystem.Colors.warning
        static let error = DesignSystem.Colors.error
        static let info = DesignSystem.Colors.info
        static let successBackground = DesignSystem.Colors.successBackground
        static let warningBackground = DesignSystem.Colors.warningBackground
        static let errorBackground = DesignSystem.Colors.errorBackground
        static let infoBackground = DesignSystem.Colors.infoBackground
        static let platformIOS = DesignSystem.Colors.iOS
        static let platformAndroid = DesignSystem.Colors.android
    }

    enum Gradient {
        static let accent = LinearGradient(
            gradient: SwiftUI.Gradient(colors: [
                StyleGuide.Color.accent.opacity(0.85),
                StyleGuide.Color.accent
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    enum Typography {
        static let display = DesignSystem.Typography.displaySmall
        static let title = DesignSystem.Typography.title3
        static let titleLarge = DesignSystem.Typography.title2
        static let titleEmphasized = DesignSystem.Typography.title3.weight(.semibold)
        static let headline = DesignSystem.Typography.headline
        static let body = DesignSystem.Typography.body
        static let bodyEmphasized = DesignSystem.Typography.body.weight(.semibold)
        static let callout = DesignSystem.Typography.callout
        static let caption = DesignSystem.Typography.caption1
        static let footnote = DesignSystem.Typography.footnote
        static let subheadline = DesignSystem.Typography.subheadline
        static let button = DesignSystem.Typography.button
    }
    
    enum Spacing {
        static let xxs = DesignSystem.Spacing.xxs
        static let xs = DesignSystem.Spacing.xs
        static let sm = DesignSystem.Spacing.sm
        static let md = DesignSystem.Spacing.md
        static let lg = DesignSystem.Spacing.lg
        static let xl = DesignSystem.Spacing.xl
        static let xxl = DesignSystem.Spacing.xxl
        static let xxxl = DesignSystem.Spacing.xxxl
        static let xxxxl = DesignSystem.Spacing.xxxxl
        static let card = DesignSystem.Spacing.cardPadding
        static let section = DesignSystem.Spacing.sectionSpacing
        static let element = DesignSystem.Spacing.elementSpacing
        static let item = DesignSystem.Spacing.itemSpacing
    }
    
    enum Radius {
        static let sm = DesignSystem.CornerRadius.sm
        static let md = DesignSystem.CornerRadius.md
        static let lg = DesignSystem.CornerRadius.lg
        static let xl = DesignSystem.CornerRadius.xl
        static let xxl = DesignSystem.CornerRadius.xxl
        static let card = DesignSystem.CornerRadius.card
        static let button = DesignSystem.CornerRadius.button
        static let sheet = DesignSystem.CornerRadius.sheet
    }
    
    enum Animation {
        static let quick = DesignSystem.Animation.quick
        static let standard = DesignSystem.Animation.standard
        static let subtle = DesignSystem.Animation.fade
        static let gentle = DesignSystem.Animation.gentle
        static let fade = DesignSystem.Animation.fade
    }
    
    enum Shadow {
        static let none = DesignSystem.Shadows.none
        static let card = DesignSystem.Shadows.card
        static let button = DesignSystem.Shadows.button
        static let accentGlow = accentGlowShadow
    }
    
    enum Icon {
        static let device = DesignSystem.Icons.device
        static let settings = DesignSystem.Icons.settings
        static let close = DesignSystem.Icons.close
        static let info = DesignSystem.Icons.info
        static let success = DesignSystem.Icons.success
        static let warning = DesignSystem.Icons.warning
        static let error = DesignSystem.Icons.error
        static let refresh = DesignSystem.Icons.refresh
        static let browse = DesignSystem.Icons.browse
        static let boot = DesignSystem.Icons.boot
        static let shutdown = DesignSystem.Icons.shutdown
        static let restart = DesignSystem.Icons.restart
        static let delete = DesignSystem.Icons.delete
        static let iOS = DesignSystem.Icons.iOS
        static let android = DesignSystem.Icons.android
        static let folder = DesignSystem.Icons.folder
        static let search = DesignSystem.Icons.search
        static let add = DesignSystem.Icons.add
    }
    
    enum Opacity {
        static let subtle = DesignSystem.Opacity.subtle
        static let light = DesignSystem.Opacity.light
        static let medium = DesignSystem.Opacity.medium
        static let strong = DesignSystem.Opacity.strong
    }
    
    enum Layout {
        static let sidebarWidth = DesignSystem.Layout.sidebarWidth
        static let preferredHitArea = DesignSystem.Layout.preferredHitArea
    }
}
