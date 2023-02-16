//
//  DistanceCalculation.swift
//  UserGuidedNFT
//
//  Created by Artem Evdokimov on 16.02.23.
//

import Foundation
import ARKit

extension MainViewController {
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
}
