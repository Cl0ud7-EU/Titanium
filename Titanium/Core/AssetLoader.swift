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
        mdlVertexDescriptor.attribute(1).offset = 12
        mdlVertexDescriptor.attribute(1).bufferIndex = 0
        mdlVertexDescriptor.attribute(2).name = MDLVertexAttributeTextureCoordinate
        mdlVertexDescriptor.attribute(2).format = .float2
        mdlVertexDescriptor.attribute(2).offset = 24
        mdlVertexDescriptor.attribute(2).bufferIndex = 0
        mdlVertexDescriptor.layout(0).stride = 32
        
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
        return Mesh(MTKMesh: mesh, Texture: unwrappedTexture)
    }
}
