//
//  Camera.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation

class Camera {
    var m_Position: SIMD3<Float>
    var m_Rotation: SIMD3<Float>
    var m_AspectRatio: Float
    var m_NearPlane: Float
    var m_FarPlane: Float
    var m_Width: Float?
    var m_Height: Float?
    var m_ViewAngle: Float?
    
    init(position: SIMD3<Float> = SIMD3<Float>(1,1,1),
         rotation: SIMD3<Float> = SIMD3<Float>(0,0,1),
         nearPlane: Float = 0.1,
         farPlane: Float = 200.0,
         width: Float = 1280.0,
         height: Float = 720.0) {
        
        self.m_Position = position
        self.m_Rotation = rotation
        self.m_AspectRatio = width / height
        self.m_NearPlane = nearPlane
        self.m_FarPlane = farPlane
        self.m_Width = width
        self.m_Height = height
    
    }
    init(position: SIMD3<Float> = SIMD3<Float>(1,1,1),
         rotation: SIMD3<Float> = SIMD3<Float>(0,0,0),
         nearPlane: Float = 0.1,
         farPlane: Float = 200.0,
         viewAngle: Float = 90.0,
         aspectRatio: Float = 1.0) {
            
        self.m_Position = position
        self.m_Rotation = rotation
        self.m_AspectRatio = aspectRatio
        self.m_NearPlane = nearPlane
        self.m_FarPlane = farPlane
        self.m_ViewAngle = viewAngle
        }
    
    func getViewMatrix(){
        
    }
}
