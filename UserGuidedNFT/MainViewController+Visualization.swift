//
//  ClusteringVisualization.swift
//  UserGuidedNFT
//
//  Created by Artem Evdokimov on 16.02.23.
//

import Foundation
import UIKit
import ARKit

extension MainViewController {
    
    // Visualize features clustering
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
    
    // Visualize surfaces clustering
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
    
    // Visualize Markers
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
    
    // Adapt view with the new clustering information
    func reshapeClusteredConvexHullView(shape: CAShapeLayer) {
        DispatchQueue.main.async {
            self.clusteredConvexHullView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = shape.path
            
            shapeLayer.opacity = 0.5
            shapeLayer.fillColor = UIColor(hue: 0.787, saturation: 0.14, brightness: 0.90, alpha: 1.0).cgColor
            shapeLayer.strokeColor = UIColor(hue: 0.787, saturation: 0.78, brightness: 0.52, alpha: 1.0).cgColor
            shapeLayer.lineWidth = 2.0
            
            self.clusteredConvexHullView.layer.addSublayer(shapeLayer)
        }
    }
}
