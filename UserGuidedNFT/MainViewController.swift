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
    
    // MARK: - Outlets
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var clusteredConvexHullView: UIView!
    @IBOutlet weak var modeSegmentControl: UISegmentedControl!
    @IBOutlet weak var markersSwitch: UISwitch!
    
    // MARK: - Global variables
    
    var clusteredConvexHullViewWidth = 0
    var clusteredConvexHullViewHeight = 0
    
    var screenPath = UIBezierPath()
    var shape = CAShapeLayer()
    
    var meshToBoundaryMap = [SCNNode: [SCNVector3]]()
    var currentlyVisiblePlaneVectors = [SCNVector3]()
    
    var mode: Mode = .featureTracking
    var showMarkers = false
    
    let dbscan = DBSCAN(radius: 60, minNumberOfPointsInCluster: 8, andDistanceCalculator: { (obj1: Any, obj2: Any) -> Float in
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
