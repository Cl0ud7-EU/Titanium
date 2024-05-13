//
//  Light.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal
import simd

enum LightType: UInt8 {
    case Directional
}

struct DirectionalLight {
    var m_Direction: SIMD3<Float>
    var m_Color: SIMD3<Float>
    var m_Intensity: Float
    
    init(Direction: SIMD3<Float> = SIMD3<Float>(1, 1, -1), //16
         Color: SIMD3<Float> = SIMD3<Float>(1, 1, 1), //16
         Intensity: Float = 1.0) //4
    {
        self.m_Direction = Direction
        self.m_Color = Color
        self.m_Intensity = Intensity
    }
}

struct PointLight {
    // var m_PositionRadius: SIMD4<Float> // Position = XYZ, Radius = W. // Future change
    var m_Position: SIMD3<Float>
    var m_Color: SIMD3<Float>
    var m_Intensity: Float
    var m_Radius: Float
    
    init(Position: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
         Color: SIMD3<Float> = SIMD3<Float>(1, 1, 1),
         Intensity: Float = 1.0,
         Radius: Float = 1.0)
    {
        self.m_Position = Position
        self.m_Color = Color
        self.m_Intensity = Intensity
        self.m_Radius = Radius
    }
}

struct SpotLight {
    var m_Position: SIMD3<Float>
    var m_Direction: SIMD3<Float>
    var m_DirectionViewS: SIMD3<Float>
    var m_ColorAndAngle: SIMD4<Float>
    var m_Intensity: Float
    
    init(Position: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
         Direction: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
         Color: SIMD3<Float> = SIMD3<Float>(1, 1, 1),
         Intensity: Float = 1.0,
         Angle: Float = 20)
    {
        self.m_Position = Position
        self.m_Direction = Direction
        self.m_DirectionViewS = SIMD3<Float>(0, 0, 0);
        self.m_ColorAndAngle = SIMD4<Float>(Color, cos(Angle))
        self.m_Intensity = Intensity
    }
}
