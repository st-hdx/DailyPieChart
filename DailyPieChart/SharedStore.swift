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
    /// その時刻にあたる活動。開始時刻(`startHour`)を起点に数えるので、
    /// 区画で埋まっていない時間(バッファ)に入っていれば nil を返す。
    ///
    /// 以前は 0:00 起点で数えたうえ、どこにも当たらなければ最後の区画を返していた。
    /// 開始時刻とバッファを入れた今は、それだと「バッファ中なのに最後の活動が出続ける」
    /// ことになるため、時間の判定は Models 側の実装に一本化する。
    func block(at date: Date, calendar: Calendar = .current) -> TimeBlock? {
        block(at: Self.hourOfDay(date, calendar: calendar))
    }

    /// いまの活動が終わるまでの残り時間。バッファ中はバッファが明ける(=翌日の開始時刻)までを返す。
    func remainingHours(at date: Date, calendar: Calendar = .current) -> Double? {
        let hourOfDay = Self.hourOfDay(date, calendar: calendar)
        var elapsed = hourOfDay - startHour
        if elapsed < 0 { elapsed += 24 }

        var cursor = 0.0
        for block in timeBlocks {
            cursor += block.hours
            if elapsed < cursor { return cursor - elapsed }
        }
        // バッファ中。次に予定が始まるのは 24 時間地点(翌日の開始時刻)。
        guard elapsed < 24 else { return nil }
        return 24 - elapsed
    }

    static func hourOfDay(_ date: Date, calendar: Calendar = .current) -> Double {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0
    }
}
