import Foundation

/// アプリ本体とウィジェット拡張はコンテナが別なので、App Group 経由でデータを共有する。
/// このファイルは両ターゲットに含める。
enum AppGroup {
    static let identifier = "group.com.PandaGiken.DailyPieChart"

    static let schedulesKey = "allSchedules"
    static let activeScheduleIdKey = "activeScheduleId"

    /// プロビジョニングが未更新などで App Group が使えない環境でもアプリが
    /// 壊れないよう、取得できなければ standard にフォールバックする。
    /// （その場合ウィジェットにはデータが見えないが、本体は従来どおり動く）
    static let defaults: UserDefaults = UserDefaults(suiteName: identifier) ?? .standard

    static var isSharedContainerAvailable: Bool {
        defaults !== UserDefaults.standard
    }

    /// v1.0 は UserDefaults.standard に保存していたため、初回起動時に一度だけ移行する。
    static func migrateFromStandardIfNeeded() {
        guard isSharedContainerAvailable else { return }
        guard defaults.data(forKey: schedulesKey) == nil,
              let legacy = UserDefaults.standard.data(forKey: schedulesKey) else { return }

        defaults.set(legacy, forKey: schedulesKey)
        if let activeId = UserDefaults.standard.string(forKey: activeScheduleIdKey) {
            defaults.set(activeId, forKey: activeScheduleIdKey)
        }
    }

    /// App Group の entitlement が無い間は suiteName がアプリ内のローカル領域を指す。
    /// 後から App Group を有効にすると参照先のファイルが変わってしまうため、
    /// standard 側にも控えを残しておき、切り替わっても復元できるようにする。
    static func mirrorToStandard(_ data: Data, activeId: String) {
        guard isSharedContainerAvailable else { return }
        UserDefaults.standard.set(data, forKey: schedulesKey)
        UserDefaults.standard.set(activeId, forKey: activeScheduleIdKey)
    }

    // MARK: - Read

    private static func decode(_ data: Data?) -> [Schedule]? {
        guard let data else { return nil }
        return try? JSONDecoder().decode([Schedule].self, from: data)
    }

    static func loadSchedules() -> [Schedule] {
        if let schedules = decode(defaults.data(forKey: schedulesKey)), !schedules.isEmpty {
            return schedules
        }
        // 共有コンテナが空なら控えを見る。
        return decode(UserDefaults.standard.data(forKey: schedulesKey)) ?? []
    }

    /// ウィジェットが表示する対象。アクティブなものが特定できなければ先頭を使う。
    static func activeSchedule() -> Schedule? {
        let all = loadSchedules()
        let activeId = defaults.string(forKey: activeScheduleIdKey)
        return all.first { $0.id.uuidString == activeId } ?? all.first
    }
}

extension Schedule {
    /// 時刻を 0:00 起点の累積時間とみなして、その瞬間にあたる活動を返す。
    func block(at date: Date, calendar: Calendar = .current) -> TimeBlock? {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let hourOfDay = Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0

        var elapsed = 0.0
        for block in timeBlocks {
            elapsed += block.hours
            if hourOfDay < elapsed { return block }
        }
        return timeBlocks.last
    }

    /// その活動が終わるまでの残り時間（時間単位）。
    func remainingHours(at date: Date, calendar: Calendar = .current) -> Double? {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let hourOfDay = Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0

        var elapsed = 0.0
        for block in timeBlocks {
            elapsed += block.hours
            if hourOfDay < elapsed { return elapsed - hourOfDay }
        }
        return nil
    }
}
