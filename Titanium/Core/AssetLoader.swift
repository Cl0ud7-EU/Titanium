//
//  AssetLoader.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal
import MetalKit

class AssetLoader {
    
    var vertexDescriptor: MTLVertexDescriptor!
    func LoadAsset(Path: String, Extension: String = "obj") -> Mesh
    {
        let allocator = MTKMeshBufferAllocator(device: g_Device)
        
        let mdlVertexDescriptor = MDLVertexDescriptor()
        mdlVertexDescriptor.attribute(0).name = MDLVertexAttributePosition
        mdlVertexDescriptor.attribute(0).format = .float3
        mdlVertexDescriptor.attribute(0).offset = 0
        mdlVertexDescriptor.attribute(0).bufferIndex = 0
        
        mdlVertexDescriptor.attribute(1).name = MDLVertexAttributeNormal
        mdlVertexDescriptor.attribute(1).format = .float3
        mdlVertexDescriptor.attribute(1).offset = MemoryLayout<SIMD3<Float>>.stride
        mdlVertexDescriptor.attribute(1).bufferIndex = 0
        
        mdlVertexDescriptor.attribute(2).name = MDLVertexAttributeTextureCoordinate
        mdlVertexDescriptor.attribute(2).format = .float4
        mdlVertexDescriptor.attribute(2).offset = MemoryLayout<SIMD3<Float>>.stride * 2
        mdlVertexDescriptor.attribute(2).bufferIndex = 0
        
        mdlVertexDescriptor.layout(0).stride = MemoryLayout<Vertex>.stride
        
        vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlVertexDescriptor)!
        
        let assetURL = Bundle.main.url(forResource: Path, withExtension: Extension)
        let mdlAsset = MDLAsset(url: assetURL, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: allocator)
        
        mdlAsset.loadTextures()
        
        let meshes = mdlAsset.childObjects(of: MDLMesh.self) as? [MDLMesh]
        guard let mdlMesh = meshes?.first else {
            fatalError("Did not find any meshes in the Model I/O asset")
        }
        
        let textureLoader = MTKTextureLoader(device: g_Device)
        let options: [MTKTextureLoader.Option : Any] = [
            .textureUsage : MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode : MTLStorageMode.private.rawValue,
            .origin : MTKTextureLoader.Origin.bottomLeft.rawValue
        ]
        
