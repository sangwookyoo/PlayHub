import SwiftUI

struct AdvancedFeaturesView: View {
    let device: Device
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: AdvancedTab
    @State private var batteryLevel: Double = 85
    @State private var isCharging = false
    @State private var latitude: String = "37.5665"
    @State private var longitude: String = "126.9780"
    
    enum AdvancedTab: String, CaseIterable, Identifiable {
        case battery, location
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .battery: return "advanced.tab.battery.title".loc()
            case .location: return "advanced.tab.location.title".loc()
            }
        }
        
        var subtitle: String {
            switch self {
            case .battery: return "advanced.tab.battery.subtitle".loc()
            case .location: return "advanced.tab.location.subtitle".loc()
            }
        }
        
        var icon: String {
            switch self {
            case .battery: return "battery.100"
            case .location: return "location.fill"
            }
        }
        
        var tint: Color {
            switch self {
            case .battery: return DesignSystem.Colors.success
            case .location: return DesignSystem.Colors.info
            }
        }
    }
    
    init(device: Device, initialTab: AdvancedTab = .battery) {
        self.device = device
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .background(DesignSystem.Colors.border.opacity(0.5))
            content
            Divider()
                .background(DesignSystem.Colors.border.opacity(0.5))
            footer
        }
        .frame(width: 960, height: 640)
        .background(StyleGuide.Color.canvas)
    }
    
    private var header: some View {
        HStack(spacing: DesignSystem.Spacing.xl) {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            selectedTab.tint.opacity(0.85),
                            selectedTab.tint
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: selectedTab.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: selectedTab.tint.opacity(0.25), radius: 12, x: 0, y: 6)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("advanced.header.title".loc())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text("advanced.header.subtitle".locf(device.name))
                    .font(DesignSystem.Typography.callout.weight(.medium))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .buttonStyle(StableButtonStyle())
            .minHitArea()
        }
        .padding(.horizontal, DesignSystem.Spacing.xxxl)
        .padding(.vertical, DesignSystem.Spacing.xxl)
        .background(DesignSystem.Colors.surface.opacity(0.95))
    }
    
    private var content: some View {
        HStack(spacing: DesignSystem.Spacing.xxl) {
            sidebar
            Divider()
                .background(DesignSystem.Colors.border.opacity(0.4))
                .padding(.vertical, DesignSystem.Spacing.xl)
            detail
        }
        .padding(.horizontal, DesignSystem.Spacing.xxxl)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            ForEach(AdvancedTab.allCases) { tab in
                Button {
                    withAnimation(DesignSystem.Animation.quick) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(tab == selectedTab ? tab.tint : DesignSystem.Colors.textSecondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(tab.title)
                                .font(DesignSystem.Typography.callout.weight(.semibold))
                                .foregroundStyle(tab == selectedTab ? tab.tint : DesignSystem.Colors.textPrimary)
                            Text(tab.subtitle)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        if tab == selectedTab {
                            Image(systemName: DesignSystem.Icons.success)
                                .foregroundStyle(tab.tint)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(
                                tab == selectedTab
                                ? tab.tint.opacity(DesignSystem.Opacity.subtle)
                                : Color.clear
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(
                                tab == selectedTab
                                ? tab.tint.opacity(DesignSystem.Opacity.light)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(StableButtonStyle())
                .minHitArea()
            }
            
            Spacer()
        }
        .frame(width: 280, alignment: .leading)
    }
    
    private var detail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(selectedTab.title)
                        .font(DesignSystem.Typography.title3.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(selectedTab.subtitle)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                
                featureContent(for: selectedTab)
            }
            .padding(.vertical, DesignSystem.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var footer: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Text("advanced.footer.note".loc())
                .font(DesignSystem.Typography.caption1)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Button("common.close".loc()) {
                dismiss()
            }
            .buttonStyle(StableBorderedButtonStyle())
            .minHitArea()
        }
        .padding(.horizontal, DesignSystem.Spacing.xxxl)
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
    
    @ViewBuilder
    private func featureContent(for tab: AdvancedTab) -> some View {
        switch tab {
        case .battery:
            batteryControls
        case .location:
            locationControls
        }
    }
    
    private var batteryControls: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.xxxl) {
                BatteryPreview(level: batteryLevel, isCharging: isCharging)
                    .frame(width: 180, height: 180)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("advanced.battery.level".loc())
                            .font(DesignSystem.Typography.callout.weight(.medium))
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        
                        Slider(value: $batteryLevel, in: 0...100, step: 1)
                            .tint(DesignSystem.Colors.success)
                        
                        Text("format.percent".locf(Int(batteryLevel)))
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    
                    Toggle(isOn: $isCharging) {
                        Label("advanced.battery.charging.label".loc(), systemImage: "bolt.fill")
                    }
                    .toggleStyle(.switch)
                    .tint(DesignSystem.Colors.success)
                }
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                actionIconButton(
                    tint: DesignSystem.Colors.success,
                    systemImage: "checkmark.circle.fill",
                    accessibilityLabel: "advanced.battery.accessibility.apply".loc()
                ) {
                    // Hook up to AdvancedFeaturesService once available.
                }
                
                Button {
                    withAnimation(DesignSystem.Animation.quick) {
                        batteryLevel = 100
                        isCharging = false
                    }
                } label: {
                    Text("common.reset".loc())
                        .font(DesignSystem.Typography.button)
                        .frame(minWidth: 100)
                }
                .buttonStyle(StableBorderedButtonStyle())
                .minHitArea()
            }
        }
        .padding(DesignSystem.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .fill(DesignSystem.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
        .frame(minHeight: 260)
        .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
    }
    
    private var locationControls: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
            HStack(spacing: DesignSystem.Spacing.lg) {
                locationField(title: "advanced.location.latitude".loc(), value: $latitude, icon: "globe.asia.australia.fill")
                    .frame(maxWidth: .infinity)
                locationField(title: "advanced.location.longitude".loc(), value: $longitude, icon: "location.north.line")
                    .frame(maxWidth: .infinity)
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                actionIconButton(
                    tint: DesignSystem.Colors.info,
                    systemImage: "checkmark.circle.fill",
                    accessibilityLabel: "advanced.location.accessibility.apply".loc()
                ) {
                    // Hook up to AdvancedFeaturesService once available.
                }
                
                Button {
                    withAnimation(DesignSystem.Animation.quick) {
                        latitude = "37.5665"
                        longitude = "126.9780"
                    }
                } label: {
                    Text("common.reset".loc())
                        .font(DesignSystem.Typography.button)
                        .frame(minWidth: 100)
                }
                .buttonStyle(StableBorderedButtonStyle())
                .minHitArea()
            }
        }
        .padding(DesignSystem.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .fill(DesignSystem.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
        .frame(minHeight: 260)
        .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
    }
    
    private func locationField(title: String, value: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.callout.weight(.medium))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(DesignSystem.Colors.primary)
#if canImport(UIKit)
                TextField(title, text: value)
                    .textFieldStyle(.plain)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.numbersAndPunctuation)
#else
                TextField(title, text: value)
                    .textFieldStyle(.plain)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
#endif
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                    .fill(DesignSystem.Colors.surfaceSecondary.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                    .stroke(DesignSystem.Colors.border.opacity(0.4), lineWidth: 1)
            )
        }
    }
    
}

private func actionIconButton(
    tint: Color,
    systemImage: String,
    accessibilityLabel: String,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        ZStack {
            Circle()
                .fill(tint.opacity(0.18))
            Circle()
                .stroke(tint.opacity(0.35), lineWidth: 1)
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 44, height: 44)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(accessibilityLabel)
    .minHitArea()
}

private struct BatteryPreview: View {
    let level: Double
    let isCharging: Bool
    
    private var sweep: CGFloat { CGFloat(level / 100) }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .foregroundStyle(DesignSystem.Colors.surfaceSecondary.opacity(0.5))
            
            Circle()
                .trim(from: 0, to: sweep)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            DesignSystem.Colors.success,
                            DesignSystem.Colors.success.opacity(0.6)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("format.percent".locf(Int(level)))
                    .font(DesignSystem.Typography.title3.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
    }
}

#if DEBUG && canImport(SwiftUI) && !os(macOS)
#Preview {
    AdvancedFeaturesView(device: Device(
        id: UUID(),
        name: "iPhone 15 Pro",
        type: .iOS,
        udid: "test-udid",
        state: .booted,
        isAvailable: true,
        osVersion: "iOS 17.5",
        deviceModel: "D83AP",
        attributes: [:]
    ))
}
#endif
