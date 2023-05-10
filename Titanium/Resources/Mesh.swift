//
//  Mesh.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal

class Mesh {
    var m_Positions: [SIMD3<Float>]
    var m_Colors: [SIMD4<Float>]
    var m_Indices: [UInt16]
    
    init(Positions: [SIMD3<Float>], Colors: [SIMD4<Float>], Indices: [UInt16]) {
        self.m_Positions = Positions
        self.m_Colors = Colors
        self.m_Indices = Indices
    }
}
