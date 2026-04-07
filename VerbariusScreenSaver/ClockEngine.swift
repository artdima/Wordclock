import Foundation
import SwiftUI

final class ClockEngine: ObservableObject {
    @Published private(set) var phrase = ""
    @Published private(set) var drift = CGSize.zero

    private let bundle: Bundle
    private var settings: SaverSettings
    private var library: ClockLibrary
    private var currentKey = ""

    private static let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    init(settings: SaverSettings, bundle: Bundle) {
        self.settings = settings
        self.bundle = bundle
        self.library = ClockLibrary(language: settings.language, bundle: bundle)
        refresh(force: true)
    }

    var textScale: Double { settings.textScale }

    func apply(_ newSettings: SaverSettings) {
        let languageChanged = newSettings.language != settings.language
        settings = newSettings
        if languageChanged {
            library = ClockLibrary(language: newSettings.language, bundle: bundle)
        }
        refresh(force: true)
    }

    func tick() {
        refresh(force: false)
    }

    private func refresh(force: Bool) {
        let now = Date()
        let key = Self.keyFormatter.string(from: now)
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
