import Foundation

/// Strict email check: one @, a dotted domain, and a top level of two or more letters.
/// The same pattern is used by the backend, so the two always agree.
nonisolated enum EmailValidator {
    static let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$"#

    static func isValid(_ value: String) -> Bool {
        value.range(of: pattern, options: .regularExpression) != nil
    }
}

/// Mobile check: exactly 10 digits after formatting characters (spaces, dashes, brackets, dots) are removed.
nonisolated enum MobileValidator {
    static let digitCount = 10
    private static let formatting: Set<Character> = [" ", "-", "(", ")", "."]

    static func normalized(_ value: String) -> String {
        String(value.filter { !formatting.contains($0) })
    }

    static func isValid(_ value: String) -> Bool {
        let digits = normalized(value)
        return digits.count == digitCount && digits.allSatisfy(\.isNumber)
    }
}
