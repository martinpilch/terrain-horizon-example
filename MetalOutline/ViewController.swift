
import Cocoa
import CoreLocation
import SceneKit
import SceneKit.ModelIO

class ViewController: NSViewController {
    
    var sceneView: SCNView {
        return self.view as! SCNView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true

        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.backgroundColor = NSColor.lightGray

        let path = Bundle.main.path(forResource: "N49E016", ofType: "hgt")!
        let initialCoordinate = CLLocationCoordinate2D(latitude: 49, longitude: 16)
        let terrainTile = try! HgtFileReader.read(from: path, initialCoordinate: initialCoordinate)
        let node = SCNNode(geometry: TerrainMesh(terrain: terrainTile).terrainGeometry)

        scene.rootNode.addChildNode(node)

        let cameraNode = SCNNode()
        let camera = SCNCamera()
        cameraNode.camera = camera
        sceneView.pointOfView = cameraNode
        camera.fieldOfView = 40
        camera.zFar = 400000
        sceneView.pointOfView?.position = SCNVector3(20000, 1000, 20000)
        sceneView.pointOfView?.look(at: SCNVector3(-20000, 500, 20000))

        node.geometry?.firstMaterial?.diffuse.contents = NSColor(red: 1, green: 0, blue: 0, alpha: 1)
        node.geometry?.firstMaterial?.specular.contents = NSColor.white
        node.geometry?.firstMaterial?.shininess = 25
        node.geometry?.firstMaterial?.lightingModel = .phong
    }
}
