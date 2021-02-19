//
//  SceneDelegate.swift
//  UserGuidedNFT
//
//  Created by Artem Evdokimov on 03.11.20.
//

import UIKit
import ARKit
import CoreGraphics
import StatusAlert

enum Mode {
    case featureTracking
    case surfacesDetection
}

class MainViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet private weak var sceneView: ARSCNView!
    @IBOutlet private weak var clusteredConvexHullView: UIView!
    @IBOutlet private weak var modeSegmentControl: UISegmentedControl!
    @IBOutlet private weak var markersSwitch: UISwitch!
    
    // MARK: - Private variables
    private var clusteredConvexHullViewWidth = 0
    private var clusteredConvexHullViewHeight = 0
    
    private var screenPath = UIBezierPath()
    private var shape = CAShapeLayer()
    
    private var meshToBoundaryMap = [SCNNode: [SCNVector3]]()
    private var currentlyVisiblePlaneVectors = [SCNVector3]()
    
    private var mode: Mode = .featureTracking
    private var showMarkers = false
    
    private let dbscan = DBSCAN(radius: 60, minNumberOfPointsInCluster: 8, andDistanceCalculator: { (obj1: Any, obj2: Any) -> Float in
        guard let point1: CGPoint = obj1 as? CGPoint, let point2: CGPoint = obj2 as? CGPoint else {
            return 0.0
        }
        let deltaX = point2.x - point1.x
        let deltaY = point2.y - point1.y
        
        return sqrtf(Float(deltaX * deltaX + deltaY * deltaY))
    })
    
    // MARK: - View lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.resetTrackingConfiguration()
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.delegate = self
        self.sceneView.showsStatistics = true
        self.sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]

        self.saveClusteredConvexHullViewSize()
        self.configureLighting()
        self.addTapGestureToSceneView()
    }
    
    func saveClusteredConvexHullViewSize() {
        self.clusteredConvexHullViewHeight = Int(self.clusteredConvexHullView.frame.height)
        self.clusteredConvexHullViewWidth = Int(self.clusteredConvexHullView.frame.width)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.shape = self.generateShape()
        self.clusteredConvexHullView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.clusteredConvexHullView.layer.addSublayer(self.shape)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.sceneView.session.pause()
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Tracking configurarion
    func generateShape() -> CAShapeLayer {
        let shape = CAShapeLayer()
        let screenPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.clusteredConvexHullViewWidth, height: self.clusteredConvexHullViewHeight))
        shape.opacity = 0.5
        shape.lineWidth = 2
        shape.strokeColor = UIColor(hue: 0.787, saturation: 0.78, brightness: 0.52, alpha: 1.0).cgColor
        shape.fillColor = UIColor(hue: 0.787, saturation: 0.14, brightness: 0.90, alpha: 1.0).cgColor
        shape.path = screenPath.cgPath
        return shape
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapGesture(_:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func didReceiveTapGesture(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        print(location)
    }
    
    func configureLighting() {
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.automaticallyUpdatesLighting = true
    }
    
    func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
        self.sceneView.session.pause()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        
        self.sceneView.showsStatistics = true
        self.sceneView.debugOptions = [.showFeaturePoints]
        
        self.sceneView.session.run(configuration, options: options)
    }
    
    // MARK: - Actions
    @IBAction func modeSegmentControlDidChange(_ sender: Any) {
        self.resetTrackingConfiguration()
        let shape = self.generateShape()
        DispatchQueue.main.async {
            self.clusteredConvexHullView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.clusteredConvexHullView.layer.addSublayer(shape)
        }
        
        let index = self.modeSegmentControl.selectedSegmentIndex
        switch index {
        case 0:
            self.presentAlert(imageName: "move-around", title: "Features mode", message: "You need to move your phone around to detect feature points", style: .light, tintColor: .black, duration: 3)
            self.mode = .featureTracking
        case 1:
            self.presentAlert(imageName: "move-around", title: "Surfaces mode", message: "You need to move your phone around to detect horizontal surfaces", style: .light, tintColor: .black, duration: 3)
            self.mode = .surfacesDetection
        default:
            break
        }
    }
    
    @IBAction func markersSwitchDidChange(_ sender: Any) {
        if self.markersSwitch.isOn {
            self.showMarkers = true
        } else {
            self.showMarkers = false
        }
    }
    
    func presentAlert(imageName: String, title: String, message: String, style: UIBlurEffect.Style, tintColor: UIColor, duration: Int) {
        if let image = UIImage(named: imageName) {
            let statusAlert = StatusAlert()
            statusAlert.image = image
            statusAlert.title = title
            statusAlert.message = message
            statusAlert.canBePickedOrDismissed = true
            statusAlert.appearance.blurStyle = style
            statusAlert.appearance.tintColor = tintColor
            statusAlert.alertShowingDuration = 2
            statusAlert.showInKeyWindow()
        }
    }
}

