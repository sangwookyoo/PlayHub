import SwiftUI

struct CreateDeviceView: View {
    @StateObject private var viewModel = CreateDeviceViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // Remove gradient background, use solid background instead
        VStack(spacing: 0) {
            enhancedHeader
            Divider()
                .background(StyleGuide.Color.outline.opacity(0.5))
            enhancedContent
            Divider()
                .background(StyleGuide.Color.outline.opacity(0.5))
            enhancedFooter
        }
        .background(StyleGuide.Color.canvas)
        .frame(width: 700, height: 760)
        .task {
            if viewModel.selectedPlatform == .iOS {
                await viewModel.loadIOSOptions()
            }
        }
        .alert("common.error".loc(), isPresented: $viewModel.showError) {
            Button("common.ok".loc(), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var enhancedHeader: some View {
        HStack(spacing: StyleGuide.Spacing.xl) {
            // App icon with enhanced styling
            AccentIconBadge(
                systemName: "plus.circle.fill",
                size: 60
            )
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                Text("create_device.header.title".loc())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(StyleGuide.Color.textPrimary)
                
                Text("create_device.header.subtitle".loc())
                    .font(StyleGuide.Typography.callout.weight(.medium))
                    .foregroundColor(StyleGuide.Color.textSecondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(StyleGuide.Color.textTertiary)
            }
            .buttonStyle(StableButtonStyle())
            .minHitArea()
        }
        .padding(.horizontal, StyleGuide.Spacing.xxxl)
        .padding(.vertical, StyleGuide.Spacing.xxl)
        .background(
            StyleGuide.Color.surface.opacity(0.95)
        )
    }
    
    private var enhancedContent: some View {
        ScrollView {
            VStack(spacing: StyleGuide.Spacing.xxxl) {
                enhancedPlatformSection
                
                if viewModel.selectedPlatform == .iOS {
                    enhancedIOSConfigSection
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else if viewModel.selectedPlatform == .android {
                    enhancedAndroidGuideSection
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, StyleGuide.Spacing.xxxl)
            .padding(.vertical, StyleGuide.Spacing.xxl)
            .animation(StyleGuide.Animation.standard, value: viewModel.selectedPlatform)
        }
    }
    
    private var enhancedPlatformSection: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xl) {
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                Text("create_device.platform.title".loc())
                    .font(StyleGuide.Typography.title.weight(.semibold))
                    .foregroundColor(StyleGuide.Color.textPrimary)
                Text("create_device.platform.subtitle".loc())
                    .font(StyleGuide.Typography.callout)
                    .foregroundColor(StyleGuide.Color.textSecondary)
            }
            
            HStack(spacing: StyleGuide.Spacing.xl) {
                // Use the existing PlatformSelectionCard but enhanced
                EnhancedPlatformSelectionCard(
                    platform: .iOS,
                    isSelected: viewModel.selectedPlatform == .iOS
                ) {
                    withAnimation(StyleGuide.Animation.standard) {
                        viewModel.selectedPlatform = .iOS
                        Task { await viewModel.loadIOSOptions() }
                    }
                }
                
                EnhancedPlatformSelectionCard(
                    platform: .android,
                    isSelected: viewModel.selectedPlatform == .android
                ) {
                    withAnimation(StyleGuide.Animation.standard) {
                        viewModel.selectedPlatform = .android
                    }
                }
            }
        }
    }
    
    private var enhancedIOSConfigSection: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xl) {
            CreateDeviceSectionHeader(
                title: "create_device.ios.section.title".loc(),
                subtitle: "create_device.ios.section.subtitle".loc(),
                icon: StyleGuide.Icon.iOS,
                tint: StyleGuide.Color.platformIOS
            )
            
            VStack(spacing: StyleGuide.Spacing.lg) {
                EnhancedFormField(
                    title: "create_device.ios.name.title".loc(),
                    placeholder: "create_device.ios.name.placeholder".loc(),
                    text: $viewModel.deviceName,
                    icon: "textformat.abc"
                )
                
                // Left-aligned picker field
                VStack(alignment: .leading, spacing: StyleGuide.Spacing.sm) {
                    HStack(spacing: StyleGuide.Spacing.sm) {
                        Image(systemName: "iphone")
                            .foregroundStyle(StyleGuide.Color.accent)
                        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                            Text("create_device.ios.device_type.title".loc())
                                .font(StyleGuide.Typography.callout.weight(.medium))
                                .foregroundColor(StyleGuide.Color.textPrimary)
                            Text("create_device.ios.device_type.subtitle".loc())
                                .font(StyleGuide.Typography.caption)
                                .foregroundColor(StyleGuide.Color.textSecondary)
                        }
                    }
                    
                    if viewModel.availableDeviceTypes.isEmpty {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                            Text("create_device.ios.device_type.loading".loc())
                                .font(StyleGuide.Typography.callout)
                                .foregroundColor(StyleGuide.Color.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) // Left aligned
                        .padding(StyleGuide.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                                .fill(StyleGuide.Color.surfaceSecondary.opacity(0.8))
                        )
                    } else {
                        Picker("", selection: $viewModel.selectedDeviceType) {
                            Text("create_device.ios.device_type.placeholder".loc()).tag(nil as DeviceType?)
                            ForEach(viewModel.availableDeviceTypes, id: \.self) { deviceType in
                                Text(deviceType.name).tag(deviceType as DeviceType?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading) // Left aligned picker
                        .padding(.horizontal, StyleGuide.Spacing.lg)
                        .padding(.vertical, StyleGuide.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                                .fill(StyleGuide.Color.surfaceSecondary.opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                                .stroke(StyleGuide.Color.outline.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                
                EnhancedPickerField(
                    title: "create_device.ios.runtime.title".loc(),
                    subtitle: "create_device.ios.runtime.subtitle".loc(),
                    icon: "cpu",
                    isEmpty: viewModel.availableRuntimes.isEmpty,
                    isLoading: false
                ) {
                    Picker("", selection: $viewModel.selectedRuntime) {
                        Text("create_device.ios.runtime.placeholder".loc()).tag(nil as Runtime?)
                        ForEach(viewModel.availableRuntimes, id: \.self) { runtime in
                            Text(runtime.name).tag(runtime as Runtime?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .cardStyle()
    }
    
    private var enhancedAndroidGuideSection: some View {
        VStack(spacing: StyleGuide.Spacing.xxxl) {
            CreateDeviceSectionHeader(
                title: "create_device.android.section.title".loc(),
                subtitle: "create_device.android.section.subtitle".loc(),
                icon: StyleGuide.Icon.android,
                tint: StyleGuide.Color.platformAndroid
            )
            
            VStack(spacing: StyleGuide.Spacing.xl) {
                // Large Android icon with enhanced styling
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    StyleGuide.Color.platformAndroid.opacity(0.8),
                                    StyleGuide.Color.platformAndroid
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: StyleGuide.Color.platformAndroid.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: StyleGuide.Icon.android)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: StyleGuide.Spacing.md) {
                    Text("android.create.studio.title".loc())
                        .font(StyleGuide.Typography.titleLarge.weight(.bold))
                        .foregroundColor(StyleGuide.Color.textPrimary)
                    
                    Text("android.create.studio.description".loc())
                        .font(StyleGuide.Typography.body)
                        .foregroundColor(StyleGuide.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .frame(maxWidth: 400)
                }
                
                VStack(spacing: StyleGuide.Spacing.sm) {
                    Button(action: { viewModel.openAndroidStudio() }) {
                        HStack(spacing: StyleGuide.Spacing.sm) {
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 16, weight: .semibold))
                            Text("android.open.studio".loc())
                                .font(StyleGuide.Typography.button)
                                .frame(minWidth: 120) // Prevent text movement
                        }
                        .frame(minWidth: 180)
                        .padding(.horizontal, StyleGuide.Spacing.lg)
                        .padding(.vertical, StyleGuide.Spacing.md)
                    }
                    .buttonStyle(StableProminentButtonStyle())
                    .controlSize(.large)
                    .minHitArea()
                    
                    Text("android.create.manual".loc())
                        .font(StyleGuide.Typography.caption)
                        .foregroundColor(StyleGuide.Color.textSecondary)
                }
            }
        }
        .cardStyle(padding: StyleGuide.Spacing.xxxl)
    }
    
    private var enhancedFooter: some View {
        HStack(spacing: StyleGuide.Spacing.lg) {
            Button("cancel".loc()) {
                dismiss()
            }
            .buttonStyle(StableBorderedButtonStyle())
            .controlSize(.large)
            .minHitArea()
            
            Spacer()
            
            // Progress indicator for creation status
            if viewModel.selectedPlatform != nil {
                VStack(alignment: .trailing, spacing: StyleGuide.Spacing.xs) {
                    HStack(spacing: StyleGuide.Spacing.sm) {
                        if viewModel.canCreate {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(StyleGuide.Color.success)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(StyleGuide.Color.warning)
                        }
                        Text(viewModel.canCreate ? "create_device.status.ready".loc() : "create_device.status.incomplete".loc())
                            .font(StyleGuide.Typography.caption.weight(.medium))
                            .foregroundStyle(viewModel.canCreate ? StyleGuide.Color.success : StyleGuide.Color.warning)
                    }
                }
            }
            
            Button(action: {
                Task {
                    if await viewModel.createDevice() {
                        dismiss()
                    }
                }
            }) {
                HStack(spacing: StyleGuide.Spacing.sm) {
                    if viewModel.isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: StyleGuide.Icon.add)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(viewModel.isCreating ? "create_device.action.creating".loc() : "create_device.action.submit".loc())
                        .font(StyleGuide.Typography.button)
                        .frame(minWidth: 100) // Prevent text movement
                }
                .frame(minWidth: 140)
                .padding(.horizontal, StyleGuide.Spacing.lg)
                .padding(.vertical, StyleGuide.Spacing.md)
            }
            .buttonStyle(StableProminentButtonStyle())
            .controlSize(.large)
            .disabled(!viewModel.canCreate || viewModel.isCreating)
            .minHitArea()
        }
        .padding(.horizontal, StyleGuide.Spacing.xxxl)
        .padding(.vertical, StyleGuide.Spacing.xl)
        .background(
            StyleGuide.Color.surface.opacity(0.95)
        )
    }
}

// MARK: - Enhanced Components (Private to avoid conflicts)

private struct EnhancedPlatformSelectionCard: View {
    let platform: Platform
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: StyleGuide.Spacing.lg) {
                // Platform icon with enhanced styling
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    platformColor.opacity(0.8),
                                    platformColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: platformColor.opacity(isSelected ? 0.4 : 0.2),
                            radius: isSelected ? 16 : 8,
                            x: 0,
                            y: isSelected ? 8 : 4
                        )
                    
                    Image(systemName: platformIcon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: StyleGuide.Spacing.xs) {
                    Text(platformName)
                        .font(StyleGuide.Typography.title.weight(.bold))
                        .foregroundColor(StyleGuide.Color.textPrimary)
                    
                    Text(platformDescription)
                        .font(StyleGuide.Typography.caption.weight(.medium))
                        .foregroundColor(StyleGuide.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // Selection indicator
                if isSelected {
                    HStack(spacing: StyleGuide.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("common.selected".loc())
                            .frame(minWidth: 50) // Prevent text movement
                    }
                    .font(StyleGuide.Typography.caption.weight(.semibold))
                    .foregroundStyle(platformColor)
                    .padding(.horizontal, StyleGuide.Spacing.md)
                    .padding(.vertical, StyleGuide.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(platformColor.opacity(0.15))
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding(StyleGuide.Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: StyleGuide.Radius.xl)
                    .fill(StyleGuide.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: StyleGuide.Radius.xl)
                            .stroke(
                                isSelected ? platformColor.opacity(0.6) : StyleGuide.Color.outline.opacity(0.4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? platformColor.opacity(0.2) : StyleGuide.Shadow.card.color,
                radius: isSelected ? 16 : StyleGuide.Shadow.card.radius,
                x: StyleGuide.Shadow.card.x,
                y: isSelected ? 8 : StyleGuide.Shadow.card.y
            )
        }
        .buttonStyle(StableButtonStyle())
        .animation(StyleGuide.Animation.standard, value: isSelected)
        .minHitArea()
    }
    
    private var platformColor: Color {
        platform == .iOS ? StyleGuide.Color.platformIOS : StyleGuide.Color.platformAndroid
    }
    
    private var platformIcon: String {
        platform == .iOS ? StyleGuide.Icon.iOS : StyleGuide.Icon.android
    }
    
    private var platformName: String {
        platform.displayName
    }
    
    private var platformDescription: String {
        platform == .iOS ? "create_device.platform.ios.description".loc() : "create_device.platform.android.description".loc()
    }
}

private struct CreateDeviceSectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: StyleGuide.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(tint.opacity(StyleGuide.Opacity.subtle))
                )
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                Text(title)
                    .font(StyleGuide.Typography.title.weight(.semibold))
                    .foregroundColor(StyleGuide.Color.textPrimary)
                Text(subtitle)
                    .font(StyleGuide.Typography.callout)
                    .foregroundColor(StyleGuide.Color.textSecondary)
            }
            
            Spacer()
        }
    }
}

private struct EnhancedFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.sm) {
            HStack(spacing: StyleGuide.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(StyleGuide.Color.accent)
                Text(title)
                    .font(StyleGuide.Typography.callout.weight(.medium))
                    .foregroundColor(StyleGuide.Color.textPrimary)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(StyleGuide.Typography.body)
                .padding(.horizontal, StyleGuide.Spacing.lg)
                .padding(.vertical, StyleGuide.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                        .fill(StyleGuide.Color.surfaceSecondary.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                        .stroke(StyleGuide.Color.outline.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

private struct EnhancedPickerField<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let isEmpty: Bool
    let isLoading: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.sm) {
            HStack(spacing: StyleGuide.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(StyleGuide.Color.accent)
                VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                    Text(title)
                        .font(StyleGuide.Typography.callout.weight(.medium))
                        .foregroundColor(StyleGuide.Color.textPrimary)
                    Text(subtitle)
                        .font(StyleGuide.Typography.caption)
                        .foregroundColor(StyleGuide.Color.textSecondary)
                }
            }
            
            if isEmpty && isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                    Text("create_device.loading.options".loc())
                        .font(StyleGuide.Typography.callout)
                        .foregroundColor(StyleGuide.Color.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Left aligned
                .padding(StyleGuide.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                        .fill(StyleGuide.Color.surfaceSecondary.opacity(0.8))
                )
            } else {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading) // Left aligned picker
                    .padding(.horizontal, StyleGuide.Spacing.lg)
                    .padding(.vertical, StyleGuide.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                            .fill(StyleGuide.Color.surfaceSecondary.opacity(0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                            .stroke(StyleGuide.Color.outline.opacity(0.5), lineWidth: 1)
                    )
            }
        }
    }
}

#if DEBUG && canImport(SwiftUI) && !os(macOS)
#Preview {
    CreateDeviceView()
}
#endif
