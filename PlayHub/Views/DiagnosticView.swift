import SwiftUI

struct DiagnosticView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = DiagnosticViewModel()
    @State private var selectedTab: DiagnosticTab = .systemCheck
    
    enum DiagnosticTab: CaseIterable, Identifiable {
        case systemCheck, logs, fixes
        
        var id: Self { self }
        
        var title: String {
            switch self {
            case .systemCheck: return "diagnostic.tab.system.title".loc()
            case .logs: return "diagnostic.tab.logs.title".loc()
            case .fixes: return "diagnostic.tab.fixes.title".loc()
            }
        }
        
        var description: String {
            switch self {
            case .systemCheck: return "diagnostic.tab.system.subtitle".loc()
            case .logs: return "diagnostic.tab.logs.subtitle".loc()
            case .fixes: return "diagnostic.tab.fixes.subtitle".loc()
            }
        }
        
        var icon: String {
            switch self {
            case .systemCheck: return "wrench.and.screwdriver.fill"
            case .logs: return "doc.text.magnifyingglass"
            case .fixes: return "sparkles"
            }
        }
        
        var tint: Color {
            switch self {
            case .systemCheck: return StyleGuide.Color.info
            case .logs: return StyleGuide.Color.accent
            case .fixes: return StyleGuide.Color.warning
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .background(StyleGuide.Color.outline.opacity(0.5))
            content
            Divider()
                .background(StyleGuide.Color.outline.opacity(0.5))
            footer
        }
        .frame(width: 960, height: 680)
        .background(StyleGuide.Color.canvas)
        .task {
            await viewModel.runDiagnostics()
        }
    }
    
    private var header: some View {
        HStack(spacing: StyleGuide.Spacing.xl) {
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
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                Text("diagnostic.title".loc())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                
                Text(selectedTab.description)
                    .font(DesignSystem.Typography.callout.weight(.medium))
                    .foregroundStyle(StyleGuide.Color.textSecondary)
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
        .padding(.horizontal, StyleGuide.Spacing.xxxl)
        .padding(.vertical, StyleGuide.Spacing.xxl)
        .background(StyleGuide.Color.surface.opacity(0.95))
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
            tabSelector
            detailContent
        }
        .padding(.horizontal, DesignSystem.Spacing.xxxl)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
    
    private var tabSelector: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(DiagnosticTab.allCases) { tab in
                Button {
                    withAnimation(DesignSystem.Animation.quick) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(tab.title)
                            .font(DesignSystem.Typography.callout.weight(.medium))
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .frame(minWidth: 120)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                            .fill(
                                tab == selectedTab
                                ? tab.tint.opacity(DesignSystem.Opacity.subtle)
                                : DesignSystem.Colors.surfaceSecondary.opacity(0.6)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                            .stroke(
                                tab == selectedTab
                                ? tab.tint.opacity(DesignSystem.Opacity.light)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(StableButtonStyle())
                .foregroundStyle(tab == selectedTab ? tab.tint : DesignSystem.Colors.textPrimary)
                .minHitArea()
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .systemCheck:
            systemCheckContent
        case .logs:
            logsContent
        case .fixes:
            fixesContent
        }
    }
    
    private var systemCheckContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
                if viewModel.isChecking {
                    loadingCard
                } else if let requirements = viewModel.systemRequirements {
                    RequirementCard(
                        title: "diagnostic.toolchain.ios".loc(),
                        icon: DesignSystem.Icons.iOS,
                        tint: DesignSystem.Colors.info,
                        checks: [
                            requirements.xcodeInstalled,
                            requirements.simctlAvailable
                        ]
                    )
                    
                    RequirementCard(
                        title: "diagnostic.toolchain.android".loc(),
                        icon: DesignSystem.Icons.android,
                        tint: DesignSystem.Colors.android,
                        checks: [
                            requirements.androidStudioInstalled,
                            requirements.adbAvailable,
                            requirements.emulatorAvailable,
                            requirements.avdConfigured
                        ]
                    )
                } else {
                    placeholderCard(
                        title: "diagnostic.placeholder.no_diagnostics.title".loc(),
                        message: "diagnostic.placeholder.no_diagnostics.message".loc()
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var logsContent: some View {
        Group {
            if viewModel.diagnosticLogs.isEmpty {
                placeholderCard(
                    title: "diagnostic.placeholder.no_logs.title".loc(),
                    message: "diagnostic.placeholder.no_logs.message".loc()
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        ForEach(viewModel.diagnosticLogs) { log in
                            LogRow(log: log)
                        }
                    }
                    .padding(DesignSystem.Spacing.xxl)
                }
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                        .fill(DesignSystem.Colors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                        .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
            }
        }
    }
    
    private var fixesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
                FixCard(
                    title: "diagnostic.fix.reset_cache.title".loc(),
                    description: "diagnostic.fix.reset_cache.description".loc(),
                    icon: "trash.circle.fill",
                    tint: DesignSystem.Colors.warning,
                    action: { await viewModel.resetXcodeCache() }
                )
                
                FixCard(
                    title: "diagnostic.fix.reset_simulators.title".loc(),
                    description: "diagnostic.fix.reset_simulators.description".loc(),
                    icon: "iphone.gen3",
                    tint: DesignSystem.Colors.error,
                    action: { await viewModel.resetSimulators() }
                )
                
                if !viewModel.fixResults.isEmpty {
                    Divider()
                        .background(DesignSystem.Colors.border.opacity(0.4))
                    Text("diagnostic.fix.recent.title".loc())
                        .font(DesignSystem.Typography.callout.weight(.medium))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        ForEach(viewModel.fixResults) { result in
                            FixResultRow(result: result)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var footer: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Button {
                viewModel.exportLogs()
            } label: {
                Label("diagnostic.action.export_logs".loc(), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(StableBorderedButtonStyle())
            .disabled(viewModel.diagnosticLogs.isEmpty)
            .minHitArea()
            
            Spacer()
            
            Button {
                Task { await viewModel.runDiagnostics() }
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if viewModel.isChecking {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: DesignSystem.Icons.refresh)
                    }
                    Text(viewModel.isChecking ? "diagnostic.action.checking".loc() : "diagnostic.action.run_again".loc())
                }
                .frame(minWidth: 140)
            }
            .buttonStyle(StableProminentButtonStyle())
            .disabled(viewModel.isChecking)
            .minHitArea()
            
            Button("common.close".loc()) {
                dismiss()
            }
            .buttonStyle(StableButtonStyle())
            .minHitArea()
        }
        .padding(.horizontal, DesignSystem.Spacing.xxxl)
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
    
    private var loadingCard: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(.circular)
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("diagnostic.loading.title".loc())
                    .font(DesignSystem.Typography.callout.weight(.medium))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("diagnostic.loading.subtitle".loc())
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
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
        .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
    }
    
    private func placeholderCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.callout.weight(.medium))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .fill(DesignSystem.Colors.surfaceSecondary.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
    }
}

private struct RequirementCard: View {
    let title: String
    let icon: String
    let tint: Color
    let checks: [SystemCheck]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(tint)
                    )
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.callout.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text("diagnostic.toolchain.subtitle".loc())
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                ForEach(checks, id: \.message) { check in
                    RequirementRow(check: check)
                }
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
        .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
    }
}

private struct RequirementRow: View {
    let check: SystemCheck
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: check.isInstalled ? DesignSystem.Icons.success : DesignSystem.Icons.error)
                .foregroundStyle(check.isInstalled ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                .font(.system(size: 16, weight: .semibold))
                .padding(DesignSystem.Spacing.sm)
                .background(
                    Circle()
                        .fill(check.isInstalled ? DesignSystem.Colors.success.opacity(0.15) : DesignSystem.Colors.error.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(check.message)
                    .font(DesignSystem.Typography.callout.weight(.medium))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                if !check.version.isEmpty && check.version != "N/A" {
                    Text("diagnostic.version.label".locf(check.version))
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                if !check.path.isEmpty {
                    Text(check.path)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

private struct LogRow: View {
    let log: DiagnosticLog
    
    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: log.timestamp)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: log.level.icon)
                .foregroundStyle(log.level.color)
                .font(.system(size: 18, weight: .semibold))
                .padding(DesignSystem.Spacing.sm)
                .background(
                    Circle()
                        .fill(log.level.color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("diagnostic.log.entry".locf(timestamp, log.level.displayName))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text(log.message)
                    .font(DesignSystem.Typography.code)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FixCard: View {
    let title: String
    let description: String
    let icon: String
    let tint: Color
    let action: () async -> Void
    
    @State private var isFixing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(tint)
                    )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.callout.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button {
                    Task {
                        guard !isFixing else { return }
                        isFixing = true
                        await action()
                        isFixing = false
                    }
                } label: {
                    if isFixing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .frame(width: 24, height: 24)
                    } else {
                        Text("diagnostic.action.run".loc())
                            .font(DesignSystem.Typography.button)
                            .frame(minWidth: 80)
                    }
                }
                .buttonStyle(StableProminentButtonStyle())
                .tint(tint)
                .disabled(isFixing)
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
        .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
    }
}

private struct FixResultRow: View {
    let result: FixResult
    
    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: result.timestamp)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: result.success ? DesignSystem.Icons.success : DesignSystem.Icons.error)
                .foregroundStyle(result.success ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                .font(.system(size: 18, weight: .semibold))
                .padding(DesignSystem.Spacing.sm)
                .background(
                    Circle()
                        .fill((result.success ? DesignSystem.Colors.success : DesignSystem.Colors.error).opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(result.title)
                    .font(DesignSystem.Typography.callout.weight(.medium))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(result.message)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text(timestamp)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG && canImport(SwiftUI) && !os(macOS)
#Preview {
    DiagnosticView()
}
#endif
