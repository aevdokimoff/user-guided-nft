//
//  MainViewController+.swift
//  UserGuidedNFT
//
//  Created by Artem Evdokimov on 16.02.23.
//

import Foundation
import ARKit

extension MainViewController: ARSCNViewDelegate {
    
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
}
