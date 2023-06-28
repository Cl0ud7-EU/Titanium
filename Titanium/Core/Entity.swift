//
//  Entity.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import MetalKit

class Entity {
    
    var m_Translation: SIMD3<Float>
    var m_Rotation: SIMD3<Float>
    var m_Scale: SIMD3<Float>
    var m_Mesh: Mesh
    
    init(Translation: SIMD3<Float> = SIMD3<Float>(0,0,0),
         Rotation: SIMD3<Float> = SIMD3<Float>(0,0,0),
         Scale: SIMD3<Float> = SIMD3<Float>(1,1,1),
         Mesh: Mesh)
    {
        
        self.m_Translation = Translation
        self.m_Rotation = Rotation
        self.m_Scale = Scale
        self.m_Mesh = Mesh
    }
}
