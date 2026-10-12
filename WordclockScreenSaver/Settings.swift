import Foundation
import os

enum WordclockBundle {
    static let bundle = Bundle(for: WordclockScreenSaverView.self)
    static let identifier = bundle.bundleIdentifier ?? "ru.artdima.Wordclock"
    static let logger = Logger(subsystem: identifier, category: "Wordclock")
    static var process: String { "\(ProcessInfo.processInfo.processName)[\(ProcessInfo.processInfo.processIdentifier)]" }
}

struct SaverSettings: Equatable, Codable {
    static let textScaleRange = 0.5...1.6

    var language: ClockLanguage = .english
    var variety = true
    var drift = true
    var textScale = 0.55

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let raw = try container.decodeIfPresent(String.self, forKey: .language),
           let stored = ClockLanguage(rawValue: raw) {
            language = stored
        }
        variety = try container.decodeIfPresent(Bool.self, forKey: .variety) ?? variety
        drift = try container.decodeIfPresent(Bool.self, forKey: .drift) ?? drift
        if let scale = try container.decodeIfPresent(Double.self, forKey: .textScale), scale > 0 {
            textScale = min(max(scale, Self.textScaleRange.lowerBound), Self.textScaleRange.upperBound)
        }
    }
}

enum SettingsStore {
    static let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return support.appendingPathComponent("Wordclock/settings.plist")
    }()

    static var modificationDate: Date? {
        (try? FileManager.default.attributesOfItem(atPath: fileURL.path))?[.modificationDate] as? Date
    }

    static func load() -> SaverSettings {
        guard let data = FileManager.default.contents(atPath: fileURL.path) else { return SaverSettings() }
        do {
            return try PropertyListDecoder().decode(SaverSettings.self, from: data)
        } catch {
            WordclockBundle.logger.error("settings unreadable at \(fileURL.path, privacy: .public): \(String(describing: error), privacy: .public)")
            return SaverSettings()
        }
    }

    static func save(_ settings: SaverSettings) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            try encoder.encode(settings).write(to: fileURL, options: .atomic)
            WordclockBundle.logger.notice("settings saved by \(WordclockBundle.process, privacy: .public)")
        } catch {
            WordclockBundle.logger.error("settings not saved to \(fileURL.path, privacy: .public): \(String(describing: error), privacy: .public)")
        }
    }
}
