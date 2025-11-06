import Foundation

// MARK: - UserDefaultsManaging 프로토콜

/// UserDefaults 작업을 위한 공통 프로토콜
/// 모든 Manager 클래스에서 공유하는 save/load 로직을 추삽화
protocol UserDefaultsManaging {
    var userDefaults: UserDefaults { get }
}

// MARK: - UserDefaultsManaging 기본 구현

extension UserDefaultsManaging {
    
    // MARK: - 일반 저장/로드 메서드
    
    /// 문자열 값 저장
    func save<T: RawRepresentable>(_ value: T, forKey key: String) where T.RawValue == String {
        userDefaults.set(value.rawValue, forKey: key)
    }
    
    /// 문자열 값 로드
    func load<T: RawRepresentable>(
        _ type: T.Type,
        forKey key: String,
        defaultValue: T? = nil
    ) -> T? where T.RawValue == String {
        guard let rawValue = userDefaults.string(forKey: key) else {
            return defaultValue
        }
        return T(rawValue: rawValue) ?? defaultValue
    }
    
    /// 문자열 저장
    func saveString(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    /// 문자열 로드
    func loadString(forKey key: String, defaultValue: String = "") -> String {
        return userDefaults.string(forKey: key) ?? defaultValue
    }
    
    /// Bool 저장
    func saveBool(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    /// Bool 로드
    func loadBool(forKey key: String, defaultValue: Bool = false) -> Bool {
        return userDefaults.object(forKey: key) as? Bool ?? defaultValue
    }
    
    /// Int 저장
    func saveInt(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    /// Int 로드
    func loadInt(forKey key: String, defaultValue: Int = 0) -> Int {
        let saved = userDefaults.integer(forKey: key)
        return saved == 0 ? defaultValue : saved
    }
    
    /// Double 저장
    func saveDouble(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    /// Double 로드
    func loadDouble(forKey key: String, defaultValue: Double = 0.0) -> Double {
        let saved = userDefaults.double(forKey: key)
        return saved == 0.0 ? defaultValue : saved
    }
    
    /// 값 제거
    func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    /// 동기화 (즉시 디스크에 저장)
    func synchronize() {
        userDefaults.synchronize()
    }
}

// MARK: - 고급 UserDefaults 작업

extension UserDefaultsManaging {
    
    /// Codable 객체 저장
    func saveObject<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: key)
        } catch {
            #if DEBUG
            print("❌ Failed to save object for key \(key): \(error)")
            #endif
        }
    }
    
    /// Codable 객체 로드
    func loadObject<T: Codable>(
        _ type: T.Type,
        forKey key: String,
        defaultValue: T? = nil
    ) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return defaultValue
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            #if DEBUG
            print("❌ Failed to load object for key \(key): \(error)")
            #endif
            return defaultValue
        }
    }
    
    /// 배열 저장
    func saveArray<T: Codable>(_ array: [T], forKey key: String) {
        saveObject(array, forKey: key)
    }
    
    /// 배열 로드
    func loadArray<T: Codable>(
        _ type: T.Type,
        forKey key: String,
        defaultValue: [T] = []
    ) -> [T] {
        return loadObject([T].self, forKey: key, defaultValue: defaultValue) ?? defaultValue
    }
    
    /// 사전 저장
    func saveDictionary(_ dictionary: [String: Any], forKey key: String) {
        userDefaults.set(dictionary, forKey: key)
    }
    
    /// 사전 로드
    func loadDictionary(forKey key: String, defaultValue: [String: Any] = [:]) -> [String: Any] {
        return userDefaults.dictionary(forKey: key) ?? defaultValue
    }
}

// MARK: - UserDefaultsManager 구체 구현

/// UserDefaults 작업을 위한 구체적인 유틸리티 클래스
/// 전역에서 사용할 수 있는 UserDefaults 헬퍼
final class UserDefaultsManager: UserDefaultsManaging {
    
    // MARK: - 싱글톤
    
    static let shared = UserDefaultsManager()
    
    // MARK: - 속성
    
    let userDefaults = UserDefaults.standard
    
    // MARK: - 초기화
    
    private init() {
        #if DEBUG
        print("🗄 UserDefaultsManager initialized")
        #endif
    }
    
    // MARK: - 배치 작업
    
    /// 여러 값을 한 번에 저장
    func saveBatch(_ values: [String: Any]) {
        values.forEach { key, value in
            userDefaults.set(value, forKey: key)
        }
        synchronize()
    }
    
    /// 여러 값을 한 번에 로드
    func loadBatch(keys: [String]) -> [String: Any] {
        var result: [String: Any] = [:]
        keys.forEach { key in
            result[key] = userDefaults.object(forKey: key)
        }
        return result
    }
    
    /// 특정 접두사를 가진 모든 키 제거
    func clearKeysWithPrefix(_ prefix: String) {
        let keys = userDefaults.dictionaryRepresentation().keys
        keys.filter { $0.hasPrefix(prefix) }.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
        synchronize()
    }
    
    /// 전체 UserDefaults 덕프 (디버깅용)
    #if DEBUG
    func dumpAllKeys() {
        let all = userDefaults.dictionaryRepresentation()
        print("🗄 UserDefaults dump:")
        all.keys.sorted().forEach { key in
            print("  \(key): \(all[key] ?? "nil")")
        }
    }
    #endif
}

// MARK: - UserDefaults 키 관리

/// UserDefaults 키 관리를 위한 유틸리티
struct UserDefaultsKeys {
    
    /// 범주별 키 네임스페이스
    enum Namespace: String {
        case app = "app"
        case theme = "theme"
        case language = "language"
        case android = "android"
        case performance = "performance"
        case device = "device"
        
        /// 키 생성
        func key(_ name: String) -> String {
            return "\(rawValue).\(name)"
        }
    }
    
    // MARK: - 앱 설정
    static let appTheme = Namespace.app.key("theme")
    static let appLanguage = Namespace.app.key("language")
    static let appAutoRefresh = Namespace.app.key("autorefresh.enabled")
    static let appAutoRefreshInterval = Namespace.app.key("autorefresh.interval")
    
    // MARK: - 테마 설정
    static let themeAccentColor = Namespace.theme.key("accent.color")
    static let themeWindowTransparency = Namespace.theme.key("window.transparency")
    static let themeReduceMotion = Namespace.theme.key("reduce.motion")
    
    // MARK: - Android 설정
    static let androidSDKPath = Namespace.android.key("sdk.path")
    static let androidAVDPath = Namespace.android.key("avd.path")
    static let androidADBPath = Namespace.android.key("adb.path")
    static let androidEmulatorPath = Namespace.android.key("emulator.path")
    
    // MARK: - 성능 설정
    static let performanceLogging = Namespace.performance.key("logging.enabled")
    static let performanceMaxLogEntries = Namespace.performance.key("max.log.entries")
}
