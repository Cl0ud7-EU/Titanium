//
//  Renderer.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal
import MetalKit
import simd

let g_MaxFramesInFlight = 3;

var g_Device: MTLDevice!

struct EntityConstants {
    var m_ModelMatrix: simd_float4x4
    var m_ModelViewMatrix: simd_float4x4
}

struct FrameConstants {
    var m_ProjectionMatrix: simd_float4x4
    var m_ViewMatrix: simd_float4x4
    var m_CameraPosition: SIMD3<Float>
    var m_PointLightCount: UInt32
    var m_SpotLightCount: UInt32
}

class Renderer: NSObject, MTKViewDelegate {
    
    let m_CommandQueue: MTLCommandQueue!
    let m_View: MTKView!

    private var m_Library: MTLLibrary!
    private var m_RenderPipelineState: MTLRenderPipelineState!
    private var m_DepthStencilState: MTLDepthStencilState!
    private var m_SamplerState: MTLSamplerState!
    
    private var m_FrameSempahore = DispatchSemaphore(value: g_MaxFramesInFlight)
    private var m_FrameIndex: Int
    
    private var m_Scene: Scene
    
    private var m_CameraPosition = SIMD3<Float>(0, 0, 0)
    
    // FrameConstants
    private var m_ConstantBuffer: MTLBuffer!
    private let m_ConstantsSize: Int
    private let m_ConstantsStride: Int
    private var m_ConstantsBufferOffset: Int
    
    // EntityConstants
    private var m_EntityConstBuffer: MTLBuffer!
    private var m_EntityConstsSize: Int
    private var m_EntityConstsStride: Int
    private var m_EntityConstsBufferOffset: Int
    
    // Meshes
    private let m_MaxDrawableEntities: Int = 1024
    
    private var m_Draws: [Draw] = []
    
    // Lights
    private let m_MaxLights: Int = 32
    private var m_PointLightsBuffer: MTLBuffer!
    private let m_PointLightStride: Int
    private var m_PointLightsBufferOffset: Int
    
    private var m_SpotLightsBuffer: MTLBuffer!
    private let m_SpotLightStride: Int
    private var m_SpotLightBufferOffset: Int
    
    private var currentConstantBufferOffset = 0
    
    init(device: MTLDevice, view: MTKView ) {
        
        
        // Perform some initialization here
        g_Device = device
        self.m_View = view
        self.m_Library = g_Device.makeDefaultLibrary()
        self.m_CommandQueue = g_Device.makeCommandQueue()!
        print("Graphics Device name: \(g_Device.name)")
        
        self.m_FrameIndex = 0
        
        m_Scene = Scene()
        m_Scene.LoadScene()
        
        // FrameConstants
        self.m_ConstantsSize = MemoryLayout<FrameConstants>.stride // MemoryLayout<SIMD3<Float>>.size
        self.m_ConstantsStride = align(m_ConstantsSize, upTo: 32)
        self.m_ConstantsBufferOffset = 0
        
        // EntityConstants
        self.m_EntityConstsSize = MemoryLayout<EntityConstants>.stride
        self.m_EntityConstsStride = align(m_EntityConstsSize, upTo: 8)
        self.m_EntityConstsBufferOffset = 0
        
        // PointLights
        self.m_PointLightStride = MemoryLayout<PointLight>.stride
        self.m_PointLightsBufferOffset = 0
        
        self.m_SpotLightStride = MemoryLayout<SpotLight>.stride
        self.m_SpotLightBufferOffset = 0
        
        super.init()
        
        m_View.device = device
        m_View.delegate = self
        m_View.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        m_View.depthStencilPixelFormat = .depth32Float
        
        m_RenderPipelineState = CreateRenderPipelineState()
        m_SamplerState = CreateSamplerState()
    
        m_ConstantBuffer = g_Device.makeBuffer(length: m_ConstantsStride * g_MaxFramesInFlight, options: .storageModeShared)
        
        m_PointLightsBuffer = g_Device.makeBuffer(length: m_MaxLights * m_PointLightStride * g_MaxFramesInFlight, options: .storageModeShared)
        
        m_EntityConstBuffer = g_Device.makeBuffer(length: m_EntityConstsStride * g_MaxFramesInFlight * m_MaxDrawableEntities, options: .storageModeShared)
        
        UpdateLightBuffers()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        
    }
    
