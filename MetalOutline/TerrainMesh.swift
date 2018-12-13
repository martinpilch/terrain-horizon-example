import CoreLocation
import Foundation
import SceneKit

// -----------------------------------------------------------------------------

class TerrainMesh: SCNNode {

    private let terrainTile: HgtTerrainTile
    let terrainGeometry: SCNGeometry?

    var initialLocation: CLLocation {
        return terrainTile.initialLocation
    }

    func height(of location: CLLocation) -> UInt16? {
        return terrainTile.height(of: location)
    }

    static func createVertices(terrain: HgtTerrainTile) -> [SCNVector3] {
        let size = terrain.size
        let w: CGFloat = CGFloat(size)
        let h: CGFloat = CGFloat(size)
        let maxElements: Int = size * size * 4

        var vertices: [SCNVector3] = []
        vertices.reserveCapacity(maxElements)

        var vertexCount = 0
        let factor: CGFloat = 0.5
        let longitudeFactor: CGFloat = CGFloat(terrain.longitudeStepDistance) * factor
        let latitudeFactor: CGFloat = CGFloat(terrain.latitudeStepDistance) * factor

        for z in 0...Int(h-2) {
            for x in 0...Int(w-2) {
                /// We are taking rows in reverse order
                /// It's due to the fact rows in heightMap are ordered from north to south
                /// and we need to render them from south to north
                let zIndex = Int(h) - 2 - z
                let topLeftY = CGFloat(terrain.heightMap[zIndex][x])
                let topRightY = CGFloat(terrain.heightMap[zIndex][x + 1])
                let bottomLeftY = CGFloat(terrain.heightMap[zIndex + 1][x])
                let bottomRightY = CGFloat(terrain.heightMap[zIndex + 1][x + 1])

                let floatX = CGFloat(x) * CGFloat(terrain.longitudeStepDistance)
                let floatZ = CGFloat(z) * CGFloat(terrain.latitudeStepDistance)

                let topLeft = SCNVector3Make(floatX - longitudeFactor, topLeftY, floatZ + latitudeFactor)
                let topRight = SCNVector3Make(floatX + longitudeFactor, topRightY, floatZ + latitudeFactor)
                let bottomLeft = SCNVector3Make(floatX - longitudeFactor, bottomLeftY, floatZ - latitudeFactor)
                let bottomRight = SCNVector3Make(floatX + longitudeFactor, bottomRightY, floatZ - latitudeFactor)

                vertices.append(bottomLeft)
                vertices.append(topLeft)
                vertices.append(topRight)
                vertices.append(bottomRight)

                vertexCount += 4
            }
        }

        return vertices
    }

    static func createNormals(vertices: [SCNVector3]) -> [SCNVector3] {

        let maxElements: Int = vertices.count

        var normals: [SCNVector3] = []
        normals.reserveCapacity(maxElements)

        for index in stride(from: 0, to: maxElements, by: 4) {
            let vectorA = vertices[index]
            let vectorB = vertices[index + 1]
            let vectorC = vertices[index + 2]

            let side1 = vectorB - vectorA
            let side2 = vectorC - vectorA

            let normal = side1.cross(vector: side2)

            // Append four times for each corner
            normals.append(normal)
            normals.append(normal)
            normals.append(normal)
            normals.append(normal)
        }

        return normals
    }

    static func createGeometryData(terrain: HgtTerrainTile) -> NSMutableData {
        let geometryData = NSMutableData()

        let size = terrain.size
        let maxElements: CInt = CInt(size * size * 4)

        var geometry: CInt = 0
        let sizeOfCInt = MemoryLayout.size(ofValue: geometry)
        while (geometry < maxElements) {
            let bytes: [CInt] = [geometry, geometry+2, geometry+3, geometry, geometry+1, geometry+2]
            geometryData.append(bytes, length: sizeOfCInt*6)
            geometry += 4
        }

        return geometryData
    }

    // -------------------------------------------------------------------------
    // MARK: - Geometry creation

    static func createGeometry(terrain: HgtTerrainTile, color: NSColor) -> SCNGeometry {

        var sources = [SCNGeometrySource]()
        var elements = [SCNGeometryElement]()

        // Create vertices
        let vertices = createVertices(terrain: terrain)
        let vertexCount = vertices.count

        sources.append(SCNGeometrySource(vertices: vertices))

        // Create normals
        let normals = createNormals(vertices: vertices)
        sources.append(SCNGeometrySource(normals: normals))

        // Create triangles using geometry data
        let geometryData = createGeometryData(terrain: terrain)
        let sizeOfCInt = MemoryLayout.size(ofValue: CInt(0))
        let element = SCNGeometryElement(data: geometryData as Data, primitiveType: .triangles, primitiveCount: vertexCount/2, bytesPerIndex: sizeOfCInt)
        elements.append(element)

        // Create geometry out of vertices, normals and geometry data
        let terrainGeometry = SCNGeometry(sources: sources, elements: elements)

        // Adjust material properties
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.ambient.contents = color
        material.specular.contents = NSColor.white
        material.emission.contents = NSColor.darkGray
        material.lightingModel = .phong

        terrainGeometry.firstMaterial = material

        return terrainGeometry
    }

    // -------------------------------------------------------------------------
    // MARK: - Initialisation

    init(terrain: HgtTerrainTile, color: NSColor = NSColor.lightGray) {
        self.terrainTile = terrain
        self.terrainGeometry = TerrainMesh.createGeometry(terrain: terrain, color: color)

        super.init()

        let terrainNode = SCNNode(geometry: terrainGeometry)
        addChildNode(terrainNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // -------------------------------------------------------------------------
}
