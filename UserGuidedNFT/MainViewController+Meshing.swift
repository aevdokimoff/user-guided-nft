//
//  Meshing.swift
//  UserGuidedNFT
//
//  Created by Artem Evdokimov on 16.02.23.
//

import Foundation
import ARKit

// MARK: - Meshing

extension MainViewController {
    
    // Add a newly found plane node to a list of nodes
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
}