// MARK: - ARSCNViewDelegate
extension MainViewController: ARSCNViewDelegate {
    
    // MARK: - Meshing
    func addMeshNode(node: SCNNode, anchor: ARAnchor) {
        let meshNode : SCNNode
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        guard let device = sceneView.device else {
            return
        }
        guard let meshGeometry = ARSCNPlaneGeometry(device: device) else {
            fatalError("Can't create plane geometry")
        }
        
        meshGeometry.update(from: planeAnchor.geometry)
        meshNode = SCNNode(geometry: meshGeometry)
        // Uncomment the following line to visualize planes detected by ARKit
        // meshNode.opacity = 0.5
        meshNode.opacity = 0.0
        meshNode.name = "MeshNode"
        
        guard let material = meshNode.geometry?.firstMaterial else {
            fatalError("ARSCNPlaneGeometry always has one material")
        }
        material.diffuse.contents = UIColor.blue
        node.addChildNode(meshNode)
    }
    
    func updateMeshNode(node: SCNNode, anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        guard let meshNode = node.childNode(withName: "MeshNode", recursively: false),
              let meshNodeGeometry = meshNode.geometry as? ARSCNPlaneGeometry else {
            return
        }
        meshNodeGeometry.update(from: planeAnchor.geometry)
        
        let planeAnchorGeometry: ARPlaneGeometry = planeAnchor.geometry
        let planeAnchorBoundaryVertices = planeAnchorGeometry.boundaryVertices
        
        // Project boundary vertices on screen
        planeAnchorBoundaryVertices.forEach({ planeAnchorBoundaryVertice in
            let rootNode = self.sceneView.scene.rootNode
            let position = SCNVector3(planeAnchorBoundaryVertice.x, planeAnchorBoundaryVertice.y, planeAnchorBoundaryVertice.z)
            let relativePosition = meshNode.convertPosition(position, to: rootNode)
            self.appendOrCreateMeshToBoundaryMapEntry(key: node, value: relativePosition)
        })
        
        // Leave only currently visible node
        if let currentValue = self.meshToBoundaryMap[node] {
            currentlyVisiblePlaneVectors = currentValue
        }
    }
    
    func appendOrCreateMeshToBoundaryMapEntry(key: SCNNode, value: SCNVector3) {
        if let _ = meshToBoundaryMap[key] {
            meshToBoundaryMap[key]?.append(value)
        } else {
            self.meshToBoundaryMap[key] = [value]
        }
    }
    
