//
//  Mesh.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal

struct Vertex {
    let m_Position: SIMD3<Float>
    let m_Color: SIMD4<Float>
    var m_Normal: SIMD3<Float>
}

class Mesh {
    let m_Positions: [SIMD3<Float>]
    let m_Colors: [SIMD4<Float>]
    let m_Indices: [UInt16]
    let m_NormalsBuffer: MTLBuffer!
    let m_Draw: Draw
    
    init(Positions: [SIMD3<Float>], Colors: [SIMD4<Float>], Indices: [UInt16], Normals: [SIMD3<Float>]) {
        self.m_Positions = Positions
        self.m_Colors = Colors
        self.m_Indices = Indices
        
        self.m_NormalsBuffer = m_Device.makeBuffer(bytes: Normals,
                                                 length: MemoryLayout<SIMD3<Float>>.stride * Normals.count,
                                                 options: .storageModeShared)
        self.m_Draw = Draw(VertexPositions: m_Positions,
                           VertexColors: m_Colors,
                           Indices: m_Indices,
                           PrimitiveType: .triangle,
                           IndexCount: m_Indices.count,
                           IndexType: .uint16)
    }
}
