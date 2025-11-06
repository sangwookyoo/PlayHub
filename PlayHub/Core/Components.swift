import SwiftUI

struct DeviceStateIndicator: View {
    let state: DeviceState
    
    var body: some View {
        HStack(spacing: StyleGuide.Spacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(state.localizedKey.loc())
                .font(StyleGuide.Typography.caption)
                .foregroundStyle(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .booted: return StyleGuide.Color.success
        case .shutdown: return StyleGuide.Color.textTertiary
        case .booting, .shutting_down: return StyleGuide.Color.warning
        case .unknown: return StyleGuide.Color.info
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(StyleGuide.Typography.title)
            Text(title)
                .font(StyleGuide.Typography.title)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        LabeledContent(label, value: value)
    }
}

struct PlatformSelectionCard: View {
    let platform: Platform
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: platform == .iOS ? StyleGuide.Icon.iOS : StyleGuide.Icon.android)
                    .font(.largeTitle)
                    .foregroundStyle(platform == .iOS ? StyleGuide.Color.platformIOS : StyleGuide.Color.platformAndroid)
                Text(platform.displayName)
            }
            .padding()
            .background(isSelected ? StyleGuide.Color.accent.opacity(0.1) : StyleGuide.Color.surface)
            .cornerRadius(StyleGuide.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                    .stroke(isSelected ? StyleGuide.Color.accent : StyleGuide.Color.outline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DeviceListRow: View {
    let device: Device
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: StyleGuide.Spacing.lg) {
            ZStack {
                Circle()
                    .fill((device.type == .iOS ? StyleGuide.Color.platformIOS : StyleGuide.Color.platformAndroid).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: device.type == .iOS ? StyleGuide.Icon.iOS : StyleGuide.Icon.android)
                    .foregroundStyle(device.type == .iOS ? StyleGuide.Color.platformIOS : StyleGuide.Color.platformAndroid)
                    .font(.system(size: 18, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                HStack {
                    Text(device.name)
                        .font(StyleGuide.Typography.body.weight(isSelected ? .semibold : .medium))
                        .foregroundStyle(StyleGuide.Color.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if let version = versionLabel {
                        Text(version)
                            .font(StyleGuide.Typography.caption)
                            .foregroundStyle(StyleGuide.Color.textSecondary)
                    }
                }
                
                HStack(spacing: StyleGuide.Spacing.sm) {
                    StatusDot(color: stateColor)
                    Text(device.state.localizedKey.loc())
                        .font(StyleGuide.Typography.caption)
                        .foregroundStyle(StyleGuide.Color.textSecondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "chevron.right")
                    .foregroundStyle(StyleGuide.Color.textSecondary.opacity(0.6))
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(.horizontal, StyleGuide.Spacing.md)
        .padding(.vertical, StyleGuide.Spacing.sm)
        .contentShape(Rectangle()) // Makes entire row clickable
    }
    
    private var versionLabel: String? {
        if let osVersion = device.osVersion, !osVersion.isEmpty {
            if device.type == .android {
                return "device.version.android".locf(osVersion)
            } else {
                return osVersion
            }
        }
        if device.type == .android, let api = device.attributes["apiLevel"], !api.isEmpty {
            return "device.version.api".locf(api)
        }
        return nil
    }
    
    private var stateColor: Color {
        switch device.state {
        case .booted: return StyleGuide.Color.success
        case .shutdown: return StyleGuide.Color.textTertiary
        case .booting, .shutting_down: return StyleGuide.Color.warning
        case .unknown: return StyleGuide.Color.info
        }
    }
}

private struct StatusDot: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}
