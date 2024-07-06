//
//  SceneManager.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import simd

class Scene {
    
    var m_Entities: [Entity] = []
    var m_PointLights: [PointLight] = []
    var m_SpotLights: [SpotLight] = []
    var m_Cameras: [Camera] = []
    let m_AssetLoader: AssetLoader
    
    init() {
        self.m_AssetLoader = AssetLoader()
        
    }
    func LoadScene() {
        
        CreateCamera()
        
        var entity = Entity(Translation: SIMD3<Float>(-10,-2, 35), Rotation: SIMD3<Float>(0,-90,0), Scale: SIMD3<Float>(0.05,0.05,0.05), Mesh: m_AssetLoader.LoadAsset(Path: "Utah_Teapot"))
        m_Entities.append(entity)
        
        entity = Entity(Translation: SIMD3<Float>(10,0,35), Rotation: SIMD3<Float>(0,-90,0), Scale: SIMD3<Float>(3,3,3), Mesh: m_AssetLoader.LoadAsset(Path: "Box"))
        m_Entities.append(entity)
        
        
        CreatePointLight(Position: SIMD3<Float>(12.0, 0.0, 35.0), Color: SIMD3<Float>(1.0, 0.0, 0.0), Intensity: 1.0, Radius: 5)
        
        //CreatePointLight(Position: SIMD3<Float>(-250.0, 100.0, 300), Color: SIMD3<Float>(0.0, 1.0, 0.0), Intensity: 1.0, Radius: 20.5)
        CreatePointLight(Position: SIMD3<Float>(-12.0, 0.0, 35.0), Color: SIMD3<Float>(0.0, 1.0, 0.0), Intensity: 1.0, Radius: 5.5)
        
        CreatePointLight(Position: SIMD3<Float>(-12.0, 0.0, 35.0), Color: SIMD3<Float>(0.0, 1.0, 0.0), Intensity: 1.0, Radius: 5.5)
        
        CreateSpotLight(Position: SIMD3<Float>(-10.0, 0.0, 0.0), Direction: SIMD3<Float>(0.0, 0.0, 0.0), Color: SIMD3<Float>(0.0, 1.0, 0.0), Intensity: 1.0, Angle: 50);
        //CreateSpotLight(Position: SIMD3<Float>(0.0, 5.0, 35.0), Direction: SIMD3<Float>(-1.0, 0.5, 0.1), Color: SIMD3<Float>(1.0, 0.0, 0.0), Intensity: 1.0, Angle: 5);
        
        entity = Entity(Translation: SIMD3<Float>(0,-100,300), Rotation: SIMD3<Float>(90, 0, 0), Scale: SIMD3<Float>(200,200,200), Mesh: m_AssetLoader.createQuadMesh()!)
        m_Entities.append(entity)
        entity = Entity(Translation: SIMD3<Float>(0,100,300), Rotation: SIMD3<Float>(-90, 0, 0), Scale: SIMD3<Float>(200,200,200), Mesh: m_AssetLoader.createQuadMesh()!)
        m_Entities.append(entity)
        entity = Entity(Translation: SIMD3<Float>(180,0,300), Rotation: SIMD3<Float>(0, 90, 0), Scale: SIMD3<Float>(200,200,200), Mesh: m_AssetLoader.createQuadMesh()!)
        m_Entities.append(entity)
        entity = Entity(Translation: SIMD3<Float>(-180,0,300), Rotation: SIMD3<Float>(0, -90, 0), Scale: SIMD3<Float>(200,200,200), Mesh: m_AssetLoader.createQuadMesh()!)
        m_Entities.append(entity)
        entity = Entity(Translation: SIMD3<Float>(0,0,300), Rotation: SIMD3<Float>(0, 0, 0), Scale: SIMD3<Float>(200,200,200), Mesh: m_AssetLoader.createQuadMesh()!)
        m_Entities.append(entity)
        
    }
    
    func CreateCamera()
    {
        m_Cameras.append(Camera(position: SIMD3<Float>(0,0,-60), nearPlane: 0.1, farPlane: 1000, width: 1280, height: 720))
    }
    
    func CreateSpotLight(Position: SIMD3<Float>, Direction: SIMD3<Float>, Color: SIMD3<Float>, Intensity: Float, Angle: Float) {
        m_SpotLights.append(SpotLight(Position: Position, Direction: Direction, Color: Color, Intensity: Intensity, Angle: Angle))
    }
    
