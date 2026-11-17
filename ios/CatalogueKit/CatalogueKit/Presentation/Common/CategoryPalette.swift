import SwiftUI

/// One muted accent for every category, so the Categories section looks uniform and professional.
nonisolated enum CategoryPalette {
    /// Slate: readable behind white text and on both light and dark grey tiles.
    static let accent = Color(categoryHex: 0x334155)
    static let neutral = Color.gray
}

private extension Color {
    init(categoryHex hex: UInt32) {
        let channelMax = Double(Constants.Home.colorChannelMax)
        self.init(
            red: Double((hex >> 16) & 0xFF) / channelMax,
            green: Double((hex >> 8) & 0xFF) / channelMax,
            blue: Double(hex & 0xFF) / channelMax
        )
    }
}
