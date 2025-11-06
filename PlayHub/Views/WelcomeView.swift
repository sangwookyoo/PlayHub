import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var platformStatuses: [PlatformStatus] = []
    @State private var isValidating = false
    
    private var loadingStatusText: String { "welcome.requirements.loading".loc() }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .background(StyleGuide.Color.outline.opacity(0.15))
            mainSection
        }
        .frame(width: Layout.cardWidth, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(StyleGuide.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .stroke(StyleGuide.Color.outline.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: StyleGuide.Shadow.card.color.opacity(0.2), radius: 24, x: 0, y: 18)
        .padding(Layout.outerPadding)
        .background(StyleGuide.Color.canvas.ignoresSafeArea())
        .task { await refreshStatuses() }
    }
    
    private var header: some View {
        HStack(spacing: StyleGuide.Spacing.xl) {
            AccentIconBadge(
                systemName: StyleGuide.Icon.device,
                size: 64
            )
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                Text("welcome.title.headline".loc())
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("welcome.title.subtitle".loc())
                    .font(StyleGuide.Typography.callout.weight(.medium))
                    .foregroundStyle(StyleGuide.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: StyleGuide.Spacing.sm) {
                statusChips
                skipButton
            }
        }
        .padding(.horizontal, Layout.padding)
        .padding(.vertical, Layout.headerVerticalPadding)
    }
    
    private var mainSection: some View {
        ViewThatFits {
            HStack(alignment: .top, spacing: Layout.spacing) {
                mainColumn(isCompact: false)
                    .frame(width: max(Layout.contentWidth, Layout.minContentWidth), alignment: .leading)
                
                decorativePanel(isCompact: false)
                    .frame(width: Layout.panelWidth)
            }
            
            VStack(spacing: Layout.spacing) {
                mainColumn(isCompact: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                decorativePanel(isCompact: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Layout.padding)
        .padding(.vertical, Layout.contentVerticalPadding)
    }

    
    private func mainColumn(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xxl) {
            overviewBlock
            callToActionRow(isCompact: isCompact)
            requirementSummary(isCompact: isCompact)
        }
    }
    
    private var overviewBlock: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.sm) {
            Text("welcome.title.subtitle".loc())
                .font(StyleGuide.Typography.body)
                .foregroundStyle(StyleGuide.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func decorativePanel(isCompact: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.53, green: 0.36, blue: 1.0),
                    Color(red: 0.35, green: 0.53, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.lg) {
                Image(systemName: StyleGuide.Icon.device)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
                
                Text("welcome.title.subtitle".loc())
                    .font(StyleGuide.Typography.callout.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(alignment: .leading, spacing: StyleGuide.Spacing.sm) {
                    if platformStatuses.isEmpty {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text(loadingStatusText)
                            .font(StyleGuide.Typography.caption)
                            .foregroundStyle(Color.white.opacity(0.75))
                    } else {
                        ForEach(platformStatuses) { status in
                            HStack(spacing: StyleGuide.Spacing.sm) {
                                Image(systemName: status.isReady ? "checkmark.circle.fill" : "clock.arrow.circlepath")
                                    .foregroundStyle(Color.white.opacity(0.9))
                                Text(status.title)
                                    .font(StyleGuide.Typography.caption.weight(.semibold))
                                    .foregroundStyle(Color.white.opacity(0.88))
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(StyleGuide.Spacing.xxxl)
        }
        .frame(minHeight: 320)
    }
    
    private var statusChips: some View {
        HStack(spacing: StyleGuide.Spacing.md) {
            if platformStatuses.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.9)
            } else {
                ForEach(platformStatuses) { status in
                    StatusChip(status: status)
                }
            }
        }
    }
    
    @ViewBuilder
    private func callToActionRow(isCompact: Bool) -> some View {
        if isCompact {
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.md) {
                getStartedButton
                recheckButton
            }
        } else {
            HStack(spacing: StyleGuide.Spacing.md) {
                getStartedButton
                recheckButton
                Spacer()
            }
        }
    }
    
    private var getStartedButton: some View {
        Button {
            completeOnboarding()
        } label: {
            Text("welcome.action.start".loc())
                .font(StyleGuide.Typography.button)
                .frame(minWidth: 160)
        }
        .buttonStyle(StableProminentButtonStyle())
        .controlSize(.large)
        .minHitArea()
    }
    
    private var recheckButton: some View {
        Button {
            Task { await refreshStatuses() }
        } label: {
            HStack(spacing: StyleGuide.Spacing.xs) {
                if isValidating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: StyleGuide.Icon.refresh)
                }
                Text("welcome.action.recheck".loc())
            }
            .font(StyleGuide.Typography.caption.weight(.semibold))
            .padding(.horizontal, StyleGuide.Spacing.lg)
            .padding(.vertical, StyleGuide.Spacing.sm)
        }
        .buttonStyle(.plain)
        .disabled(isValidating)
        .minHitArea()
    }
    
    private var skipButton: some View {
        Button("welcome.action.skip".loc()) {
            skipOnboarding()
        }
        .buttonStyle(.plain)
        .foregroundStyle(StyleGuide.Color.textSecondary)
    }
    
    @ViewBuilder
private func requirementSummary(isCompact: Bool) -> some View {
        if platformStatuses.isEmpty {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .fill(StyleGuide.Color.surfaceSecondary.opacity(0.4))
                .frame(maxWidth: isCompact ? .infinity : CGFloat(360), minHeight: CGFloat(160))
                .overlay(
                    VStack(spacing: StyleGuide.Spacing.sm) {
                        ProgressView()
                        Text(loadingStatusText)
                            .font(StyleGuide.Typography.caption)
                            .foregroundStyle(StyleGuide.Color.textSecondary)
                    }
                )
        } else {
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.md) {
                Text("welcome.summary.title".loc())
                    .font(StyleGuide.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                
                ForEach(platformStatuses) { status in
                    RequirementSection(status: status)
                }
            }
            .padding(StyleGuide.Spacing.xxl)
            .frame(maxWidth: isCompact ? .infinity : CGFloat(360), alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                    .fill(StyleGuide.Color.surfaceSecondary.opacity(0.5))
            )
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
        dismiss()
    }
    
    private func skipOnboarding() {
        dismiss()
    }
    
    @MainActor
    private func refreshStatuses() async {
        if isValidating { return }
        isValidating = true
        defer { isValidating = false }
        
        let results = settingsManager.validatePaths()
        let iOSReady = (results["xcode"] ?? false)
        let simulatorReady = iOSReady
        let androidSDKReady = (results["android_sdk"] ?? false)
        let avdReady = (results["avd_path"] ?? false)
        let adbReady = (results["adb"] ?? false)
        let emulatorReady = (results["emulator"] ?? false)
        
        withAnimation(StyleGuide.Animation.standard) {
            platformStatuses = [
                PlatformStatus(
                    key: "welcome.platform.ios",
                    icon: StyleGuide.Icon.iOS,
                    accent: StyleGuide.Color.platformIOS,
                    isReady: iOSReady && simulatorReady,
                    steps: [
                        SetupStep(titleKey: "welcome.requirements.ios.xcode", isComplete: iOSReady),
                        SetupStep(titleKey: "welcome.requirements.ios.simulator", isComplete: simulatorReady)
                    ]
                ),
                PlatformStatus(
                    key: "welcome.platform.android",
                    icon: StyleGuide.Icon.android,
                    accent: StyleGuide.Color.platformAndroid,
                    isReady: androidSDKReady && avdReady && adbReady && emulatorReady,
                    steps: [
                        SetupStep(titleKey: "welcome.requirements.android.sdk", isComplete: androidSDKReady),
                        SetupStep(titleKey: "welcome.requirements.android.avd", isComplete: avdReady),
                        SetupStep(titleKey: "welcome.requirements.android.adb", isComplete: adbReady),
                        SetupStep(titleKey: "welcome.requirements.android.emulator", isComplete: emulatorReady)
                    ]
                )
            ]
        }
    }
}

private struct StatusChip: View {
    let status: PlatformStatus
    
    var body: some View {
        HStack(spacing: StyleGuide.Spacing.xs) {
            Image(systemName: status.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(status.isReady ? StyleGuide.Color.success : StyleGuide.Color.warning)
            Text(status.title)
                .font(StyleGuide.Typography.caption.weight(.semibold))
                .foregroundStyle(status.isReady ? StyleGuide.Color.success : StyleGuide.Color.textPrimary)
        }
        .padding(.horizontal, StyleGuide.Spacing.md)
        .padding(.vertical, StyleGuide.Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(status.accent.opacity(0.12))
        )
    }
}

private struct RequirementSection: View {
    let status: PlatformStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.sm) {
            HStack(spacing: StyleGuide.Spacing.sm) {
                Text(status.title)
                    .font(StyleGuide.Typography.callout.weight(.semibold))
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                if status.isReady {
                    Image(systemName: StyleGuide.Icon.success)
                        .foregroundStyle(StyleGuide.Color.success)
                }
            }
            ForEach(Array(status.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: StyleGuide.Spacing.sm) {
                    Text("welcome.requirements.step".locf(index + 1))
                        .font(StyleGuide.Typography.caption.weight(.semibold))
                        .foregroundStyle(StyleGuide.Color.textSecondary)
                    Text(step.localizedTitle)
                        .font(StyleGuide.Typography.caption)
                        .foregroundStyle(step.isComplete ? StyleGuide.Color.textPrimary : StyleGuide.Color.textSecondary)
                }
            }
        }
    }
}

private enum Layout {
    static let cardWidth: CGFloat = 960
    static let cardMinHeight: CGFloat = 520
    static let panelWidth: CGFloat = 320
    static let minContentWidth: CGFloat = 320
    static let cornerRadius: CGFloat = 36
    static let padding: CGFloat = StyleGuide.Spacing.xxxl
    static let spacing: CGFloat = StyleGuide.Spacing.xxl
    static let contentWidth: CGFloat = cardWidth - (padding * 2) - spacing - panelWidth
    static let headerVerticalPadding: CGFloat = StyleGuide.Spacing.xxl
    static let contentVerticalPadding: CGFloat = StyleGuide.Spacing.xl
    static let outerPadding: CGFloat = StyleGuide.Spacing.xxxl
}

// MARK: - Supporting Models

private struct PlatformStatus: Identifiable, Equatable {
    let id = UUID()
    let key: String
    let icon: String
    let accent: Color
    let isReady: Bool
    let steps: [SetupStep]
    
    var title: String { key.loc() }
    
    static func == (lhs: PlatformStatus, rhs: PlatformStatus) -> Bool {
        lhs.key == rhs.key && lhs.isReady == rhs.isReady && lhs.steps == rhs.steps
    }
}

private struct SetupStep: Identifiable, Equatable {
    let id = UUID()
    let titleKey: String
    let isComplete: Bool
    
    var localizedTitle: String { titleKey.loc() }
    
    static func == (lhs: SetupStep, rhs: SetupStep) -> Bool {
        lhs.titleKey == rhs.titleKey && lhs.isComplete == rhs.isComplete
    }
}

#if DEBUG && canImport(SwiftUI) && !os(macOS)
#Preview {
    WelcomeView()
        .environmentObject(SettingsManager())
        .environmentObject(LocalizationManager.shared)
}
#endif
