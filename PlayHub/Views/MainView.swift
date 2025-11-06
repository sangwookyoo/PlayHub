#if os(macOS)
import AppKit
#endif
import SwiftUI
import Combine

@MainActor
struct MainView: View {
    private let environment: AppEnvironmentProtocol
    @StateObject private var viewModel: DeviceListViewModel
    @ObservedObject private var coordinator: AppCoordinator
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    init(environment: AppEnvironmentProtocol = AppEnvironment.shared) {
        self.environment = environment
        _viewModel = StateObject(wrappedValue: environment.makeDeviceListViewModel())
        _coordinator = ObservedObject(wrappedValue: environment.coordinator)
    }
 
    @State private var selectedDeviceID: Device.ID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            DeviceListPanel(
                viewModel: viewModel,
                selectedDeviceID: $selectedDeviceID,
                presentWelcome: { coordinator.showWelcome() },
                presentCreateDevice: { coordinator.showCreateDevice() },
                presentSettings: { coordinator.showSettings() },
                onRefresh: { refreshDevices() }
            )
            .navigationSplitViewColumnWidth(
                min: StyleGuide.Layout.sidebarWidth,
                ideal: StyleGuide.Layout.sidebarWidth,
                max: StyleGuide.Layout.sidebarWidth
            )
        } detail: {
            if let device = selectedDevice {
                DeviceDetailView(
                    viewModel: environment.makeDeviceDetailViewModel(device: device)
                )
                .id(device.id) // Force refresh when device changes
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(StyleGuide.Animation.standard, value: selectedDeviceID)
            } else {
                EmptySelectionView()
                    .transition(.opacity)
                    .animation(StyleGuide.Animation.fade, value: selectedDeviceID)
            }
        }
        .navigationTitle("")
        .background(StyleGuide.Color.canvas)
        .task {
            await viewModel.refreshDevices()
            if selectedDeviceID == nil, let first = viewModel.filteredDevices.first {
                withAnimation(StyleGuide.Animation.gentle) {
                    selectedDeviceID = first.id
                }
            }
            if !UserDefaults.standard.bool(forKey: "hasSeenWelcome") {
                coordinator.showWelcome()
            }
        }
        .onReceive(coordinator.refreshPublisher) { request in
            refreshDevices(force: request.force)
        }
        .sheet(item: activeSheetBinding) { sheet in
            switch sheet {
            case .welcome:
                WelcomeView()
                    .environmentObject(settingsManager)
                    .environmentObject(localizationManager)
            case .createDevice:
                CreateDeviceView()
                    .environmentObject(settingsManager)
            case .settings:
                SettingsView()
                    .environmentObject(settingsManager)
                    .environmentObject(localizationManager)
                    .environmentObject(themeManager)
            }
        }
        .id(localizationManager.updateTrigger)
    }
    
    private var activeSheetBinding: Binding<AppCoordinator.Sheet?> {
        Binding(
            get: { coordinator.activeSheet },
            set: { coordinator.activeSheet = $0 }
        )
    }
    
    private func refreshDevices(force: Bool = true) {
        Task {
            await viewModel.refreshDevices(force: force)
            // Ensure selected device still exists after refresh
            if let id = selectedDeviceID,
               !viewModel.devices.contains(where: { $0.id == id }) {
                withAnimation(StyleGuide.Animation.gentle) {
                    selectedDeviceID = viewModel.filteredDevices.first?.id
                }
            }
        }
    }
    
    private var selectedDevice: Device? {
        guard let id = selectedDeviceID else { return nil }
        return viewModel.devices.first(where: { $0.id == id })
    }
}

struct DeviceListPanel: View {
    @ObservedObject var viewModel: DeviceListViewModel
    @Binding var selectedDeviceID: Device.ID?
    let presentWelcome: () -> Void
    let presentCreateDevice: () -> Void
    let presentSettings: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    let onRefresh: () -> Void
    
