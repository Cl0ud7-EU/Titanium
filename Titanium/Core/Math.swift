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

extension Float {
    func toRadians() -> Float {
        return self * .pi / 180
    }
}

extension simd_float4x4 {
    init(Translate V: SIMD3<Float>, M: simd_float4x4) {
        self.init(SIMD4<Float>(M[0,0], M[1,0], M[2,0], M[3,0]),
                  SIMD4<Float>(M[0,1], M[1,1], M[2,1], M[3,1]),
                  SIMD4<Float>(M[0,2], M[1,2], M[2,2], M[3,2]),
                  SIMD4<Float>(V.x, V.y, V.z, M[3,3]))
    }
    
    init(Scale V: SIMD3<Float>, M: simd_float4x4) {
        self.init(SIMD4<Float>(M[0,0] * V.x, M[1,0], M[2,0], M[3,0]),
                  SIMD4<Float>(M[0,1], M[1,1] * V.y, M[2,1], M[3,1]),
                  SIMD4<Float>(M[0,2], M[1,2], M[2,2] * V.z, M[3,2]),
                  SIMD4<Float>(M[0,3], M[1,3], M[2,3], M[3,3]))
    }
    
    init(Rotate Quat: SIMD4<Float>) {
        
        let x2 = Quat.x * Quat.x;
        let y2 = Quat.y * Quat.y;
        let z2 = Quat.z * Quat.z;
        let xy = Quat.x * Quat.y;
        let xz = Quat.x * Quat.z;
        let yz = Quat.y * Quat.z;
        let wx = Quat.w * Quat.x;
        let wy = Quat.w * Quat.y;
        let wz = Quat.w * Quat.z;
        
        // Counter Clockwise
        self.init(SIMD4<Float>(1.0 - 2.0 * (y2 + z2), 2.0 * (xy + wz), 2.0 * (xz - wy), 0),
                  SIMD4<Float>(2.0 * (xy - wz), 1.0 - 2.0 * (x2 + z2), 2.0 * (yz + wx), 0),
                  SIMD4<Float>(2.0 * (xz + wy), 2.0 * (yz - wx), 1.0 - 2.0 * (x2 + y2), 0),
                  SIMD4<Float>(0, 0, 0, 1))
        
        // Clockwise
//        self.init(SIMD4<Float>(1.0 - 2.0 * (y2 + z2), 2.0 * (xy - wz), 2.0 * (xz + wy), 0),
//                  SIMD4<Float>(2.0 * (xy + wz), 1.0 - 2.0 * (x2 + z2), 2.0 * (yz - wx), 0),
//                  SIMD4<Float>(2.0 * (xz - wy), 2.0 * (yz + wx), 1.0 - 2.0 * (x2 + y2), 0),
//                  SIMD4<Float>(0, 0, 0, 1))
        

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
    
    init(PerspectiveProjectionFoVY fovYRadians: Float,
         aspectRatio: Float,
         near: Float,
         far: Float)
    {
        let ScaleY = 1 / tan(fovYRadians * 0.5)
        let ScaleX = ScaleY / aspectRatio
        let k: Float = far / (far - near)
        
        self.init(SIMD4<Float>(ScaleX, 0,  0,  0),
                  SIMD4<Float>(0, ScaleY,  0,  0),
                  SIMD4<Float>(0,  0, k, 1),
                  SIMD4<Float>(0,  0, -near * k,  0))
    }
}

func EulerToQuat(Rot: SIMD3<Float>) -> SIMD4<Float> {
    
    let CosX = cos(Rot.x * 0.5)
    let SinX = sin(Rot.x * 0.5)
    let CosY = cos(Rot.y * 0.5)
    let SinY = sin(Rot.y * 0.5)
    let CosZ = cos(Rot.z * 0.5)
    let SinZ = sin(Rot.z * 0.5)
    
    let Qx = CosZ * CosY * SinX - SinZ * SinY * CosX
    let Qy = CosZ * SinY * CosX + SinZ * CosY * SinX
    let Qz = SinZ * CosY * CosX - CosZ * SinY * SinX
    let Qw = CosZ * CosY * CosX + SinZ * SinY * SinX
    
    return (SIMD4<Float>(Qx,Qy,Qz,Qw))
}

func CreateModelViewMatrix(Translation: SIMD3<Float>, Rotation: SIMD3<Float>, Scale: SIMD3<Float>,  Camera: Camera) -> simd_float4x4{
    
    // ModelMatrix
    let ScaleMatrix = DoScale(Scale: Scale)
    
    let RotationMatrix = Rotate(Rotation: Rotation)
    
    let TranslateMatrix = Translate(Translation: Translation)
    
    let ModelMatrix = TranslateMatrix * RotationMatrix * ScaleMatrix
    
    // ViewMatrix
    let ViewMatrix = CreateViewMatrix(Camera: Camera)
    
    let ModelViewMatrix = ViewMatrix * ModelMatrix
    return ModelViewMatrix
}

func CreateViewMatrix(Camera: Camera) -> simd_float4x4 {
    
    // This is a Left-Handed system
    let Up = SIMD3<Float>(0, 1, 0)
    let Forward = GetForwardVector(Rotation: Camera.m_Rotation)
    let Right = normalize(cross(Up, Forward))
    let UpAdjusted = cross(Forward, Right)
    
    let Orientation = matrix_float4x4(columns: (
        SIMD4<Float>(Right, 0),
        SIMD4<Float>(UpAdjusted, 0),
        SIMD4<Float>(Forward, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
    
    let Translation = Translate(Translation: -Camera.m_Position)
        
    return Translation * Orientation
}

func CreatePerspectiveProjMatrix(PerspectiveProjectionFoVY fovYRadians: Float,
                                 aspectRatio: Float,
                                 nearPlane: Float,
                                 farPlane: Float) -> simd_float4x4
{
    let ProjectionMatrix = simd_float4x4(PerspectiveProjectionFoVY: 45.0 * (Float.pi/180),
                                         aspectRatio: aspectRatio,
                                         near: nearPlane,
                                         far: farPlane)
    return ProjectionMatrix
}

func Translate(Translation: SIMD3<Float>) -> simd_float4x4 {
    
    return simd_float4x4(Translate:Translation, M: matrix_identity_float4x4)
}

func Rotate(Rotation: SIMD3<Float>) -> simd_float4x4 {
    
    let RotationInRadians = Rotation * (Float.pi/180)
    let Rotation = EulerToQuat(Rot: RotationInRadians)
    return simd_float4x4(Rotate: Rotation)
}

func DoScale(Scale: SIMD3<Float>) -> simd_float4x4 {
    return simd_float4x4(Scale: Scale, M: matrix_identity_float4x4)
}

func GetForwardVector(Rotation: SIMD3<Float>) -> SIMD3<Float> {
    let RotationMatrix = Rotate(Rotation: Rotation)
    return normalize(SIMD3<Float>(RotationMatrix.columns.2.x, RotationMatrix.columns.2.y, RotationMatrix.columns.2.z))
}
