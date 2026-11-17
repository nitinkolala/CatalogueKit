import ImageIO
import UIKit

/// Decodes image data straight to a smaller bitmap with ImageIO, without decoding the full-size image first.
/// A 2000-pixel product photo shown in a 160-point card then uses a fraction of the memory.
nonisolated enum ImageDecoder {
    /// Returns the image with its longest side at most `maxPixelSize` pixels. Smaller images keep their size.
    /// Returns nil when the data is not an image.
    static func downsample(_ data: Data, maxPixelSize: Int) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxPixelSize, 1),
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

extension UIImage {
    /// Approximate memory a decoded image uses. Used as its cost in the memory cache.
    nonisolated var decodedByteCount: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
