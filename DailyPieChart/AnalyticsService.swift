import Foundation
import UIKit

/// ファネル計測。「予定を書いた人のうち何人がPro解放まで辿り着いたか」を知るためだけに入れている。
///
/// 送るのはイベント名と画面の位置だけで、**登録した予定の名前や時間帯は一切送らない**。
/// 端末の識別も、インストール時に生成したランダムなUUIDだけを使う(広告IDやIDFVは使わない)。
///
/// 送り先はIkigai Finder用に作ったCloudflare Workerに相乗り(`app`パラメータで区別)。
/// 複数アプリのイベントを1箇所に集めたほうが、Workerを増やすより運用コストが低いため。
@MainActor
final class Analytics {
    static let shared = Analytics()

    private let endpoint = URL(string: "https://ikigai-proxy.shinya-takayanagi-h4s.workers.dev/event")!
    private let appName = "daily-pie-chart"

    private var queue: [Event] = []
    /// 送信中のぶん。端末への書き出しは queue と合わせて行う。
    /// これを別に持たないと、送信中に積まれたイベントが控えを上書きして消す。
    private var inFlight: [Event] = []
    private var isFlushing = false
    private var consecutiveFailures = 0
    private var isDisabledForSession = false

    private let failureLimit = 3
    private let batchSize = 10

    private struct Event: Codable {
        let name: String
        let params: [String: String]
        let at: String
    }

    /// 未送信のイベントを置く場所。アプリが終了しても消えないようにする。
    private static let pendingKey = "analytics_pending_events"

    private init() {
        // 前回の起動で送りきれなかったぶんを引き継ぐ。
        // これが無いと、バックグラウンドに回らずに終了したセッションの記録が丸ごと消える。
        if let data = UserDefaults.standard.data(forKey: Self.pendingKey),
           let saved = try? JSONDecoder().decode([Event].self, from: data) {
            queue = saved
            UserDefaults.standard.removeObject(forKey: Self.pendingKey)
        }

        // didEnterBackground だけだと、ホームに戻さず落とされた場合に間に合わない。
        // 先に飛ぶ willResignActive でも書き出しておく。
        for name in [UIApplication.willResignActiveNotification,
                     UIApplication.didEnterBackgroundNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                Task { @MainActor in
                    Analytics.shared.persistQueue()
                    Analytics.shared.flush()
                }
            }
        }
    }

    /// 送信待ちのイベントを端末に書き出す。送信が済めば捨てる。
    private func persistQueue() {
        let pending = inFlight + queue
        guard !pending.isEmpty, let data = try? JSONEncoder().encode(pending) else {
            UserDefaults.standard.removeObject(forKey: Self.pendingKey)
            return
        }
        UserDefaults.standard.set(data, forKey: Self.pendingKey)
    }

    // MARK: - 記録

    func track(_ name: String, _ params: [String: String] = [:]) {
        guard !isDisabledForSession else { return }

        queue.append(Event(name: name, params: params, at: Self.timestamp.string(from: Date())))

        // 積んだ時点で書き出す。非アクティブ化を待つと、購入シートが閉じて
        // アプリがアクティブに戻ってから積まれる purchase_succeeded が、
        // そのまま落とされたときに消える。
        persistQueue()

        if queue.count >= batchSize {
            flush()
        }
    }

    // MARK: - 送信

    func flush() {
        guard !isDisabledForSession, !isFlushing, !queue.isEmpty else { return }

        let batch = queue
        queue = []
        inFlight = batch
        isFlushing = true

        Task {
            let succeeded = await send(batch)
            await MainActor.run {
                self.isFlushing = false
                self.inFlight = []
                if succeeded {
                    self.consecutiveFailures = 0
                    // 送信中に積まれたぶんだけが残る。無ければここで控えも消える。
                    self.persistQueue()
                    if !self.queue.isEmpty { self.flush() }
                } else {
                    self.consecutiveFailures += 1
                    if self.consecutiveFailures >= self.failureLimit {
                        // ここまで来たら諦める。溜め続けてメモリを食うより欠測を受け入れる。
                        self.isDisabledForSession = true
                        self.queue = []
                        UserDefaults.standard.removeObject(forKey: Self.pendingKey)
                    } else {
                        // 一度の失敗で捨てない。戻して次の機会に送り直す。
                        self.queue = batch + self.queue
                        self.persistQueue()
                    }
                }
            }
        }
    }

    private func send(_ batch: [Event]) async -> Bool {
        let payload = Payload(
            installID: Self.installID,
            app: appName,
            appVersion: Self.appVersion,
            language: Self.language,
            events: batch
        )

        guard let body = try? JSONEncoder().encode(payload) else { return false }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200..<300).contains(http.statusCode)
        } catch {
            return false
        }
    }

    private struct Payload: Encodable {
        let installID: String
        let app: String
        let appVersion: String
        let language: String
        let events: [Event]
    }

    // MARK: - 端末側の値

    private static let installID: String = {
        let key = "analytics_install_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }()

    private static let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }()

    private static let language: String = {
        Locale.current.language.languageCode?.identifier ?? "?"
    }()

    private static let timestamp: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

// MARK: - イベント名

enum AnalyticsEvent {
    static let appOpened = "app_opened"
    static let scheduleAdded = "schedule_added"              // 1日の予定を1件書いた
    static let scheduleShared = "schedule_shared"            // 円グラフを画像にして共有した
    static let personViewed = "person_viewed"                // 偉人の1日を開いた
    static let freeLimitHit = "free_limit_hit"               // 無料枠に当たって追加できなかった
    static let paywallShown = "paywall_shown"                // (trigger: add_schedule / locked_person / pro_teaser / share_theme)
    static let paywallTapped = "paywall_tapped"              // 購入ボタンを押した
    static let purchaseSucceeded = "purchase_succeeded"
    static let purchaseCancelled = "purchase_cancelled"
    static let purchaseFailed = "purchase_failed"
    static let restoreTapped = "restore_purchases_tapped"
}
