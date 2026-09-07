import Foundation

enum ClockLanguage: String, CaseIterable, Identifiable {
    case russian = "Russia"
    case english = "English"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .russian: return "Russian"
        case .english: return "English"
        }
    }
}

struct ClockEntry: Decodable {
    let clock: String
    let phrases: [String]

    private struct AnyKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyKey.self)
        guard let clockKey = AnyKey(stringValue: "clock") else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "missing clock"))
        }
        clock = try container.decode(String.self, forKey: clockKey)

        var numbered: [(Int, String)] = []
        for key in container.allKeys where key.stringValue.hasPrefix("value_") {
            guard let index = Int(key.stringValue.dropFirst("value_".count)),
                  let text = try container.decodeIfPresent(String.self, forKey: key),
                  !text.isEmpty else { continue }
            numbered.append((index, text))
        }
        phrases = numbered.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
}

struct ClockLibrary {
    private let entries: [String: [String]]

    init(language: ClockLanguage, bundle: Bundle) {
        guard let url = bundle.url(forResource: language.rawValue, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ClockEntry].self, from: data) else {
            entries = [:]
            return
        }
        entries = Dictionary(decoded.map { ($0.clock, $0.phrases) }, uniquingKeysWith: { first, _ in first })
    }

    func phrases(for key: String) -> [String] {
        entries[key] ?? []
    }
}
