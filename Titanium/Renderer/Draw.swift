//
//  Draw.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal

class Draw {
    
    let m_VertexBuffer: MTLBuffer
    let m_VertexColorBuffer: MTLBuffer
    let m_IndexBuffer: MTLBuffer
    let m_PrimitiveType: MTLPrimitiveType
    let m_IndexCount: Int
    let m_IndexType: MTLIndexType

    init(VertexPositions: [SIMD3<Float>], VertexColors: [SIMD4<Float>], Indices: [UInt16],
         PrimitiveType: MTLPrimitiveType, IndexCount: Int, IndexType: MTLIndexType) {

        self.m_VertexBuffer = m_Device.makeBuffer(bytes: VertexPositions,
                                                  length: MemoryLayout<SIMD3<Float>>.stride * VertexPositions.count,
                                                  options: .storageModeShared)!
        
        self.m_VertexColorBuffer = m_Device.makeBuffer(bytes: VertexColors,
                                                       length: MemoryLayout<SIMD4<Float>>.stride * VertexColors.count,
                                                       options: .storageModeShared)!
        
        self.m_IndexBuffer = m_Device.makeBuffer(bytes: Indices,
                                                 length: MemoryLayout<UInt16>.size * Indices.count,
                                                 options: .storageModeShared)!
        self.m_PrimitiveType = PrimitiveType
        self.m_IndexCount = IndexCount
        self.m_IndexType = IndexType
    }
}
