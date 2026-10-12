import Combine
import CoreGraphics
import Foundation
import os

final class ClockEngine: ObservableObject {
    @Published private(set) var phrase = ""
    @Published private(set) var drift = CGSize.zero
    @Published private(set) var settings: SaverSettings

    private let bundle: Bundle
    private var library: ClockLibrary
    private var currentKey = ""
    private var settingsStamp: Date?

    private static let calendar = Calendar.autoupdatingCurrent

    init(settings: SaverSettings, bundle: Bundle) {
        self.settings = settings
        self.bundle = bundle
        self.library = .cached(settings.language, bundle: bundle)
        self.settingsStamp = SettingsStore.modificationDate
        refresh(force: true)
    }

    var textScale: Double { settings.textScale }

    func apply(_ newSettings: SaverSettings) {
        if newSettings.language != settings.language {
            library = .cached(newSettings.language, bundle: bundle)
        }
        settings = newSettings
        refresh(force: true)
    }

    func tick() {
        reloadSettingsIfChanged()
        refresh(force: false)
    }

    private func reloadSettingsIfChanged() {
        let stamp = SettingsStore.modificationDate
        guard stamp != settingsStamp else { return }
        settingsStamp = stamp
        let stored = SettingsStore.load()
        guard stored != settings else { return }
        WordclockBundle.logger.notice("settings reloaded in \(WordclockBundle.process, privacy: .public)")
        apply(stored)
    }

    private func refresh(force: Bool) {
        let now = Date()
        let key = Self.key(for: now)
        updateDrift(now)
        guard force || key != currentKey else { return }
        currentKey = key

        let options = library.phrases(for: key)
        let text: String
        if options.isEmpty {
            text = key
        } else if settings.variety {
            text = options[Self.variant(for: now, count: options.count)]
        } else {
            text = options[0]
        }
        if text != phrase { phrase = text }
    }

    private func updateDrift(_ now: Date) {
        guard settings.drift else {
            if drift != .zero { drift = .zero }
            return
        }
        let seconds = now.timeIntervalSinceReferenceDate
        drift = CGSize(width: sin(seconds / 137), height: cos(seconds / 197))
    }

    private static func key(for date: Date) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02ld:%02ld", parts.hour ?? 0, parts.minute ?? 0)
    }

    private static func variant(for date: Date, count: Int) -> Int {
        var seed = UInt64(bitPattern: Int64(date.timeIntervalSinceReferenceDate / 60))
        seed = (seed &+ 0x9E37_79B9_7F4A_7C15) ^ (seed >> 30)
        seed = seed &* 0xBF58_476D_1CE4_E5B9
        seed ^= seed >> 27
        seed = seed &* 0x94D0_49BB_1331_11EB
        seed ^= seed >> 31
        return Int(seed % UInt64(count))
    }
}
