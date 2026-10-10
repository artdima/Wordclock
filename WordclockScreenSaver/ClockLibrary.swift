import Foundation
import os

enum ClockLanguage: String, CaseIterable, Identifiable {
    case russian = "Russian"
    case english = "English"

    var id: String { rawValue }

    static var systemDefault: ClockLanguage {
        Locale.preferredLanguages.first?.hasPrefix("ru") == true ? .russian : .english
    }

    var title: String {
        switch self {
        case .russian: return String(localized: "Russian", bundle: WordclockBundle.bundle)
        case .english: return String(localized: "English", bundle: WordclockBundle.bundle)
        }
    }
}

struct ClockEntry: Decodable {
    let clock: String
    let phrases: [String]

    private struct AnyKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        clock = try container.decode(String.self, forKey: AnyKey(stringValue: "clock"))

        var numbered: [(index: Int, text: String)] = []
        for key in container.allKeys where key.stringValue.hasPrefix("value_") {
            guard let index = Int(key.stringValue.dropFirst("value_".count)),
                  let raw = try container.decodeIfPresent(String.self, forKey: key) else { continue }
            let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { numbered.append((index, text)) }
        }
        phrases = numbered.sorted { $0.index < $1.index }.map { $0.text }
    }
}

struct ClockLibrary {
    private static let logger = Logger(subsystem: WordclockBundle.identifier, category: "ClockLibrary")
    private static var cache: [ClockLanguage: ClockLibrary] = [:]

    private let entries: [String: [String]]

    static func cached(_ language: ClockLanguage, bundle: Bundle) -> ClockLibrary {
        if let library = cache[language] { return library }
        let library = ClockLibrary(language: language, bundle: bundle)
        cache[language] = library
        return library
    }

    init(language: ClockLanguage, bundle: Bundle) {
        guard let url = bundle.url(forResource: language.rawValue, withExtension: "json") else {
            Self.logger.error("\(language.rawValue, privacy: .public).json is missing in \(bundle.bundlePath, privacy: .public)")
            assertionFailure("\(language.rawValue).json is not in the bundle")
            entries = [:]
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([ClockEntry].self, from: data)
            entries = Dictionary(decoded.map { ($0.clock, $0.phrases) }, uniquingKeysWith: { first, _ in first })
        } catch {
            Self.logger.error("Cannot load \(url.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public)")
            assertionFailure("Cannot load \(url.lastPathComponent): \(error)")
            entries = [:]
        }
    }

    func phrases(for key: String) -> [String] {
        entries[key] ?? []
    }
}
