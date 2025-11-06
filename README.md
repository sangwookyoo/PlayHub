# PlayHub

PlayHub is a macOS desktop tool that unifies iOS Simulators and Android Emulators into a single management interface. Built with SwiftUI, it provides device control, diagnostics, and localization in one place, accelerating mobile team development.

**한국어 버전:** [`README_ko.md`](README_ko.md)

<img width="1641" height="886" alt="스크린샷 2025-11-06 오후 11 45 00" src="https://github.com/user-attachments/assets/06d382dd-c4d9-450d-98c6-e4bf226a2767" />

## ✨ Features

* **Unified Workspace:** Browse, search, and filter iOS and Android virtual devices on a single screen.
* **Onboarding Checklist:** Verify required developer tools step-by-step to help new team members set up quickly.
* **One-Click Actions:** Boot, shut down, restart, delete, and check device status with a single click.
* **Advanced Control:** Simulate battery level, charging state, and GPS coordinates to reproduce QA scenarios.
* **App Installation:** Upload and install `.app` or `.apk` packages directly to selected devices.
* **Multi-Language Support:** Includes English, Korean, Japanese, Simplified Chinese, Traditional Chinese, German, French, and Spanish localizations by default.

## 🛠 System Requirements

* macOS 13 Ventura or later (Apple Silicon recommended)
* Xcode Command Line Tools (`xcode-select --install`)
* Android Studio and AVD Manager
* `adb` and Android Emulator binaries must be available in `PATH` or configured via **Settings ▸ Paths**.

## 🚀 Getting Started

1. **Clone the Repository**

   ```bash
   git clone https://github.com/sangwookyoo/PlayHub.git
   cd PlayHub
   ```
2. **Open in Xcode**

   * Open `PlayHub.xcodeproj` with Xcode 15 or later.
3. **Build and Run**

   * Select the `PlayHubApp` target.
   * Build with `⌘B` and run with `⌘R`.
4. **Complete Initial Setup**

   * Follow the welcome checklist to verify required tool paths.

## 📁 Project Structure

```
PlayHub/
├── Core/          # Style guide, dependency container, shared utilities
├── Resources/     # Localization bundles and assets
├── Services/      # iOS/Android tooling integration services
├── ViewModels/    # ObservableObject-based state management
└── Views/         # SwiftUI views and UI components
```

## 🤪 Testing Guide

* Automated testing is in progress — community contributions are welcome.
* For manual verification, ensure:

  * Both iOS and Android device lists load and refresh correctly.
  * `.app` and `.apk` installations complete without errors.
  * Diagnostic results update immediately when tool paths change.

## 🤝 Contributing

1. Fork the repository and create a new branch (`git checkout -b feature/awesome`).
2. Use clear commit messages to describe your changes.
3. After modifying localization files, validate with:

   ```bash
   plutil -lint Resources/Localizable/**/*.strings
   ```
4. Submit a Pull Request including relevant screenshots and test results.

## 📄 License

PlayHub is distributed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🌐 Localization Status

| Language            | Status |
| ------------------- | ------ |
| English             | ✅      |
| Korean              | ✅      |
| Japanese            | ✅      |
| Simplified Chinese  | ✅      |
| Traditional Chinese | ✅      |
| German              | ✅      |
| French              | ✅      |
| Spanish             | ✅      |
