# PlayHub

PlayHub은 macOS에서 iOS 시뮬레이터와 Android 에뮬레이터를 하나의 앱에서 통합 관리할 수 있는 데스크톱 도구입니다. SwiftUI 기반 인터페이스로 디바이스 제어, 진단, 로컬라이제이션을 한 번에 처리하여 모바일 팀의 개발 속도를 높여 줍니다.

**English version available:** see [`README.md`](README.md).

## ✨ 주요 기능

- **통합 워크스페이스:** iOS·Android 가상 디바이스를 한 화면에서 탐색, 검색, 필터링합니다.
- **온보딩 체크리스트:** 필수 개발 도구를 단계별로 확인하여 신규 팀원이 빠르게 셋업하도록 돕습니다.
- **원클릭 액션:** 부팅, 종료, 재시작, 삭제, 상태 확인을 클릭 한 번으로 실행합니다.
- **고급 제어:** 배터리 잔량과 충전 상태, 위치 좌표를 시뮬레이션해 재현 가능한 QA 시나리오를 구성합니다.
- **앱 설치:** 선택한 디바이스에 `.app`, `.apk` 패키지를 바로 업로드하고 설치합니다.
- **다국어 지원:** 영어, 한국어, 일본어, 중국어 간체, 중국어 번체, 독일어, 프랑스어, 스페인어 번들을 기본 제공합니다.

## 🛠 시스템 요구 사항

- macOS 13 Ventura 이상 (Apple Silicon 권장)
- Xcode 명령줄 도구 (`xcode-select --install`)
- Android Studio 및 AVD Manager
- `adb`, Android Emulator 바이너리가 `PATH`에 있거나 Settings ▸ Paths에서 설정되어 있어야 합니다.

## 🚀 시작하기

1. **저장소 클론**
   ```bash
   git clone https://github.com/sangwookyoo/PlayHub.git
   cd PlayHub
   ```
2. **Xcode에서 열기**
   - `PlayHub.xcodeproj`를 Xcode 15 이상으로 실행합니다.
3. **빌드 및 실행**
   - `PlayHubApp` 타깃을 선택합니다.
   - `⌘B`로 빌드 후 `⌘R`로 실행합니다.
4. **최초 실행 가이드 완료**
   - 웰컴 체크리스트 안내를 따라 필수 경로를 확인합니다.

## 📁 프로젝트 구조

```
PlayHub/
├── Core/          # 스타일 가이드, 의존성 컨테이너, 공용 유틸리티
├── Resources/     # 로컬라이제이션 번들 및 에셋
├── Services/      # iOS/Android 툴링 연동 서비스
├── ViewModels/    # ObservableObject 기반 상태 관리
└── Views/         # SwiftUI 뷰와 컴포넌트
```

## 🧪 테스트 가이드

- 자동화 테스트는 진행 중이며 커뮤니티 기여를 환영합니다.
- 수동 검증 시 다음을 확인하십시오.
  - 두 플랫폼의 디바이스 목록이 정상적으로 로드되고 새로 고침됩니다.
  - `.app`, `.apk` 앱 설치 플로우가 오류 없이 완료됩니다.
  - 진단 결과가 도구 경로 변경에 맞춰 즉시 갱신됩니다.

## 🤝 기여하기

1. 저장소를 포크하고 새 브랜치를 생성합니다 (`git checkout -b feature/awesome`).
2. 명확한 커밋 메시지로 작업 내용을 정리합니다.
3. 로컬라이제이션 파일을 수정한 후 `plutil -lint Resources/Localizable/**/*.strings`로 유효성을 검사합니다.
4. 변경 사항과 스크린샷, 테스트 결과를 포함해 Pull Request를 올립니다.

## 📄 라이선스

PlayHub은 MIT 라이선스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

## 🌐 로컬라이제이션 현황

| 언어 | 상태 |
|------|------|
| English | ✅ |
| 한국어 | ✅ |
| 日本語 | ✅ |
| 简体中文 | ✅ |
| 繁體中文 | ✅ |
| Deutsch | ✅ |
| Français | ✅ |
| Español | ✅ |
