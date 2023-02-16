//
//  PointsPath.swift
//  UserGuidedNFT
//
//  Created by Artem Evdokimov on 16.02.23.
//

import Foundation
import ARKit

extension MainViewController {
    // Create UIBezierPath from the points array
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
    
    // Get array of feature points in the scene
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
    
    // Detect if a point is inside a polygon
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
}