    func draw(in view: MTKView) {
        
        m_FrameSempahore.wait()
        
        guard let RenderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        guard let CommandBuffer = m_CommandQueue.makeCommandBuffer() else { return }

        let RenderCommandEncoder = CommandBuffer.makeRenderCommandEncoder(descriptor: RenderPassDescriptor)!
        
        RenderCommandEncoder.setRenderPipelineState(m_RenderPipelineState)
        
        RenderCommandEncoder.setDepthStencilState(m_DepthStencilState)
        RenderCommandEncoder.setFrontFacing(.clockwise)
        RenderCommandEncoder.setCullMode(.back)
        
        UpdateFrameConstants()
        
        RenderCommandEncoder.setVertexBuffer(m_ConstantBuffer, offset: m_ConstantsBufferOffset, index: 3)
        RenderCommandEncoder.setFragmentBuffer(m_PointLightsBuffer, offset: m_PointLightsBufferOffset, index: 4)
        
        for (Index, Entity) in m_Scene.m_Entities.enumerated() {
            
            let mesh = Entity.m_Mesh
            //guard let mesh = Entity.m_Mesh else { continue }
            
            UpdateEntityConstants(Translation: Entity.m_Translation, Rotation: Entity.m_Rotation, Scale: Entity.m_Scale, EntityIndex: Index)
            
            for (MeshIndex, MeshBuffer) in mesh.m_MTKMesh.vertexBuffers.enumerated() {
                RenderCommandEncoder.setVertexBuffer(MeshBuffer.buffer, offset: MeshBuffer.offset, index: MeshIndex)
            }
            
            
            RenderCommandEncoder.setVertexBuffer(m_EntityConstBuffer, offset: m_EntityConstsBufferOffset, index: 4)
            
            
            RenderCommandEncoder.setFragmentBuffer(m_ConstantBuffer, offset: m_ConstantsBufferOffset, index: 2)
//            RenderCommandEncoder.setFragmentBuffer(m_EntityConstBuffer, offset: m_EntityConstsBufferOffset, index: 3)
            RenderCommandEncoder.setFragmentTexture(Entity.m_Mesh.m_Texture, index: 0)
            RenderCommandEncoder.setFragmentSamplerState(m_SamplerState, index: 0)
        
            
            //RenderCommandEncoder.setTriangleFillMode(MTLTriangleFillMode.lines)
            
            for SubMesh in mesh.m_MTKMesh.submeshes {
                let indexBuffer = SubMesh.indexBuffer
                RenderCommandEncoder.drawIndexedPrimitives(type: SubMesh.primitiveType,
                                                           indexCount: SubMesh.indexCount,
                                                           indexType: SubMesh.indexType,
                                                           indexBuffer: indexBuffer.buffer,
                                                           indexBufferOffset: indexBuffer.offset)
            }
        }
        
        
        RenderCommandEncoder.endEncoding();
        
        CommandBuffer.present(view.currentDrawable!);
        
        CommandBuffer.addCompletedHandler { [weak self] _ in
                    self?.m_FrameSempahore.signal()
        }
        
        CommandBuffer.commit();
        
        m_FrameIndex += 1
    }
    
    func BuildShaders() -> MTLRenderPipelineDescriptor {

        let RenderPipelineDescriptor = MTLRenderPipelineDescriptor();
        
        RenderPipelineDescriptor.vertexFunction = m_Library.makeFunction(name: "VertexMain")!
        RenderPipelineDescriptor.fragmentFunction = m_Library.makeFunction(name: "FragmentMain")!
        RenderPipelineDescriptor.colorAttachments[0].pixelFormat = m_View.colorPixelFormat
        
        RenderPipelineDescriptor.depthAttachmentPixelFormat = m_View.depthStencilPixelFormat
        
        let DepthStencilDescriptor = MTLDepthStencilDescriptor()
        DepthStencilDescriptor.depthCompareFunction = .less
        DepthStencilDescriptor.isDepthWriteEnabled = true
        m_DepthStencilState = g_Device.makeDepthStencilState(descriptor: DepthStencilDescriptor)!
        
        return RenderPipelineDescriptor
    }
    
