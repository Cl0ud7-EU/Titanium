//
//  Math.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import simd

func align(_ value: Int, upTo alignment: Int) -> Int {
    return ((value + alignment - 1) / alignment) * alignment
}

extension simd_float4x4 {
    init(Translate V: SIMD3<Float>, M: simd_float4x4) {
        self.init(SIMD4<Float>(M[0,0], M[1,0], M[2,0], M[3,0]),
                  SIMD4<Float>(M[0,1], M[1,1], M[2,1], M[3,1]),
                  SIMD4<Float>(M[0,2], M[1,1], M[2,2], M[3,2]),
                  SIMD4<Float>(V.x, V.y, V.z, M[3,3]))
    }
    
    init(Scale V: SIMD3<Float>, M: simd_float4x4) {
        self.init(SIMD4<Float>(M[0,0] * V.x, M[1,0], M[2,0], M[3,0]),
                  SIMD4<Float>(M[0,1], M[1,1] * V.y, M[2,1], M[3,1]),
                  SIMD4<Float>(M[0,2], M[1,2], M[2,2] * V.z, M[3,2]),
                  SIMD4<Float>(M[0,3], M[1,3], M[2,3], M[3,3]))
    }
    
    init(OrthographicProjection right: Float, left: Float, top: Float, bottom: Float, near: Float, far: Float)
    {
        let ScaleX: Float = 2 / (right - left)
        let ScaleY: Float = 2 / (top - bottom)
        let ScaleZ: Float = 1 / (near - far)
        let TransX: Float = (left + right) / (left - right)
        let TransY: Float = (top + bottom) / (bottom - top)
        let TransZ: Float = near / (near - far)
        self.init(SIMD4<Float>(ScaleX,  0,  0, 0),
                  SIMD4<Float>( 0, ScaleY,  0, 0),
                  SIMD4<Float>( 0,  0, ScaleZ, 0),
                  SIMD4<Float>( TransX, TransY, TransZ, 1))
    }
}