    func parseProjectPoints<T>(_ array: [T], renderer: SCNSceneRenderer) -> [CGPoint] {
        var projectPoints: [CGPoint] = [CGPoint]()
        array.forEach { pointLocation in
            if pointLocation is SCNVector3 {
                let pos = renderer.projectPoint(SCNVector3Make((pointLocation as! SCNVector3).x, (pointLocation as! SCNVector3).y, (pointLocation as! SCNVector3).z))
                let projected2DPoint = CGPoint(x: Int(pos.x), y: Int(pos.y))
                projectPoints.append(projected2DPoint)
            } else if pointLocation is vector_float3 {
                let pos = renderer.projectPoint(SCNVector3Make((pointLocation as! vector_float3).x, (pointLocation as! vector_float3).y, (pointLocation as! vector_float3).z))
                let projected2DPoint = CGPoint(x: Int(pos.x), y: Int(pos.y))
                projectPoints.append(projected2DPoint)
            }
        }
        return projectPoints
    }
    
    // MARK: - Rendering
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if (self.mode == .featureTracking) {
            // ...
        } else if (self.mode == .surfacesDetection) {
            self.addMeshNode(node: node, anchor: anchor)
            if self.showMarkers {
                self.visualizeMarkers()
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if (self.mode == .featureTracking) {
            // ...
        } else if (self.mode == .surfacesDetection) {
            self.updateMeshNode(node: node, anchor: anchor)
            if self.showMarkers {
                self.visualizeMarkers()
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if (self.mode == .featureTracking) {
            guard let currentFrame = self.sceneView.session.currentFrame,
            let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }
            self.visualizeFeaturesClustering(featurePointsArray, renderer)
        } else if (self.mode == .surfacesDetection) {
            self.visualizeSurfacesClustering(renderer: renderer)
        }
    }
    
    func visualizeFeaturesClustering(_ featurePointsArray: [vector_float3], _ renderer: SCNSceneRenderer) {
        let projectPoints = parseProjectPoints(featurePointsArray, renderer: renderer)
        
        guard let results: NSArray = self.dbscan?.clusters(fromPoints: projectPoints) as NSArray? else { return }
        
        let screenPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.clusteredConvexHullViewWidth, height: self.clusteredConvexHullViewHeight))
        let shape = self.shape
        
        results.forEach { clusterU in // iterate clusters
            if let cluster = clusterU as? [CGPoint] { // get current cluster
                let convexHullResult = convexHull(cluster)
                
                let path = createPathFromPoints(points: convexHullResult)
                screenPath.append(path.reversing())
                screenPath.usesEvenOddFillRule = false
            }
        }
        shape.path = screenPath.cgPath
        self.reshapeClusteredConvexHullView(shape: shape)
    }
    
