import SwiftUI

struct DeviceDetailView: View {
    @StateObject var viewModel: DeviceDetailViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var showAppInstaller = false
    @State private var statusMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var simulatedBatteryLevel: Double = 85
    @State private var isCharging = false
    @State private var simulatedLatitude: String = "37.5665"
    @State private var simulatedLongitude: String = "126.9780"
    @State private var isDeviceInfoExpanded = false
    
    private let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                summaryCard
            actionGrid
            installCard
            if viewModel.device.type == .iOS {
                iosAdvancedSection
            }
        }
            .padding(.horizontal, DesignSystem.Spacing.xxxl)
            .padding(.top, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xxxl)
        }
        .background(StyleGuide.Color.canvas)
        .navigationTitle(viewModel.device.name)
        .sheet(isPresented: $showAppInstaller) {
            AppInstallerView(viewModel: viewModel)
        }
        .alert("common.info".loc(), isPresented: Binding<Bool>(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("common.ok".loc(), role: .cancel) {}
        } message: {
            Text(statusMessage ?? "")
        }
        .alert("device.action.delete".loc(), isPresented: $showDeleteConfirmation) {
            Button("cancel".loc(), role: .cancel) {}
            Button("device.action.delete".loc(), role: .destructive) {
                performDeviceDeletion()
            }
        } message: {
            Text("device.detail.delete.description".loc())
        }
        .task {
            await viewModel.refreshDeviceStatus()
        }
        .refreshable {
            await viewModel.refreshDeviceStatus()
        }
    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
            HStack(spacing: DesignSystem.Spacing.xl) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                    .fill(cardAccent)
                    .frame(width: 92, height: 92)
                    .overlay(
                        Image(systemName: viewModel.device.type == .iOS ? DesignSystem.Icons.iOS : DesignSystem.Icons.android)
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: cardAccent.opacity(0.25), radius: 10, x: 0, y: 6)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text(viewModel.device.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(StyleGuide.Color.textPrimary)
                    
                    if let model = viewModel.device.deviceModel, !model.isEmpty {
                        Text(model)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(StyleGuide.Color.textSecondary)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        StatusBadge(
                            text: viewModel.device.state.localizedKey.loc(),
                            systemImage: stateIcon,
                            tint: stateColor
                        )
                        
                        StatusBadge(
                            text: viewModel.device.type.displayName,
                            systemImage: viewModel.device.type == .iOS ? DesignSystem.Icons.iOS : DesignSystem.Icons.android,
                            tint: cardAccent
                        )
                        
                        if let osVersion = versionLabel {
                            StatusBadge(
                                text: osVersion,
                                systemImage: "cpu",
                                tint: StyleGuide.Color.textSecondary
                            )
                        }
                    }
                }
                Spacer()
            }
            
            Divider()
                .background(StyleGuide.Color.outline)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Button {
                    withAnimation(StyleGuide.Animation.quick) {
                        isDeviceInfoExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("device.detail.info".loc())
                            .font(DesignSystem.Typography.callout.weight(.semibold))
                            .foregroundStyle(StyleGuide.Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(StyleGuide.Color.textSecondary)
                            .rotationEffect(.degrees(isDeviceInfoExpanded ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isDeviceInfoExpanded)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if isDeviceInfoExpanded {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.lg),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.lg)
                    ], spacing: DesignSystem.Spacing.lg) {
                        DetailInfoRow(title: "device.detail.platform".loc(), value: viewModel.device.type.displayName)
                        DetailInfoRow(title: "device.detail.status".loc(), value: viewModel.device.state.localizedKey.loc())
                        DetailInfoRow(title: "device.detail.udid".loc(), value: viewModel.device.udid ?? "–")
                        DetailInfoRow(title: "device.detail.available".loc(), value: availabilityText)
                    }
                    
                    if !viewModel.device.attributes.isEmpty {
                        Divider()
                            .background(StyleGuide.Color.outline.opacity(0.4))
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            ForEach(viewModel.device.attributes.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                DetailInfoRow(title: key.capitalized, value: value)
                            }
                        }
                    }
                }
            }
    }
    .padding(DesignSystem.Spacing.xl)
    .background(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
            .fill(StyleGuide.Color.surface)
    )
    .shadow(color: DesignSystem.Shadows.card.color, radius: DesignSystem.Shadows.card.radius, x: DesignSystem.Shadows.card.x, y: DesignSystem.Shadows.card.y)
    }
    
    private var actionGrid: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("device.actions.title".loc())
                .font(DesignSystem.Typography.title3.weight(.semibold))
                .foregroundStyle(StyleGuide.Color.textPrimary)
            
            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
                PrimaryDeviceActionButton(
                    title: "device.action.boot".loc(),
                    systemImage: DesignSystem.Icons.boot,
                    tint: DesignSystem.Colors.success,
                    isDisabled: viewModel.device.state == .booted,
                    isLoading: viewModel.isLoading
                ) {
                    await viewModel.bootDevice()
                }
                
                PrimaryDeviceActionButton(
                    title: "device.action.shutdown".loc(),
                    systemImage: DesignSystem.Icons.shutdown,
                    tint: DesignSystem.Colors.error,
                    isDisabled: viewModel.device.state == .shutdown,
                    isLoading: viewModel.isLoading
                ) {
                    await viewModel.shutdownDevice()
                }
                
                PrimaryDeviceActionButton(
                    title: "device.action.restart".loc(),
                    systemImage: DesignSystem.Icons.restart,
                    tint: DesignSystem.Colors.info,
                    isDisabled: viewModel.device.state != .booted,
                    isLoading: viewModel.isLoading
                ) {
                    await viewModel.restartDevice()
                }
                
                PrimaryDeviceActionButton(
                    title: "device.action.delete".loc(),
                    systemImage: DesignSystem.Icons.delete,
                    tint: DesignSystem.Colors.error,
                    isDisabled: viewModel.device.type != .android || isDeleting,
                    isLoading: isDeleting
                ) {
                    await MainActor.run { showDeleteConfirmation = true }
                }
            }
        }
    }
    
    private var installCard: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.xl) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignSystem.Colors.primary.opacity(0.85),
                                DesignSystem.Colors.primary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.25), radius: 12, x: 0, y: 6)
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("features.install.app".loc())
                    .font(DesignSystem.Typography.title3.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("install.instruction.title".loc())
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text(viewModel.device.name)
                    .font(DesignSystem.Typography.caption1.weight(.medium))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer(minLength: DesignSystem.Spacing.xxxl)
            
            Button {
                showAppInstaller = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("install.button".loc())
                        .font(DesignSystem.Typography.button)
                        .frame(minWidth: 120)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .buttonStyle(StableProminentButtonStyle())
            .controlSize(.large)
            .minHitArea()
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .fill(DesignSystem.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var iosAdvancedSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("advanced.features".loc())
                .font(DesignSystem.Typography.title3.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: DesignSystem.Spacing.lg), GridItem(.flexible(), spacing: DesignSystem.Spacing.lg)], spacing: DesignSystem.Spacing.lg) {
                batteryControlCard
                locationControlCard
            }
        }
    }
    
    private var batteryControlCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "battery.100")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.success)
                Text("advanced.battery".loc())
                    .font(DesignSystem.Typography.headline.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("format.percent".locf(Int(simulatedBatteryLevel)))
                    .font(DesignSystem.Typography.caption1.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            
            Slider(value: $simulatedBatteryLevel, in: 0...100, step: 1)
                .tint(DesignSystem.Colors.success)
            
            Toggle(isOn: $isCharging) {
                Text("advanced.battery.charging".loc())
                    .font(DesignSystem.Typography.callout)
            }
            .toggleStyle(.switch)
            
            HStack {
                Spacer()
                CircularActionButton(
                    tint: DesignSystem.Colors.success,
                    systemImage: "checkmark.circle.fill",
                    accessibilityLabel: "advanced.battery.accessibility.apply".loc()
                ) {
                    applyBatterySimulation()
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.success.opacity(0.25), lineWidth: 1)
        )
        .frame(minHeight: 280, alignment: .topLeading)
    }
    
    private var locationControlCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.info)
                Text("advanced.location".loc())
                    .font(DesignSystem.Typography.headline.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            
            HStack(spacing: DesignSystem.Spacing.lg) {
                SimulationTextField(
                    title: "advanced.location.latitude".loc(),
                    systemImage: "globe.americas.fill",
                    text: $simulatedLatitude
                )
                
                SimulationTextField(
                    title: "advanced.location.longitude".loc(),
                    systemImage: "map.fill",
                    text: $simulatedLongitude
                )
            }
            
            HStack {
                Menu {
                    ForEach(Array(LocationOptions.presets.enumerated()), id: \.offset) { _, preset in
                        Button(preset.name ?? "advanced.location.preset.default".loc()) {
                            simulatedLatitude = String(format: "%.4f", preset.latitude)
                            simulatedLongitude = String(format: "%.4f", preset.longitude)
                        }
                    }
                } label: {
                    Label("advanced.location.preset".loc(), systemImage: "mappin.and.ellipse")
                        .font(DesignSystem.Typography.caption1.weight(.medium))
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .fill(DesignSystem.Colors.surfaceSecondary.opacity(0.6))
                        )
                }
                Spacer()
                CircularActionButton(
                    tint: DesignSystem.Colors.info,
                    systemImage: "paperplane.fill",
                    accessibilityLabel: "advanced.location.accessibility.apply".loc(),
                    isDisabled: simulatedLatitude.isEmpty || simulatedLongitude.isEmpty
                ) {
                    applyLocationSimulation()
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.info.opacity(0.25), lineWidth: 1)
        )
        .frame(minHeight: 280, alignment: .topLeading)
    }
    
