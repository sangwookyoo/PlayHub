
import SwiftUI

/// PlayHub Design System - A unified design language for a consistent and accessible user interface.
/// This system provides a comprehensive set of styles, components, and utilities that adhere to the
/// macOS Human Interface Guidelines (HIG), ensuring the app feels native and intuitive.
///
/// Enhanced version with improved consistency, better dark mode support, and expanded color palette.
struct DesignSystem {
    
    // MARK: - Color System
    
    /// A semantic and adaptive color palette that automatically responds to light and dark modes.
    /// Enhanced with better consistency and more semantic naming.
    struct Colors {
        
        // MARK: - Primary & Accent
        static let primary = Color.accentColor
        static let primaryVariant = Color.accentColor.opacity(0.8)
        static let primaryLight = Color.accentColor.opacity(0.6)
        static let primaryDark = Color.accentColor.opacity(0.9)
        
        // MARK: - Backgrounds
        static let background = Color(nsColor: .windowBackgroundColor)
        static let backgroundSecondary = Color(nsColor: .underPageBackgroundColor)
        static let surface = Color(nsColor: .controlBackgroundColor)
        static let surfaceSecondary = Color(nsColor: .controlBackgroundColor)
        static let surfaceElevated = Color(nsColor: .controlBackgroundColor).opacity(0.8)
        
        // MARK: - Text Colors
        static let textPrimary = Color(nsColor: .labelColor)
        static let textSecondary = Color(nsColor: .secondaryLabelColor)
        static let textTertiary = Color(nsColor: .tertiaryLabelColor)
        static let textQuaternary = Color(nsColor: .quaternaryLabelColor)
        static let textDisabled = Color(nsColor: .disabledControlTextColor)
        static let textInverse = Color(nsColor: .alternateSelectedControlTextColor)
        
        // MARK: - Borders & Separators
        static let border = Color(nsColor: .separatorColor)
        static let borderSecondary = Color(nsColor: .gridColor)
        static let borderLight = Color(nsColor: .separatorColor).opacity(0.5)
        static let borderStrong = Color(nsColor: .separatorColor).opacity(1.2)
        
        // MARK: - Interactive Colors
        static let interactive = Color.accentColor
        static let interactiveHover = Color.accentColor.opacity(0.8)
        static let interactivePressed = Color.accentColor.opacity(0.6)
        static let interactiveDisabled = Color(nsColor: .disabledControlTextColor)
        
        // MARK: - Semantic Colors
        static let success = Color.green
        static let successLight = Color.green.opacity(0.7)
        static let successBackground = Color.green.opacity(0.1)
        
        static let warning = Color.orange
        static let warningLight = Color.orange.opacity(0.7) 
        static let warningBackground = Color.orange.opacity(0.1)
        
        static let error = Color.red
        static let errorLight = Color.red.opacity(0.7)
        static let errorBackground = Color.red.opacity(0.1)
        
        static let info = Color.blue
        static let infoLight = Color.blue.opacity(0.7)
        static let infoBackground = Color.blue.opacity(0.1)
        
        // MARK: - Platform Colors
        static let iOS = Color.blue
        static let iOSLight = Color.blue.opacity(0.7)
        static let iOSBackground = Color.blue.opacity(0.1)
        
        static let android = Color.green
        static let androidLight = Color.green.opacity(0.7)
        static let androidBackground = Color.green.opacity(0.1)
        
        // MARK: - Status Colors
        static let online = Color.green
        static let offline = Color.gray
        static let pending = Color.orange
        static let unknown = Color.purple
    }
    
    // MARK: - Enhanced Typography System
    
    /// A comprehensive typography system with better hierarchy and consistency.
    struct Typography {
        // Display styles
        static let displayLarge = Font.system(size: 36, weight: .bold, design: .default)
        static let displayMedium = Font.system(size: 32, weight: .bold, design: .default)
        static let displaySmall = Font.system(size: 28, weight: .bold, design: .default)
        
        // Title styles  
        static let largeTitle = Font.largeTitle
        static let title1 = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        
        // Body styles
        static let headline = Font.headline
        static let body = Font.body
        static let bodyEmphasized = Font.body.weight(.semibold)
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        
        // Supporting styles
        static let footnote = Font.footnote
        static let caption1 = Font.caption
        static let caption2 = Font.caption2
        
        // Special purpose
        static let code = Font.system(.body, design: .monospaced)
        static let codeSmall = Font.system(.callout, design: .monospaced)
        static let button = Font.body.weight(.medium)
        static let buttonSmall = Font.callout.weight(.medium)
    }
    
    // MARK: - Enhanced Spacing System
    
    /// An expanded 4pt grid-based spacing scale for more granular control.
    struct Spacing {
        static let none: CGFloat = 0
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        static let xxxxl: CGFloat = 64
        
