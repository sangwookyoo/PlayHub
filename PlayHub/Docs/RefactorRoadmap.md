# PlayHub Refactor Roadmap

This document captures the immediate follow-up work after the first refactor pass.

## 1. Design System V2
- Move component styles (`StableButtonStyle`, etc.) onto `StyleGuide` to simplify a gradual transition away from `DesignSystem`.
- Introduce light/dark palettes as data rather than direct `Color` references so themes can be swapped dynamically.
- Map typography tokens to semantic roles (title, label, body, helper) and replace ad‑hoc font usage.
- Extract reusable layout primitives (cards, panels, field groups) to reduce repeated spacings.

## 2. Architecture Modernisation
- Replace `DependencyContainer` factory methods with feature-specific use cases and repositories.
- Adopt a `Coordinator`/`Navigator` layer to remove NotificationCenter-based routing.
- Model feature modules (Devices, Settings, Diagnostics) as independent packages for clearer ownership.
- Add domain models for simulator diagnostics (battery, location) with validation rules.

## 3. Performance & Tooling
- Add async caching for expensive platform calls (`simctl`, `adb`) with stale-while-revalidate strategy.
- Integrate swift-format and SwiftLint with a pre-commit pipeline.
- Establish snapshot/UI tests for primary flows (device list, detail actions, onboarding).
- Benchmark cold launch and heavy list filtering to guide further optimisation.

## 4. De-scoping Legacy Features
- Confirm the diagnostic log export still has a use case; if not, remove or merge into the new analytics module.
- Evaluate if the advanced features pane should become a separate window or inline drawer for better context.