    func UpdateEntityConstants(Translation: SIMD3<Float>, Rotation: SIMD3<Float>, Scale: SIMD3<Float>, EntityIndex: Int) {
        
        // ModelMatrix
        let Scale = Scale
        let ScaleMatrix = simd_float4x4(Scale: Scale, M: matrix_identity_float4x4)
        
        let RotationRadians = Rotation * (Float.pi/180)
        let Rotation = EulerToQuat(Rot: RotationRadians)
        let RotationMatrix = simd_float4x4(Rotate: Rotation)
        
        let Translate = Translation
        let TranslateMatrix = simd_float4x4(Translate: Translate, M: matrix_identity_float4x4)
        
        let ModelMatrix = TranslateMatrix * RotationMatrix * ScaleMatrix
        
        // ViewMatrix
        let ViewMatrix = simd_float4x4(Translate: -m_CameraPosition, M: matrix_identity_float4x4)
        
        let ModelViewMatrix = ViewMatrix * ModelMatrix
        var Constants = EntityConstants(m_ModelMatrix: ModelMatrix, m_ModelViewMatrix: ModelViewMatrix)
        
        m_EntityConstsBufferOffset = ((m_FrameIndex % g_MaxFramesInFlight) * m_MaxDrawableEntities) + m_EntityConstsStride * EntityIndex
        let BufferData = m_EntityConstBuffer.contents().advanced(by: m_EntityConstsBufferOffset)
        BufferData.copyMemory(from: &Constants, byteCount: m_EntityConstsSize)
    }
    
    func UpdateFrameConstants() {
        
        let AspectRatio = Float(m_View.drawableSize.width / m_View.drawableSize.height)
//        let CanvasWidth: Float = 1280
//        let CanvasHeight = CanvasWidth / AspectRatio
//        let ProjectionMatrix = simd_float4x4(OrthographicProjection: CanvasWidth / 2,
//                                             left: -CanvasWidth / 2,
//                                             top: CanvasHeight / 2,
//                                             bottom: -CanvasHeight / 2,
//                                             near: 0.1,
//                                             far: 100.0)
       
        let ProjectionMatrix = simd_float4x4(PerspectiveProjectionFoVY: 45.0 * (Float.pi/180),
                                             aspectRatio: AspectRatio,
                                             near: 0.1,
                                             far: 1000.0)
        
        // ViewMatrix
        let ViewMatrix = simd_float4x4(Translate: -m_CameraPosition, M: matrix_identity_float4x4)
        
        var Constants = FrameConstants(m_ProjectionMatrix: ProjectionMatrix, m_ViewMatrix: ViewMatrix, m_CameraPosition: m_CameraPosition, m_PointLightCount: UInt32(m_Scene.m_PointLights.count), m_SpotLightCount: UInt32(m_Scene.m_SpotLights.count))
        
        m_ConstantsBufferOffset = (m_FrameIndex % g_MaxFramesInFlight) * m_ConstantsStride
        let BufferData = m_ConstantBuffer.contents().advanced(by: m_ConstantsBufferOffset)
        BufferData.copyMemory(from: &Constants, byteCount: m_ConstantsSize)
    }
    
    func UpdateLightBuffers() {
        
        m_PointLightsBufferOffset = (m_FrameIndex % g_MaxFramesInFlight) * m_MaxLights * m_PointLightStride
        
        let lightsPointer = m_PointLightsBuffer.contents().bindMemory(to: PointLight.self, capacity: m_Scene.m_PointLights.count)
        lightsPointer.update(from: m_Scene.m_PointLights, count: m_Scene.m_PointLights.count)
    }
    
    func CreateRenderPipelineState() -> MTLRenderPipelineState {
        
        let RenderPipelineDescriptor = BuildShaders()
        
        RenderPipelineDescriptor.vertexDescriptor = m_Scene.m_AssetLoader.vertexDescriptor
        
        do {
            let RenderPipelineState = try g_Device.makeRenderPipelineState(descriptor: RenderPipelineDescriptor)
            return RenderPipelineState
        } catch {
            fatalError("Error creating RenderPipelineState: \(error)")
        }
    }
    
    func CreateSamplerState() -> MTLSamplerState {
        let SamplerDescriptor = MTLSamplerDescriptor()
        
        SamplerDescriptor.normalizedCoordinates = true
        SamplerDescriptor.magFilter = .linear
        SamplerDescriptor.minFilter = .linear
        SamplerDescriptor.mipFilter = .nearest
        SamplerDescriptor.sAddressMode = .repeat
        SamplerDescriptor.tAddressMode = .repeat
        
        let SamplerState = g_Device.makeSamplerState(descriptor: SamplerDescriptor)!
        return SamplerState
    }
}
