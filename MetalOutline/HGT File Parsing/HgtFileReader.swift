import Foundation
import CoreLocation

public struct HgtFileReader {
    static let size = 1201
    static let threeSeconds: Double = 3.0 / 60.0 / 60.0

    public static func read(from path: String) throws -> [[UInt16]] {

        let handle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))

        defer { handle.closeFile() }

        // Calculate all the necessary values
        let unitSize = MemoryLayout<UInt16>.size
        let rowSize = size * unitSize
        let expectedFileSize = size * rowSize

        // Get fileSize
        let fileSize = handle.seekToEndOfFile()

        // Check file size
        guard fileSize == expectedFileSize else {
            throw CocoaError(.fileReadCorruptFile)
        }

        // Go back to the start
        handle.seek(toFileOffset: 0)

        // Iterate
        let matrix: [[UInt16]] = (0..<size).map { rowIndex in
            // Read a row
            let data = handle.readData(ofLength: rowSize)
            // With bytes...
            let row: [UInt16] = data.withUnsafeBytes { (bytes: UnsafePointer<UInt16>) -> [UInt16] in
                // Get the buffer. Count isn't using rowSize because it calculates number of bytes based on data type
                let buffer = UnsafeBufferPointer<UInt16>(start: bytes, count: size)
                // Create an array
                return Array<UInt16>(buffer)
            }
            // Swap little to big endian
            return row.map { CFSwapInt16HostToBig($0) }
        }

        return matrix
    }

    public static func read(from path: String, initialCoordinate: CLLocationCoordinate2D) throws -> HgtTerrainTile {

        let matrix = try read(from: path)

        let tile = HgtTerrainTile(
            initialCoordinate: initialCoordinate,
            step: threeSeconds,
            heightMap: matrix
        )

        return tile
    }
}
