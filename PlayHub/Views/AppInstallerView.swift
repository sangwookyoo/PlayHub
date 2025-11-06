
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct AppInstallerView: View {
    @ObservedObject var viewModel: DeviceDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFileURL: URL?
    @State private var isInstalling = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    private var device: Device { viewModel.device }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
            
            ScrollView {
        VStack(spacing: StyleGuide.Spacing.xl) {
                    instructionCard
                    fileSelectionArea
                    
                    if selectedFileURL != nil {
                        installButton
                    }
                    
                    if isInstalling {
                        progressView
                    }
                }
                .padding(StyleGuide.Spacing.xl)
            }
        }
        .frame(width: 600, height: 500)
        .background(StyleGuide.Color.canvas)
        .alert("common.error".loc(), isPresented: $showError) {
            Button("common.ok".loc(), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("common.success".loc(), isPresented: $showSuccess) {
            Button("common.ok".loc(), role: .cancel) {
                dismiss()
            }
        } message: {
            Text("installer.success.message".loc())
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                Text("installer.title".loc())
                    .font(StyleGuide.Typography.title)
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                
                HStack(spacing: 6) {
                    Image(systemName: device.type == .iOS ? StyleGuide.Icon.iOS : StyleGuide.Icon.android)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(platformColor)
                
                    Text(device.name)
                        .font(StyleGuide.Typography.callout)
                        .foregroundStyle(StyleGuide.Color.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: StyleGuide.Icon.close)
                    .font(.title2)
                    .foregroundStyle(StyleGuide.Color.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(StyleGuide.Spacing.xl)
    }
    
    private var instructionCard: some View {
        HStack(spacing: StyleGuide.Spacing.md) {
            Image(systemName: StyleGuide.Icon.info)
                .font(.title2)
                .foregroundStyle(StyleGuide.Color.info)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("installer.guide.title".loc())
                    .font(StyleGuide.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                
                Text(instructionText)
                    .font(StyleGuide.Typography.caption)
                    .foregroundStyle(StyleGuide.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(StyleGuide.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StyleGuide.Color.info.opacity(0.1))
        .cornerRadius(StyleGuide.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                .stroke(StyleGuide.Color.info.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var instructionText: String {
        switch device.type {
        case .iOS: return "installer.instruction.ios".loc()
        case .android: return "installer.instruction.android".loc()
        }
    }
    
    private var fileSelectionArea: some View {
        VStack(spacing: StyleGuide.Spacing.lg) {
            if let fileURL = selectedFileURL {
                selectedFileCard(fileURL)
            } else {
                filePickerButton
            }
        }
    }
    
    private var filePickerButton: some View {
        Button(action: selectFile) {
            VStack(spacing: StyleGuide.Spacing.md) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(StyleGuide.Color.textTertiary)
                
                Text("installer.action.select_file".loc())
                    .font(StyleGuide.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                
                Text(fileTypeText)
                    .font(StyleGuide.Typography.caption)
                    .foregroundStyle(StyleGuide.Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(StyleGuide.Spacing.xxl)
            .background(StyleGuide.Color.surface)
            .cornerRadius(StyleGuide.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                    .strokeBorder(
                        StyleGuide.Color.outline,
                        style: StrokeStyle(lineWidth: 1, dash: [10, 5])
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func selectedFileCard(_ fileURL: URL) -> some View {
        HStack(spacing: StyleGuide.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: StyleGuide.Radius.md)
                    .fill(platformColor)
                    .frame(width: 56, height: 56)
                
                Image(systemName: fileIconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                Text(fileURL.lastPathComponent)
                    .font(StyleGuide.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                    .lineLimit(1)
                
                Text(fileURL.path)
                    .font(StyleGuide.Typography.caption)
                    .foregroundStyle(StyleGuide.Color.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: { selectedFileURL = nil }) {
                Image(systemName: StyleGuide.Icon.close)
                    .font(.title3)
                    .foregroundStyle(StyleGuide.Color.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(StyleGuide.Spacing.lg)
        .background(StyleGuide.Color.surface)
        .cornerRadius(StyleGuide.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                .stroke(StyleGuide.Color.outline, lineWidth: 1)
        )
    }
    
    private var installButton: some View {
        Button(action: installApp) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                Text("installer.action.install".loc())
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isInstalling || !isSelectedFileValid)
    }
    
    private var progressView: some View {
        VStack(spacing: StyleGuide.Spacing.md) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(platformColor)
            Text("installer.status.installing".loc())
                .font(StyleGuide.Typography.caption)
                .foregroundStyle(StyleGuide.Color.textSecondary)
        }
        .padding(StyleGuide.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(StyleGuide.Color.surface)
        .cornerRadius(StyleGuide.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                .stroke(StyleGuide.Color.outline, lineWidth: 1)
        )
    }
    
    private var platformColor: Color {
        device.type == .iOS ? StyleGuide.Color.platformIOS : StyleGuide.Color.platformAndroid
    }
    
    private var fileTypeText: String {
        device.type == .iOS ? "installer.filetype.ios".loc() : "installer.filetype.android".loc()
    }
    
    private var fileIconName: String {
        device.type == .iOS ? StyleGuide.Icon.iOS : StyleGuide.Icon.android
    }
    
    private var isSelectedFileValid: Bool {
        guard let url = selectedFileURL else { return false }
        switch device.type {
        case .iOS:
            return url.pathExtension.lowercased() == "app"
        case .android:
            return url.pathExtension.lowercased() == "apk"
        }
    }
    
    private func selectFile() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = device.type == .iOS // .app은 디렉터리
        panel.canCreateDirectories = false
        panel.treatsFilePackagesAsDirectories = false
        
        switch device.type {
        case .iOS:
            panel.allowedFileTypes = ["app"]
            panel.message = "installer.panel.ios".loc()
        case .android:
            panel.allowedFileTypes = ["apk"]
            panel.message = "installer.panel.android".loc()
        }
        
        if panel.runModal() == .OK {
            selectedFileURL = panel.url
        }
        #else
        print("File selection is only available on macOS.")
        #endif
    }
    
    private func installApp() {
        guard let fileURL = selectedFileURL else { return }
        guard isSelectedFileValid else {
            errorMessage = "installer.error.invalid_selection".locf(fileTypeText)
            showError = true
            return
        }
        
        isInstalling = true
        
        Task {
            do {
                try await viewModel.installApp(from: fileURL.path)
                await MainActor.run {
                    isInstalling = false
                    selectedFileURL = nil
                    showSuccess = true
                }
            } catch {
                let appError = (error as? AppError)
                await MainActor.run {
                    isInstalling = false
                    errorMessage = appError?.localizedDescription ?? error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#if DEBUG && canImport(SwiftUI) && !os(macOS)
#Preview {
    let environment = AppEnvironment.shared
    let repository = environment.makeDeviceRepository()
    let coordinator = environment.coordinator
    let sampleDevice = Device(
        id: UUID(),
        name: "iPhone 15 Pro",
        type: .iOS,
        udid: "test-udid",
        state: .booted
    )
    let viewModel = DeviceDetailViewModel(
        device: sampleDevice,
        deviceRepository: repository,
        coordinator: coordinator
    )
    
    return AppInstallerView(viewModel: viewModel)
        .environmentObject(environment.settings)
        .environmentObject(environment.localization)
        .environmentObject(environment.theme)
}
#endif