        var texture: MTLTexture?
        let firstSubmesh = mdlMesh.submeshes?.firstObject as? MDLSubmesh
        let material = firstSubmesh?.material
        if let baseColorProperty = material?.property(with: MDLMaterialSemantic.baseColor) {
            if baseColorProperty.type == .texture, let textureURL = baseColorProperty.urlValue {
                texture = try? textureLoader.newTexture(URL: textureURL, options: options)
            }
        }
        let mesh = try! MTKMesh(mesh: mdlMesh, device: g_Device)
        
   
        guard let unwrappedTexture = texture else {
            return Mesh(MTKMesh: mesh)
        }
        //return Mesh(MTKMesh: mesh)
        return Mesh(MTKMesh: mesh, Texture: unwrappedTexture)
    }

    func createQuadMesh() -> Mesh? {
        // Define vertices of the quad
        let vertices = [
            Vertex(m_Position: SIMD3<Float>(-1, 1, 0.0), m_Normal: SIMD3<Float>(0, 0, -1), m_Color: simd_float4(1, 1, 1, 1)), // Top Left
            Vertex(m_Position: SIMD3<Float>(1, 1, 0), m_Normal: SIMD3<Float>(0, 0, -1), m_Color: simd_float4(1, 1, 1, 1)), // Top Right
            Vertex(m_Position: SIMD3<Float>(1, -1, 0), m_Normal: SIMD3<Float>(0, 0, -1), m_Color: simd_float4(1, 1, 1, 1)), // Bottom Right
            Vertex(m_Position: SIMD3<Float>(-1, -1, 0), m_Normal: SIMD3<Float>(0, 0, -1), m_Color: simd_float4(1, 1, 1, 1)) // Bottom Left
        ]
        
        print ("simdFloat3", MemoryLayout<SIMD3<Float>>.stride)
        print ("MTLPackedFloat3", MemoryLayout<MTLPackedFloat3>.stride)
        print ("simdfloat4", MemoryLayout<simd_float4>.stride)
        print ("simdFloat4", MemoryLayout<SIMD4<Float>>.stride)
        print ("simdpackedfloat4", MemoryLayout<simd_packed_float4>.stride)
        // Define indices of the quad
        let indices: [UInt16] = [
            0, 1, 2,
            0, 2, 3
        ]
        
        // Create vertex descriptor
        let mdlVertexDescriptor = MDLVertexDescriptor()
        mdlVertexDescriptor.attribute(0).name = MDLVertexAttributePosition
        mdlVertexDescriptor.attribute(0).format = .float3
        mdlVertexDescriptor.attribute(0).offset = 0
        mdlVertexDescriptor.attribute(0).bufferIndex = 0
        
        mdlVertexDescriptor.attribute(1).name = MDLVertexAttributeNormal
        mdlVertexDescriptor.attribute(1).format = .float3
        mdlVertexDescriptor.attribute(1).offset = 12
        mdlVertexDescriptor.attribute(1).bufferIndex = 0
        
        mdlVertexDescriptor.attribute(2).name = MDLVertexAttributeTextureCoordinate
        mdlVertexDescriptor.attribute(2).format = .float4
        mdlVertexDescriptor.attribute(2).offset = 32
        mdlVertexDescriptor.attribute(2).bufferIndex = 0
        
        mdlVertexDescriptor.layout(0).stride = 48
        
        let indicesData = Data(bytes: indices, count: MemoryLayout<UInt16>.stride * indices.count)
        let vertexData = Data(bytes: vertices, count: 48 * vertices.count)
        //mdlVertexDescriptor.setPackedOffsets();
        //vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlVertexDescriptor)!
        let mtkMeshBufferAlloc = MTKMeshBufferAllocator(device: g_Device)
        
        //let indexBuffer: MDLMeshBuffer
        let indexBuffer: MTKMeshBuffer
        do {
            //indexBuffer = mdlMeshBufferAlloc.newBuffer(with: indicesData, type: .index)
            indexBuffer = mtkMeshBufferAlloc.newBuffer(with: indicesData, type: .index) as! MTKMeshBuffer
        } catch {
            print("Failed to create MDLIndexBuffer: \(error)")
            return nil
        }
        // Create vertex descriptor
        let subMesh = MDLSubmesh(indexBuffer: indexBuffer,
                                 indexCount: indices.count,
                                 indexType: .uint16,
                                 geometryType: .triangles,
                                 material: nil)
        
        
        //let mtkMeshBufferAlloc = MTKMeshBufferAllocator(device: g_Device)
                
        //let vertexBuffer: MDLMeshBuffer
        let vertexBuffer: MTKMeshBuffer
        do {
            //vertexBuffer = mdlMeshBufferAlloc.newBuffer(with: vertexData, type: .vertex)
            vertexBuffer =  mtkMeshBufferAlloc.newBuffer(with: vertexData, type: .vertex) as! MTKMeshBuffer

        } catch {
            print("Failed to create MDLVertexBuffer: \(error)")
            return nil
        }
        // Create MTKMesh
        let mdlMesh = MDLMesh(vertexBuffer: vertexBuffer,
                              vertexCount: vertices.count,
                              descriptor: mdlVertexDescriptor, //check this
                              submeshes: [subMesh])
        //let mesh = MTKMesh(vertexBuffers: [vertexBuffer!], vertexDescriptor: MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)!, submeshes: [submesh])
        
        
        // Convert MDLMesh to MTKMesh
//        do {
//            
//        } catch {
//            print("Failed to create MTKMesh: \(error)")
//            return nil
//        }
        let mesh = try! MTKMesh(mesh: mdlMesh, device: g_Device)
        return Mesh(MTKMesh: mesh)
        
       
    }
}
