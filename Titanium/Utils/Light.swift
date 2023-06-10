//
//  Light.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal

enum LightType: UInt8 {
    case Directional
}

struct DirectionalLight {
    var m_Direction = SIMD3<Float>(0, 0, 0) // 16
    var m_Color = SIMD3<Float>(1, 1, 1) // 16
    var m_Intensity: Float = 1.0 // 4
    
    init(Direction: SIMD3<Float>, Color: SIMD3<Float>, Intensity: Float) {
        self.m_Direction = Direction
        self.m_Color = Color
        self.m_Intensity = Intensity
    }
}

struct PointLight {
    var m_Position = SIMD3<Float>(0, 0, 0)
    var m_Color = SIMD3<Float>(1, 1, 1)
    var m_Intensity: Float = 1.0
    var m_Radius: Float = 1.0
    
    init(Position: SIMD3<Float>, Color: SIMD3<Float>, Intensity: Float, Radius: Float) {
        self.m_Position = Position
        self.m_Color = Color
        self.m_Intensity = Intensity
        self.m_Radius = Radius
    }
}
