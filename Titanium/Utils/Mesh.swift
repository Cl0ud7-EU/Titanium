//
//  Mesh.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import MetalKit

struct Vertex {
    let m_Position: SIMD3<Float>
    var m_Normal: SIMD3<Float>
    let m_Color: SIMD4<Float>
}

struct Mesh {
    var m_MTKMesh: MTKMesh
    var m_Texture: MTLTexture?
    
    init(MTKMesh: MTKMesh) {
        self.m_MTKMesh = MTKMesh
    }
    
    init(MTKMesh: MTKMesh, Texture: MTLTexture) {
        self.m_MTKMesh = MTKMesh
        self.m_Texture = Texture
    }
}
