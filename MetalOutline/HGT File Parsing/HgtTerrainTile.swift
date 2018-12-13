import CoreLocation

public struct HgtTerrainTile {
    // SouthWest (bottom left) initial coordinate
    public let initialLocation: CLLocation
    // Step between two HGT values
    public let step: CLLocationDegrees
    // Average distance in between two values
    public let longitudeStepDistance: CLLocationDistance
    public let latitudeStepDistance: CLLocationDistance
    // Array of altitudes
    public let heightMap: [[UInt16]]
    // Size of the tile
    public let size: Int

    init(initialCoordinate: CLLocationCoordinate2D, step: CLLocationDegrees, heightMap: [[UInt16]]) {
        let initialCoordinateAltitude: Double = Double(heightMap.last?[0] ?? 0)

        // init with CLLocation object
        self.initialLocation = CLLocation(
            coordinate: initialCoordinate,
            altitude: initialCoordinateAltitude,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date()
        )
        self.step = step
        self.heightMap = heightMap
        self.size = heightMap.count
        self.longitudeStepDistance = HgtTerrainTile.longitudeStepDistance(with: initialCoordinate, steps: self.size)
        self.latitudeStepDistance = HgtTerrainTile.latitudeStepDistance(with: initialCoordinate, steps: self.size)
    }

    public func height(of location: CLLocation) -> UInt16? {
        let (xOffset, y) = offset(of: location)
        let yOffset = size - 1 - y

        // Check if not out of bounds
        guard yOffset >= 0 && yOffset < size &&
            xOffset >= 0 && xOffset < size else {
            return nil
        }

        return heightMap[yOffset][xOffset]
    }

    func offset(of location: CLLocation) -> (Int, Int) {
        let coordinate = location.coordinate
        let initialCoordinate = initialLocation.coordinate

        // Calculate deltas of coordinates
        let latitudeDelta = coordinate.latitude - initialCoordinate.latitude
        let longitudeDelta = coordinate.longitude - initialCoordinate.longitude

        // Calculate offset from delta by dividing with step
        let latitudeOffset = Int((latitudeDelta / step).rounded(.toNearestOrEven))
        let longitudeOffset = Int((longitudeDelta / step).rounded(.toNearestOrEven))


        return (longitudeOffset, latitudeOffset)
    }

    static func longitudeStepDistance(with coordinate: CLLocationCoordinate2D, steps: Int) -> CLLocationDistance {
        let bottomLeft = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let bottomRight = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude + 1)
        let topLeft = CLLocation(latitude: coordinate.latitude + 1, longitude: coordinate.longitude)
        let topRight = CLLocation(latitude: coordinate.latitude + 1, longitude: coordinate.longitude + 1)

        let doubleSteps = Double(steps)
        let bottomLeftToRightStepDistance = bottomLeft.distance(from: bottomRight) / doubleSteps
        let topLeftToRightStepDistance = topLeft.distance(from: topRight) / doubleSteps

        return (bottomLeftToRightStepDistance + topLeftToRightStepDistance) / 2
    }

    static func latitudeStepDistance(with coordinate: CLLocationCoordinate2D, steps: Int) -> CLLocationDistance {
        let bottomLeft = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let bottomRight = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude + 1)
        let topLeft = CLLocation(latitude: coordinate.latitude + 1, longitude: coordinate.longitude)
        let topRight = CLLocation(latitude: coordinate.latitude + 1, longitude: coordinate.longitude + 1)

        let doubleSteps = Double(steps)
        let leftBottomToTopStepDistance = bottomLeft.distance(from: topLeft) / doubleSteps
        let rightBottomToTopStepDistance = bottomRight.distance(from: topRight) / doubleSteps

        return (leftBottomToTopStepDistance + rightBottomToTopStepDistance) / 2
    }
}
