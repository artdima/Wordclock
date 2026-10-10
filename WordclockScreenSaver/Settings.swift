import Foundation
import ScreenSaver

enum WordclockBundle {
    static let bundle = Bundle(for: WordclockScreenSaverView.self)
    static let identifier = bundle.bundleIdentifier ?? "ru.artdima.Wordclock"
}

struct SaverSettings: Equatable {
    static let textScaleRange = 0.5...1.6

    var language: ClockLanguage = .systemDefault
    var variety = true
    var drift = true
    var textScale = 1.0
}

enum SettingsStore {
    private enum Key {
        static let language = "language"
        static let variety = "variety"
        static let drift = "drift"
        static let textScale = "textScale"
    }

    private static let defaults: ScreenSaverDefaults? = {
        let store = ScreenSaverDefaults(forModuleWithName: WordclockBundle.identifier)
        store?.register(defaults: [
            Key.language: ClockLanguage.systemDefault.rawValue,
            Key.variety: true,
            Key.drift: true,
            Key.textScale: 1.0
        ])
        return store
    }()

    static func load() -> SaverSettings {
        var settings = SaverSettings()
        guard let store = defaults else { return settings }
        if let raw = store.string(forKey: Key.language), let language = ClockLanguage(rawValue: raw) {
            settings.language = language
        }
        settings.variety = store.bool(forKey: Key.variety)
        settings.drift = store.bool(forKey: Key.drift)
        let scale = store.double(forKey: Key.textScale)
        settings.textScale = scale > 0 ? scale.clamped(to: SaverSettings.textScaleRange) : 1.0
        return settings
    }

    static func save(_ settings: SaverSettings) {
        guard let store = defaults else { return }
        store.set(settings.language.rawValue, forKey: Key.language)
        store.set(settings.variety, forKey: Key.variety)
        store.set(settings.drift, forKey: Key.drift)
        store.set(settings.textScale, forKey: Key.textScale)
        store.synchronize()
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