    func CreatePointLight(Position: SIMD3<Float>, Color: SIMD3<Float>, Intensity: Float, Radius: Float) {
        m_PointLights.append(PointLight(Position: Position, Color: Color, Intensity: Intensity, Radius: Radius))
    }
    
    // Simple function to apply rotation at Y clockwise
    func ApplyRotationY(Entity: Entity, DeltaTime: Float) {
        let rotationSpeed: Float = 20.0
        let rotationDelta = rotationSpeed * DeltaTime
        
        Entity.m_Rotation.y += rotationDelta // Update only the Y rotation for clockwise rotation
                
        // Ensure rotation stays within 0 to 2*pi range
        //Entity.m_Rotation.y = fmod(Entity.m_Rotation.y, .pi * 2)
    }

    
//    func CreateCube(Translation: SIMD3<Float>, Rotation: SIMD3<Float>, Scale: SIMD3<Float>) {
//
//        let Positions = [
//            SIMD3<Float>(-1.0, -1.0, -1.0),
//            SIMD3<Float>(1.0, -1.0, -1.0),
//            SIMD3<Float>(1.0, 1.0, -1.0),
//            SIMD3<Float>(1.0, 1.0, 1.0),
//            SIMD3<Float>(1.0, -1.0, 1.0),
//            SIMD3<Float>(-1.0, 1.0, -1.0),
//            SIMD3<Float>(-1.0, 1.0, 1.0),
//            SIMD3<Float>(-1.0, -1.0, 1.0)
//        ]
//
//        let Colors = [
//            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
//            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
//            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
//            SIMD4<Float>(1.0, 0.0, 1.0, 1.0),
//            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
//            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
//            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
//            SIMD4<Float>(1.0, 0.0, 1.0, 1.0)
//        ]
//
//        let Indices: [UInt16] = [
//            // Front face
//            0, 16, 3,    // Triangle 1
//            3, 16, 6,    // Triangle 2
//
//            // Back face
//            12, 11, 21,    // Triangle 1
//            11, 18, 21,    // Triangle 2
//
//            // Top face
//            15, 19, 7,    // Triangle 1
//            7, 19, 10,    // Triangle 2
//
//            // Bottom face
//            4, 13, 1,    // Triangle 1
//            23, 1, 13,    // Triangle 2
//
//            // Left face
//            2, 20, 17,    // Triangle 1
//            2, 22, 20,    // Triangle 2
//
//            // Right face
//            5, 8, 14,    // Triangle 1
//            9, 14, 8     // Triangle 2
//        ]
//
//        var vertices: [Vertex] = []
//        var normal = SIMD3<Float>(0,0,0)
//        // Create Verts
//        for i in 0...7
//        {
//            for e in 0...2
//            {
//                vertices.append(Vertex(m_Position: Positions[i], m_Normal: normal, m_Color: Colors[i]))
//            }
//        }
//
//        // Calculate normal per vertex
//        for i in stride(from: 0, to: Indices.count-1, by: 3*2)
//        {
//            var vertexCalculated: [UInt16] = []
//            let vectorA = vertices[Int(Indices[i+1])].m_Position - vertices[Int(Indices[i])].m_Position
//            let vectorB = vertices[Int(Indices[i+2])].m_Position - vertices[Int(Indices[i])].m_Position
////
//            let normal = normalize(simd_cross(vectorB, vectorA))
//            for index in 0...5
//            {
//                if (!vertexCalculated.contains(Indices[index+i]))
//                {
//                    vertices[Int(Indices[index+i])].m_Normal = normal
//                    vertexCalculated.append(Indices[index+i])
//                }
//            }
//        }
//
//        var PosArray: [SIMD3<Float>] = []
//        var ColorArray: [SIMD4<Float>] = []
//        var NormalArray: [SIMD3<Float>] = []
////
//        for vert in vertices
//        {
//            PosArray.append(vert.m_Position)
//            ColorArray.append(vert.m_Color)
//            NormalArray.append(vert.m_Normal)
//        }
//        //m_Entities.append(Entity(Translation: Translation, Rotation: Rotation, Scale: Scale, Mesh: Mesh(MTKMesh: ())))
//    }
}
