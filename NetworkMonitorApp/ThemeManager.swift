import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    enum Theme: String, CaseIterable, Identifiable {
        case modern = "Modern"
        case retro1986 = "Retro 1986"
        var id: String { rawValue }
    }

    @Published var style: Theme {
        didSet {
            UserDefaults.standard.set(style.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "selectedTheme"

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let t = Theme(rawValue: raw) {
            self.style = t
        } else {
            self.style = .modern
        }
    }
}