private func applyBatterySimulation() {
        Task { @MainActor in
            do {
                let level = Int(simulatedBatteryLevel)
                try await viewModel.applyBattery(level: level, isCharging: isCharging)
                let state = isCharging ? "advanced.battery.charging".loc() : "advanced.battery.not_charging".loc()
                statusMessage = "device.action.battery.applied".locf(level, state)
            } catch {
                statusMessage = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }
    
    private func applyLocationSimulation() {
        Task { @MainActor in
            do {
                guard let latitude = Double(simulatedLatitude), let longitude = Double(simulatedLongitude) else {
                    throw AppError.invalidInput("advanced.location".loc())
                }
                try await viewModel.applyLocation(latitude: latitude, longitude: longitude)
                statusMessage = "device.action.location.applied".locf(simulatedLatitude, simulatedLongitude)
            } catch {
                statusMessage = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            }
        }
    }
    
    private func performDeviceDeletion() {
        Task { @MainActor in
            isDeleting = true
            defer { isDeleting = false }
            await viewModel.deleteDevice()
        }
    }
    
    private var cardAccent: Color {
        viewModel.device.type == .iOS ? DesignSystem.Colors.iOS : DesignSystem.Colors.android
    }
    
    private var stateColor: Color {
        switch viewModel.device.state {
        case .booted: return StyleGuide.Color.success
        case .shutdown: return StyleGuide.Color.textTertiary
        case .booting, .shutting_down: return StyleGuide.Color.warning
        case .unknown: return StyleGuide.Color.info
        }
    }
    
    private var stateIcon: String {
        switch viewModel.device.state {
        case .booted: return DesignSystem.Icons.success
        case .shutdown: return "power"
        case .booting, .shutting_down: return "clock.arrow.circlepath"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private var availabilityText: String {
        viewModel.device.isAvailable ? "device.detail.available".loc() : "device.detail.unavailability".loc()
    }
    
    private var versionLabel: String? {
        if let version = viewModel.device.osVersion, !version.isEmpty {
            return viewModel.device.type == .android ? "device.version.android".locf(version) : version
        }
        return nil
    }
}

private struct DetailInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(StyleGuide.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(StyleGuide.Color.textSecondary)
            Text(value)
                .font(StyleGuide.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(StyleGuide.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatusBadge: View {
    let text: String
    let systemImage: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(StyleGuide.Typography.caption)
        .fontWeight(.semibold)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(tint.opacity(DesignSystem.Opacity.subtle))
        .foregroundStyle(tint)
        .cornerRadius(DesignSystem.CornerRadius.badge)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.badge)
                .stroke(tint.opacity(DesignSystem.Opacity.light), lineWidth: 1)
        )
    }
}

private struct PrimaryDeviceActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    var isDisabled: Bool = false
    var isLoading: Bool = false
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(isDisabled ? DesignSystem.Opacity.subtle : DesignSystem.Opacity.light))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(tint.opacity(DesignSystem.Opacity.light), lineWidth: 1)
                        )
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isDisabled ? DesignSystem.Colors.textTertiary : tint)
                    }
                }
                Text(title)
                    .font(DesignSystem.Typography.caption1.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? DesignSystem.Opacity.disabled : DesignSystem.Opacity.opaque)
        .minHitArea()
    }
}