    func visualizeSurfacesClustering(renderer: SCNSceneRenderer) {
        let screenPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.clusteredConvexHullViewWidth, height: self.clusteredConvexHullViewHeight))
        let shape = self.shape
        
        if (self.currentlyVisiblePlaneVectors.count > 0) {
            // Show only currently visible plane
            let projectPoints = parseProjectPoints(self.currentlyVisiblePlaneVectors, renderer: renderer)
            let convexHullResult = convexHull(projectPoints)
            
            let path = createPathFromPoints(points: convexHullResult)
            screenPath.append(path.reversing())
            screenPath.usesEvenOddFillRule = false
        }
        
        shape.path = screenPath.cgPath
        self.reshapeClusteredConvexHullView(shape: shape)
    }
    
    // Source: https://stackoverflow.com/a/29345941
    func isPointInsidePlane(polygon: [CGPoint], test: CGPoint) -> Bool {
        if polygon.count <= 1 {
            return false //or if first point = test -> return true
        }
        let p = UIBezierPath()
        let firstPoint = polygon[0] as CGPoint
        p.move(to: firstPoint)
        for index in 1...polygon.count-1 {
            p.addLine(to: polygon[index] as CGPoint)
        }
        p.close()
        return p.contains(test)
    }
    
    func visualizeMarkers() {
        let meshNodes3D = self.sceneView.scene.rootNode.childNodes.filter({
            return ($0.childNode(withName: "MeshNode", recursively: false) == nil) ? false : true
        }).map({
            $0.childNode(withName: "MeshNode", recursively: false)
        })
        
        if meshNodes3D.count < 2 {
            return
        }
        
        self.sceneView.scene.rootNode.childNodes
            .filter({ $0.name == "MarkerNode" })
            .forEach({ $0.removeFromParentNode() })
        
        for from in meshNodes3D {
            for to in meshNodes3D {
                if (to != from), let toU = to, let fromU = from {
                    guard let middlePointWithRespectToOutlines = self.computeMiddlePointWithRespectToOutlines(from: fromU, to: toU) else {
                        return
                    }
                    var isInside = false
                    meshNodes3D.forEach({ mn3d in
                        guard let mn3d = mn3d, let mn3dBoundingSphere = mn3d.geometry?.boundingSphere else {
                            return
                        }
                        let rootNode = self.sceneView.scene.rootNode
                        let mn3dBoundingSphereCenter = mn3d.convertPosition(mn3dBoundingSphere.center, to: rootNode)
                        if (self.distanceBetweenVectors(v1: middlePointWithRespectToOutlines, v2: mn3dBoundingSphereCenter) <= mn3dBoundingSphere.radius) {
                            isInside = true
                        }
                    })
                    
                    if (!isInside) {
                        let markerGeometry = SCNSphere(radius: 0.05)
                        let markerNode = SCNNode(geometry: markerGeometry)
                        markerNode.name = "MarkerNode"
                        markerNode.opacity = 0.8
                        markerNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        markerNode.position = middlePointWithRespectToOutlines
                        self.sceneView.scene.rootNode.addChildNode(markerNode)
                    }
                }
            }
        }
        
    }
    
    func computeMiddlePointWithRespectToOutlines(from: SCNNode, to: SCNNode) -> SCNVector3? {
        let rootNode = self.sceneView.scene.rootNode
        
        let fromSphereCenter = from.convertPosition(from.boundingSphere.center, to: rootNode)
        let toSphereCenter = to.convertPosition(to.boundingSphere.center, to: rootNode)
        
        let toMinusFrom = toSphereCenter - fromSphereCenter
        let fromMinusTo = fromSphereCenter - toSphereCenter
        let fromMinusToNormLengthed = fromMinusTo.normalized() * from.boundingSphere.radius
        let toMinusFromNormLengthed = toMinusFrom.normalized() * to.boundingSphere.radius

        let fromSphereOutlinePoint = fromSphereCenter + fromMinusToNormLengthed
        let toSphereOutlinePoint = toSphereCenter + toMinusFromNormLengthed
        
        return (toSphereOutlinePoint + fromSphereOutlinePoint) / 2
    }
    
    // Source: Adapted from https://stackoverflow.com/a/60397098
    func distanceBetweenNodes(n1: SCNNode, n2: SCNNode) -> Float {
        let end = n1.presentation.worldPosition
        let start = n2.presentation.worldPosition

        let dx = (end.x) - (start.x)
        let dy = (end.y) - (start.y)
        let dz = (end.z) - (start.z)

        return sqrt(pow(dx,2)+pow(dy,2)+pow(dz,2))
    }
    
    // Source: Adapted from https://stackoverflow.com/a/60397098
    func distanceBetweenVectors(v1: SCNVector3, v2: SCNVector3) -> Float {
        let dx = (v1.x) - (v2.x)
        let dy = (v1.y) - (v2.y)
        let dz = (v1.z) - (v2.z)

        return sqrt(pow(dx,2)+pow(dy,2)+pow(dz,2))
    }
    
    func createPathFromPoints(points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        for i in 0...(points.count - 1) {
            if (i == 0) {
                path.move(to: points[i])
            } else {
                path.addLine(to: points[i])
            }
        }
        path.close()
        return path
    }
    
    func reshapeClusteredConvexHullView(shape: CAShapeLayer) {
        DispatchQueue.main.async {
            self.clusteredConvexHullView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.clusteredConvexHullView.layer.addSublayer(shape)
        }
    }
}
