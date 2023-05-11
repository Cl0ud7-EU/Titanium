//
//  Draw.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal

class Draw {
    let m_RenderPipelineState: MTLRenderPipelineState
    let m_VertexBuffer: MTLBuffer
    let m_VertexColorBuffer: MTLBuffer
    let m_IndexBuffer: MTLBuffer
    let m_PrimitiveType: MTLPrimitiveType
    let m_IndexCount: Int
    let m_IndexType: MTLIndexType

    init(RenderPipelineState: MTLRenderPipelineState, VertexBuffer: MTLBuffer,
         IndexBuffer: MTLBuffer, VertexColorBuffer:MTLBuffer,
         PrimitiveType: MTLPrimitiveType, IndexCount: Int, IndexType: MTLIndexType) {

        self.m_RenderPipelineState = RenderPipelineState
        self.m_VertexBuffer = VertexBuffer
        self.m_VertexColorBuffer = VertexBuffer
        self.m_IndexBuffer = IndexBuffer
        self.m_PrimitiveType = PrimitiveType
        self.m_IndexCount = IndexCount
        self.m_IndexType = IndexType
    }
}