private struct SimulationTextField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption1.weight(.medium))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: systemImage)
                    .foregroundStyle(DesignSystem.Colors.info)
                TextField(title, text: $text)
                    .textFieldStyle(.plain)
                    .font(DesignSystem.Typography.callout)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.surfaceSecondary.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CircularActionButton: View {
    let tint: Color
    let systemImage: String
    let accessibilityLabel: String
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
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
        .disabled(isDisabled)
        .opacity(isDisabled ? DesignSystem.Opacity.disabled : DesignSystem.Opacity.opaque)
        .accessibilityLabel(accessibilityLabel)
        .minHitArea()
    }
}

#if DEBUG && canImport(SwiftUI) && !os(macOS)
#Preview {
    DeviceDetailView(
        viewModel: DeviceDetailViewModel(
            device: Device(
                id: UUID(),
                name: "iPhone 15 Pro",
                type: .iOS,
                udid: "test-udid",
                state: .booted,
                isAvailable: true,
                osVersion: "iOS 17.0"
            ),
            deviceRepository: DeviceRepository(service: DeviceService(platformServices: [])),
            coordinator: AppCoordinator()
        )
    )
    .environmentObject(ThemeManager.shared)
    .environmentObject(SettingsManager())
    .environmentObject(LocalizationManager.shared)
}
#endif