    var body: some View {
        // Apply consistent layout structure like CreateDeviceView
        VStack(spacing: 0) {
            enhancedHeader
            Divider()
                .background(StyleGuide.Color.outline.opacity(0.5))
            enhancedContent
            if !viewModel.filteredDevices.isEmpty {
                Divider()
                    .background(StyleGuide.Color.outline.opacity(0.5))
                enhancedFooter
            }
        }
        .background(StyleGuide.Color.canvas)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var enhancedHeader: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.lg) {
            HStack(spacing: StyleGuide.Spacing.xs) {
                toolbarButtons
                Spacer()
            }
            
            HStack(alignment: .center, spacing: StyleGuide.Spacing.md) {
                AccentIconBadge(
                    systemName: StyleGuide.Icon.device,
                    size: 48,
                    cornerRadius: StyleGuide.Radius.lg,
                    iconSize: 22,
                    shadow: Shadow(
                        color: StyleGuide.Color.accent.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                )
                
                VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                    Text("devices.title".loc())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(StyleGuide.Color.textPrimary)
                    Text(deviceCountDescription)
                        .font(StyleGuide.Typography.callout.weight(.medium))
                        .foregroundStyle(StyleGuide.Color.textSecondary)
                }
                
                Spacer()
            }
            
            filterControls
            searchBar
        }
        .padding(.horizontal, StyleGuide.Spacing.xxl)
        .padding(.vertical, StyleGuide.Spacing.xl)
        .background(
            StyleGuide.Color.surface.opacity(0.95)
        )
    }
    
    private var enhancedContent: some View {
        Group {
            if viewModel.filteredDevices.isEmpty {
                VStack(spacing: StyleGuide.Spacing.xl) {
                    Spacer()
                    
                    // Enhanced empty state with icon matching CreateDeviceView style
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        StyleGuide.Color.textTertiary.opacity(0.3),
                                        StyleGuide.Color.textTertiary.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: StyleGuide.Icon.device)
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(StyleGuide.Color.textTertiary)
                    }
                    
                    VStack(spacing: StyleGuide.Spacing.sm) {
                        Text("devices.empty.title".loc())
                            .font(StyleGuide.Typography.title.weight(.semibold))
                            .foregroundStyle(StyleGuide.Color.textPrimary)
                        Text("devices.empty.subtitle".loc())
                            .font(StyleGuide.Typography.callout)
                            .foregroundStyle(StyleGuide.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, StyleGuide.Spacing.xxxl)
                .padding(.vertical, StyleGuide.Spacing.xxl)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: StyleGuide.Spacing.sm) {
                            ForEach(viewModel.filteredDevices, id: \.id) { device in
                                DeviceListRow(device: device, isSelected: selectedDeviceID == device.id)
                                    .id(device.id)
                                    .padding(.horizontal, StyleGuide.Spacing.lg)
                                    .padding(.vertical, StyleGuide.Spacing.xs)
                                    .background(
                                        RoundedRectangle(cornerRadius: StyleGuide.Radius.lg, style: .continuous)
                                            .fill(
                                                selectedDeviceID == device.id
                                                ? StyleGuide.Color.accent.opacity(0.08)
                                                : StyleGuide.Color.surface.opacity(0.18)
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: StyleGuide.Radius.lg, style: .continuous)
                                            .stroke(
                                                selectedDeviceID == device.id
                                                ? StyleGuide.Color.accent.opacity(0.35)
                                                : StyleGuide.Color.outline.opacity(0.15),
                                                lineWidth: 1
                                            )
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(StyleGuide.Animation.quick) {
                                            selectedDeviceID = device.id
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, StyleGuide.Spacing.md)
                        .padding(.horizontal, StyleGuide.Spacing.xl)
                    }
                    .background(StyleGuide.Color.canvas)
                    .onChange(of: selectedDeviceID) { newValue in
                        guard let id = newValue else { return }
                        withAnimation(StyleGuide.Animation.quick) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private var enhancedFooter: some View {
        // Create device button matching CreateDeviceView footer style
        HStack(spacing: StyleGuide.Spacing.lg) {
            Spacer()
            
            Button(action: { presentCreateDevice() }) {
                HStack(spacing: StyleGuide.Spacing.xs) {
                    Image(systemName: StyleGuide.Icon.add)
                        .font(.system(size: 16, weight: .semibold))
                    Text("devices.create".loc())
                        .font(StyleGuide.Typography.button)
                        .frame(minWidth: 80) // Prevent text movement
                }
                .frame(minWidth: 120)
                .padding(.horizontal, StyleGuide.Spacing.lg)
                .padding(.vertical, StyleGuide.Spacing.xxs)
            }
            .buttonStyle(StableProminentButtonStyle())
            .controlSize(.mini)
            .minHitArea()
            
            Spacer()
        }
        .padding(.horizontal, StyleGuide.Spacing.xxl)
        .padding(.vertical, StyleGuide.Spacing.lg)
        .background(
            StyleGuide.Color.surface.opacity(0.95)
        )
    }
    
    private var searchBar: some View {
        HStack(spacing: StyleGuide.Spacing.sm) {
            searchFieldInput
                .frame(maxWidth: .infinity)
            
            ConsolidatedToolbarButton(
                title: "menu.refresh".loc(),
                systemImage: StyleGuide.Icon.refresh,
                style: .refresh
            ) {
                onRefresh()
            }
        }
        .background(StyleGuide.Color.surface.opacity(0.95))
    }
    
    private var searchFieldInput: some View {
        HStack(spacing: StyleGuide.Spacing.sm) {
            Image(systemName: StyleGuide.Icon.search)
                .foregroundStyle(StyleGuide.Color.accent)
            
            TextField("devices.search.placeholder".loc(), text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(StyleGuide.Typography.callout)
                .foregroundStyle(StyleGuide.Color.textPrimary)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    withAnimation(StyleGuide.Animation.quick) {
                        viewModel.searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(StyleGuide.Color.textSecondary.opacity(0.6))
                }
                .buttonStyle(StableButtonStyle())
                .minHitArea()
            }
        }
        .padding(.horizontal, StyleGuide.Spacing.lg)
        .padding(.vertical, StyleGuide.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                .fill(StyleGuide.Color.surfaceMuted.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                .stroke(StyleGuide.Color.outline.opacity(0.5), lineWidth: 1)
        )
        .accessibilityLabel("devices.search.placeholder".loc())
    }
    
    private var toolbarButtons: some View {
        HStack(spacing: StyleGuide.Spacing.sm) {
            ConsolidatedToolbarButton(
                title: "toolbar.welcome".loc(),
                systemImage: StyleGuide.Icon.info,
                style: .info
            ) {
                presentWelcome()
            }
            
            ConsolidatedToolbarButton(
                title: themeManager.currentTheme == .dark ? "theme.light".loc() : "theme.dark".loc(),
                systemImage: themeManager.currentTheme == .dark ? "sun.max.fill" : "moon.fill",
                style: .theme
            ) {
                let next: AppTheme = themeManager.currentTheme == .dark ? .light : .dark
                themeManager.setTheme(next)
            }
            
            ConsolidatedToolbarButton(
                title: "settings.title".loc(),
                systemImage: StyleGuide.Icon.settings,
                style: .settings
            ) {
                presentSettings()
            }
        }
    }
    
    private var filterControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: StyleGuide.Spacing.xs) {
                ImprovedFilterChip(
                    title: "filter.all".loc(),
                    count: viewModel.count(for: nil),
                    systemImage: "square.stack.3d.down.forward",
                    isSelected: viewModel.filterType == nil
                ) {
                    withAnimation(StyleGuide.Animation.quick) {
                        viewModel.filterType = nil
                    }
                }
                
                ImprovedFilterChip(
                    title: "filter.ios".loc(),
                    count: viewModel.count(for: .iOS),
                    systemImage: StyleGuide.Icon.iOS,
                    isSelected: viewModel.filterType == .iOS
                ) {
                    withAnimation(StyleGuide.Animation.quick) {
                        viewModel.filterType = .iOS
                    }
                }
                
                ImprovedFilterChip(
                    title: "filter.android".loc(),
                    count: viewModel.count(for: .android),
                    systemImage: StyleGuide.Icon.android,
                    isSelected: viewModel.filterType == .android
                ) {
                    withAnimation(StyleGuide.Animation.quick) {
                        viewModel.filterType = .android
                    }
                }
            }
            .padding(.vertical, StyleGuide.Spacing.xs)
            .padding(.horizontal, StyleGuide.Spacing.sm)
        }
    }
    
    private var deviceCountDescription: String {
        let count = viewModel.filteredDevices.count
        switch count {
        case 0:
            return "devices.count.none".loc()
        case 1:
            return "devices.count.single".loc()
        default:
            return "devices.count.multiple".locf(count)
        }
    }
}

struct EmptySelectionView: View {
    var body: some View {
        VStack(spacing: StyleGuide.Spacing.xl) {
            // Enhanced empty selection state matching CreateDeviceView style
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                StyleGuide.Color.textTertiary.opacity(0.3),
                                StyleGuide.Color.textTertiary.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sidebar.left")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(StyleGuide.Color.textTertiary)
            }
            
            VStack(spacing: StyleGuide.Spacing.sm) {
                Text("devices.select.title".loc())
                    .font(StyleGuide.Typography.title.weight(.semibold))
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                Text("devices.select.subtitle".loc())
                    .font(StyleGuide.Typography.callout)
                    .foregroundStyle(StyleGuide.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StyleGuide.Color.canvas)
    }
}

// MARK: - Enhanced Components

private struct ConsolidatedToolbarButton: View {
    let title: String
    let systemImage: String
    let style: ButtonStyle
    var isBusy: Bool = false
    let action: () -> Void
    
    enum ButtonStyle {
        case info, theme, settings, refresh
        
        var tint: Color {
            switch self {
            case .info: return StyleGuide.Color.info
            case .theme: return StyleGuide.Color.warning
            case .settings: return StyleGuide.Color.textSecondary
            case .refresh: return StyleGuide.Color.accent
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(style.tint.opacity(0.18))
                Circle()
                    .stroke(style.tint.opacity(0.35), lineWidth: 1)
                Group {
                    if isBusy {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(style.tint)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(style.tint)
                    }
                }
            }
            .frame(width: 42, height: 42)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .help(title)
        .accessibilityLabel(title)
        .minHitArea()
    }
}

private struct ImprovedFilterChip: View {
    let title: String
    let count: Int
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: StyleGuide.Spacing.xxs) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 14)
                
                Text("filter.chip.title_count".locf(title, count))
                    .font(StyleGuide.Typography.caption.weight(.semibold))
            }
            .padding(.horizontal, StyleGuide.Spacing.sm)
            .padding(.vertical, StyleGuide.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: StyleGuide.Radius.lg, style: .continuous)
                    .fill(isSelected ? StyleGuide.Color.accent.opacity(0.12) : StyleGuide.Color.surfaceMuted.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: StyleGuide.Radius.lg, style: .continuous)
                    .stroke(
                        isSelected ? StyleGuide.Color.accent.opacity(0.4) : StyleGuide.Color.outline.opacity(0.4), 
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(StableButtonStyle())
        .foregroundStyle(isSelected ? StyleGuide.Color.accent : StyleGuide.Color.textSecondary)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(StyleGuide.Animation.quick, value: isSelected)
        .minHitArea()
    }
}

#if DEBUG && canImport(SwiftUI) && !os(macOS)
#Preview {
    let environment = AppEnvironment.shared
    return MainView(environment: environment)
        .environmentObject(environment.settings)
        .environmentObject(environment.localization)
        .environmentObject(environment.theme)
}
#endif
