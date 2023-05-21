//
//  Entity.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation

class Entity {
    
    var m_Translation: SIMD3<Float>
    var m_Rotation: SIMD3<Float>
    var m_Scale: SIMD3<Float>
    let m_Mesh: Mesh
    
    init(Translation: SIMD3<Float>, Rotation: SIMD3<Float>, Scale: SIMD3<Float>, Mesh: Mesh) {
        self.m_Translation = Translation
        self.m_Rotation = Rotation
        self.m_Scale = Scale
        self.m_Mesh = Mesh
    }
}