        // Component-specific spacing
        static let cardPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 32
        static let elementSpacing: CGFloat = 16
        static let itemSpacing: CGFloat = 8
    }
    
    // MARK: - Enhanced Corner Radius System
    
    /// Expanded corner radius system for better visual consistency.
    struct CornerRadius {
        static let none: CGFloat = 0
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
        
        // Component-specific radii
        static let button: CGFloat = 8
        static let card: CGFloat = 12
        static let sheet: CGFloat = 16
        static let badge: CGFloat = 20
    }
    
    // MARK: - Enhanced Shadow System
    
    /// Comprehensive shadow system for better visual hierarchy.
    struct Shadows {
        // Elevation shadows
        static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        static let sm = Shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        static let md = Shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        static let lg = Shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        static let xl = Shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 12)
        
        // Special purpose shadows
        static let card = Shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        static let button = Shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        static let modal = Shadow(color: .black.opacity(0.15), radius: 32, x: 0, y: 16)
    }
    
    // MARK: - Enhanced Iconography System
    
    /// Expanded library of SF Symbols with better organization.
    struct Icons {
        // Navigation
        static let add = "plus.circle.fill"
        static let back = "chevron.left"
        static let forward = "chevron.right"
        static let close = "xmark"
        static let menu = "line.3.horizontal"
        static let more = "ellipsis.circle"
        
        // Actions
        static let settings = "gearshape.fill"
        static let search = "magnifyingglass"
        static let filter = "line.3.horizontal.decrease.circle"
        static let refresh = "arrow.clockwise"
        static let edit = "pencil"
        static let copy = "doc.on.doc"
        static let share = "square.and.arrow.up"
        
        // Device actions
        static let boot = "power"
        static let shutdown = "poweroff"
        static let restart = "arrow.clockwise.circle"
        static let delete = "trash.fill"
        
        // Information
        static let logs = "doc.text.fill"
        static let info = "info.circle.fill"
        static let warning = "exclamationmark.triangle.fill"
        static let error = "xmark.octagon.fill"
        static let success = "checkmark.circle.fill"
        
        // Devices & Platforms
        static let device = "desktopcomputer"
        static let phone = "iphone"
        static let tablet = "ipad"
        static let iOS = "applelogo"
        static let android = "smartphone" // Changed to a more appropriate symbol
        
        // Advanced features
        static let battery = "battery.100"
        static let location = "location.fill"
        static let camera = "camera.fill"
        static let microphone = "mic.fill"
        static let recording = "record.circle"
        static let screenshot = "camera.shutter.button"
        
        // File operations
        static let folder = "folder"
        static let browse = "folder.badge.plus"
        
        // UI Elements
        static let sidebar = "sidebar.left"
        static let expand = "arrow.up.left.and.arrow.down.right"
        static let collapse = "arrow.down.right.and.arrow.up.left"
        static let fullscreen = "arrow.up.left.and.down.right.magnifyingglass"
    }
    
    // MARK: - Enhanced Gradient System
    
    /// Expanded gradient collection for better visual appeal.
    struct Gradients {
        static let primary = LinearGradient(
            gradient: Gradient(colors: [
                Color.accentColor.opacity(0.8),
                Color.accentColor
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let onboarding = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.47, green: 0.27, blue: 0.98),
                Color(red: 0.37, green: 0.47, blue: 0.99)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let button = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.37, green: 0.47, blue: 0.99),
                Color(red: 0.47, green: 0.27, blue: 0.98)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let success = LinearGradient(
            gradient: Gradient(colors: [
                Color.green.opacity(0.8),
                Color.green
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let error = LinearGradient(
            gradient: Gradient(colors: [
                Color.red.opacity(0.8),
                Color.red
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Enhanced Animation System
    
    /// Comprehensive animation system for consistent motion design.
    struct Animation {
        // Basic animations
        static let instant = SwiftUI.Animation.linear(duration: 0)
        static let quick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let standard = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let gentle = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let slow = SwiftUI.Animation.spring(response: 0.7, dampingFraction: 0.8)
        
        // Specialized animations
        static let bounce = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.4)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let snappy = SwiftUI.Animation.interpolatingSpring(stiffness: 300, damping: 30)
        
        // Transition animations
        static let slideIn = SwiftUI.Animation.easeOut(duration: 0.4)
        static let slideOut = SwiftUI.Animation.easeIn(duration: 0.3)
        static let fade = SwiftUI.Animation.easeInOut(duration: 0.25)
    }
    
    // MARK: - Enhanced Layout System
    
    /// Expanded layout constants for better consistency.
    struct Layout {
        // Button dimensions
        static let buttonHeight: CGFloat = 40
        static let buttonHeightSmall: CGFloat = 32
        static let buttonHeightLarge: CGFloat = 48
        static let buttonMinWidth: CGFloat = 80
        
        // Input dimensions
        static let inputHeight: CGFloat = 36
        static let inputHeightLarge: CGFloat = 44
        
        // Panel dimensions
        static let sidebarWidth: CGFloat = 400
        static let sidebarWidthCollapsed: CGFloat = 60
        static let detailPanelWidth: CGFloat = 320
        static let inspectorWidth: CGFloat = 260
        
        // Card dimensions
        static let cardMaxWidth: CGFloat = 480
        static let cardMinHeight: CGFloat = 120
        
        // Grid dimensions
        static let gridItemMinWidth: CGFloat = 200
        static let gridItemMaxWidth: CGFloat = 300
        
        // Hit areas (for better touch/click targets)
        static let minHitArea: CGFloat = 44
        static let preferredHitArea: CGFloat = 48
    }
    
    // MARK: - Opacity System
    
    /// Standardized opacity values for consistent transparency.
    struct Opacity {
        static let invisible: Double = 0
        static let subtle: Double = 0.1
        static let light: Double = 0.2
        static let medium: Double = 0.4
        static let strong: Double = 0.6
        static let heavy: Double = 0.8
        static let opaque: Double = 1.0
        
        // Interactive states
        static let hover: Double = 0.1
        static let pressed: Double = 0.2
        static let disabled: Double = 0.4
    }
}

// MARK: - Enhanced Shadow Structure

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Enhanced View Extensions

extension View {
    
    /// Applies a standardized surface styling with enhanced options.
    func surfaced(elevation: Shadow = DesignSystem.Shadows.card) -> some View {
        self
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .shadow(
                color: elevation.color,
                radius: elevation.radius,
                x: elevation.x,
                y: elevation.y
            )
    }
    
    /// Applies standardized padding with size options.
    func standardPadding(_ padding: CGFloat = DesignSystem.Spacing.lg) -> some View {
        self.padding(padding)
    }
    
    /// Applies card styling with enhanced visual appeal.
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.cardPadding) -> some View {
        self
            .padding(padding)
            .background(StyleGuide.Color.surface)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .shadow(
                color: DesignSystem.Shadows.card.color,
                radius: DesignSystem.Shadows.card.radius,
                x: DesignSystem.Shadows.card.x,
                y: DesignSystem.Shadows.card.y
            )
    }
    
    /// Ensures minimum hit area for better accessibility.
    func minHitArea() -> some View {
        self.frame(minWidth: DesignSystem.Layout.preferredHitArea, 
                  minHeight: DesignSystem.Layout.preferredHitArea)
    }
    
    /// Applies interactive styling with hover effects.
    func interactiveStyle() -> some View {
        self
            .scaleEffect(1.0)
            .animation(DesignSystem.Animation.quick, value: false)
    }
    
    /// Applies stable button styling that prevents text movement.
    func stableButtonStyle() -> some View {
        self
            .buttonStyle(StableButtonStyle())
    }
}

// MARK: - Shared Components

/// Shared accent-styled icon badge used across headers to keep gradient and shadow consistent.
struct AccentIconBadge: View {
    let systemName: String
    var size: CGFloat = 60
    var cornerRadius: CGFloat = StyleGuide.Radius.xl
    var gradient: LinearGradient = StyleGuide.Gradient.accent
    var iconSize: CGFloat = 28
    var iconWeight: Font.Weight = .semibold
    var iconColor: Color = .white
    var shadow: Shadow = StyleGuide.Shadow.accentGlow

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(gradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: iconSize, weight: iconWeight))
                    .foregroundStyle(iconColor)
            )
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - Stable Button Style

/// A button style that prevents text movement and visual jumping on press
struct StableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(StyleGuide.Animation.quick, value: configuration.isPressed)
    }
}

/// A stable prominent button style for primary actions
struct StableProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, StyleGuide.Spacing.lg)
            .padding(.vertical, StyleGuide.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(
                        isEnabled 
                        ? (configuration.isPressed 
                           ? StyleGuide.Color.accent.opacity(0.8) 
                           : StyleGuide.Color.accent)
                        : DesignSystem.Colors.interactiveDisabled
                    )
            )
            .foregroundStyle(
                isEnabled 
                ? .white 
                : DesignSystem.Colors.textDisabled
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(StyleGuide.Animation.quick, value: configuration.isPressed)
    }
}

/// A stable bordered button style for secondary actions
struct StableBorderedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, StyleGuide.Spacing.lg)
            .padding(.vertical, StyleGuide.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(
                        configuration.isPressed 
                        ? StyleGuide.Color.surfaceMuted 
                        : StyleGuide.Color.surface
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(
                        isEnabled 
                        ? StyleGuide.Color.outline 
                        : DesignSystem.Colors.borderLight, 
                        lineWidth: 1
                    )
            )
            .foregroundStyle(
                isEnabled 
                ? StyleGuide.Color.textPrimary 
                : DesignSystem.Colors.textDisabled
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(StyleGuide.Animation.quick, value: configuration.isPressed)
    }
}
