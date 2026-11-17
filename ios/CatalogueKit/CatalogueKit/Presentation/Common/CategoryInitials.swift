import Foundation

/// Two-letter badge text for a category. Two or more words use the first letter of the first two words
/// ("Men's Clothing" -> "MC"). A single word uses its first two characters ("Electronics" -> "EL").
nonisolated enum CategoryInitials {
    static func make(from name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let text: String
        if words.count >= Constants.Home.categoryInitialWordCount {
            text = words
                .prefix(Constants.Home.categoryInitialWordCount)
                .compactMap { $0.first.map(String.init) }
                .joined()
        } else {
            text = String(name.prefix(Constants.Home.categoryInitialsLength))
        }
        return text.uppercased()
    }
}
