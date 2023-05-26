//
//  Renderer.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal
import MetalKit

let MaxFramesInFlight = 3;

var m_Device: MTLDevice!

class Renderer: NSObject, MTKViewDelegate {
    
    let m_CommandQueue: MTLCommandQueue!
    let m_View: MTKView!

    private var m_Library: MTLLibrary!
    private var m_RenderPipelineState: MTLRenderPipelineState!
    private var m_DepthStencilState: MTLDepthStencilState!
    
    private var m_FrameSempahore = DispatchSemaphore(value: MaxFramesInFlight)
    private var m_FrameIndex: Int
    
    private var m_ConstantBuffer: MTLBuffer!
    private let m_ConstantsSize: Int
    private let m_ConstantsStride: Int
    private var m_ConstantsBufferOffset: Int
    
    private let m_MaxDrawableEntities: Int = 1024
    private var m_Entities: [Entity] = []
    private var m_Meshes: [Mesh] = []
    private var m_Draws: [Draw] = []
    
    init(device: MTLDevice, view: MTKView ) {
        
        
        // perform some initialization here
        m_Device = device
        self.m_View = view
        self.m_Library = m_Device.makeDefaultLibrary()
        self.m_CommandQueue = m_Device.makeCommandQueue()!
        print("Graphics Device name: \(m_Device.name)")
        
        self.m_FrameIndex = 0
        
        self.m_ConstantsSize = MemoryLayout<simd_float4x4>.size // MemoryLayout<SIMD3<Float>>.size
        self.m_ConstantsStride = align(m_ConstantsSize, upTo: 256) // Maybe change it to 64 if the GPU Support it ????
        self.m_ConstantsBufferOffset = 0
        
        super.init()

        m_View.device = device
        m_View.delegate = self
        m_View.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        m_View.depthStencilPixelFormat = .depth32Float
        
        CreateScene()
        m_RenderPipelineState = CreateRenderPipelineState()
    
        m_ConstantBuffer = m_Device.makeBuffer(length: m_MaxDrawableEntities * m_ConstantsStride * MaxFramesInFlight, options: .storageModeShared)
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
        
        for (Index, Entity) in m_Entities.enumerated()
        {
            UpdateConstants(Translation: Entity.m_Translation, Rotation: Entity.m_Rotation, EntityIndex: Index)
            
            RenderCommandEncoder.setVertexBuffer(Entity.m_Mesh.m_Draw.m_VertexBuffer, offset: 0, index: 0)
            RenderCommandEncoder.setVertexBuffer(Entity.m_Mesh.m_Draw.m_VertexColorBuffer, offset: 0, index: 1)
            RenderCommandEncoder.setVertexBuffer(m_ConstantBuffer, offset: m_ConstantsBufferOffset, index: 2)
            //RenderCommandEncoder.setTriangleFillMode(MTLTriangleFillMode.lines)
            RenderCommandEncoder.drawIndexedPrimitives(type: Entity.m_Mesh.m_Draw.m_PrimitiveType,
                                                       indexCount: Entity.m_Mesh.m_Draw.m_IndexCount,
                                                       indexType: Entity.m_Mesh.m_Draw.m_IndexType,
                                                       indexBuffer: Entity.m_Mesh.m_Draw.m_IndexBuffer, indexBufferOffset: 0)
            
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
        
        RenderPipelineDescriptor.vertexFunction = m_Library.makeFunction(name: "vertex_main")!
        RenderPipelineDescriptor.fragmentFunction = m_Library.makeFunction(name: "fragment_main")!
        RenderPipelineDescriptor.colorAttachments[0].pixelFormat = m_View.colorPixelFormat
        
        RenderPipelineDescriptor.depthAttachmentPixelFormat = m_View.depthStencilPixelFormat
        
        let DepthStencilDescriptor = MTLDepthStencilDescriptor()
        DepthStencilDescriptor.depthCompareFunction = .less
        DepthStencilDescriptor.isDepthWriteEnabled = true
        m_DepthStencilState = m_Device.makeDepthStencilState(descriptor: DepthStencilDescriptor)!
        
        return RenderPipelineDescriptor
    }
    
    func UpdateConstants(Translation: SIMD3<Float>, Rotation: SIMD3<Float>, EntityIndex: Int) {
        
        let CameraPosition = SIMD3<Float>(0, 0, 0)
        let ViewMatrix = simd_float4x4(Translate: -CameraPosition, M: matrix_identity_float4x4)
        
        let Scale = SIMD3<Float>(1.0, 1.0, 1.0)
        let ScaleMatrix = simd_float4x4(Scale: Scale, M: matrix_identity_float4x4)
        
        let RotationRadians = Rotation * (Float.pi/180)
        
        let Rotation = EulerToQuat(Rot: RotationRadians)
        let RotationMatrix = simd_float4x4(Rotate: Rotation)
        
        let Translate = Translation
        let TranslateMatrix = simd_float4x4(Translate: Translate, M: matrix_identity_float4x4)
        
        let ModelMatrix = TranslateMatrix * RotationMatrix * ScaleMatrix
        
        let AspectRatio = Float(m_View.drawableSize.width / m_View.drawableSize.height)
        let CanvasWidth: Float = 1280
        let CanvasHeight = CanvasWidth / AspectRatio
//        let ProjectionMatrix = simd_float4x4(OrthographicProjection: CanvasWidth / 2,
//                                             left: -CanvasWidth / 2,
//                                             top: CanvasHeight / 2,
//                                             bottom: -CanvasHeight / 2,
//                                             near: 0.1,
//                                             far: 100.0)
       
        let ProjectionMatrix = simd_float4x4(perspectiveProjectionFoVY: 45.0 * (Float.pi/180),
                                             aspectRatio: AspectRatio,
                                             near: 0.1,
                                             far: 100.0)
        
        var TransformMatrix = ProjectionMatrix * ViewMatrix * ModelMatrix
        
        m_ConstantsBufferOffset = ((m_FrameIndex % MaxFramesInFlight) * m_MaxDrawableEntities) + m_ConstantsStride * (EntityIndex)
        let Constants = m_ConstantBuffer.contents().advanced(by: m_ConstantsBufferOffset)
        Constants.copyMemory(from: &TransformMatrix, byteCount: m_ConstantsSize)
    }
    
    func CreateCube(Translation: SIMD3<Float>, Rotation: SIMD3<Float>) {

        let Positions = [
            SIMD3<Float>(-1.0, -1.0, -1.0),
            SIMD3<Float>(1.0, -1.0, -1.0),
            SIMD3<Float>(1.0, 1.0, -1.0),
            SIMD3<Float>(1.0, 1.0, 1.0),
            SIMD3<Float>(1.0, -1.0, 1.0),
            SIMD3<Float>(-1.0, 1.0, -1.0),
            SIMD3<Float>(-1.0, 1.0, 1.0),
            SIMD3<Float>(-1.0, -1.0, 1.0)
        ]
        
        let Colors = [
            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
            SIMD4<Float>(1.0, 0.0, 1.0, 1.0)
        ]
        
        let Indices: [UInt16] = [
            // Front face
            0, 5, 1,    // Triangle 1
            1, 5, 2,    // Triangle 2

            // Back face
            4, 3, 7,    // Triangle 1
            3, 6, 7,    // Triangle 2

            // Top face
            5, 6, 2,    // Triangle 1
            2, 6, 3,    // Triangle 2

            // Bottom face
            1, 4, 0,    // Triangle 1
            7, 0, 4,    // Triangle 2

            // Left face
            0, 6, 5,    // Triangle 1
            0, 7, 6,    // Triangle 2

            // Right face
            1, 2, 4,    // Triangle 1
            3, 4, 2     // Triangle 2
        ]
        m_Entities.append(Entity(Translation: Translation, Rotation: Rotation, Scale: SIMD3<Float>(1.0, 1.0, 1.0), Mesh: Mesh(Positions: Positions, Colors: Colors, Indices: Indices)))
    }
    
    func CreateScene() {
        
        CreateCube(Translation: SIMD3<Float>(-5.0, 0.0, 10.0), Rotation: SIMD3<Float>(0.0, 0.0, 45.0))
        CreateCube(Translation: SIMD3<Float>(5.0, 0.0, 10.0), Rotation: SIMD3<Float>(0.0, 275.0, 0.0))
    }
    
    func CreateRenderPipelineState() -> MTLRenderPipelineState {
        
        let RenderPipelineDescriptor = BuildShaders()
        let VertexDescriptor = MTLVertexDescriptor()
        
        VertexDescriptor.attributes[0].format = .float3
        VertexDescriptor.attributes[0].offset = 0
        VertexDescriptor.attributes[0].bufferIndex = 0
        
        VertexDescriptor.attributes[1].format = .float4
        VertexDescriptor.attributes[1].offset = 0
        VertexDescriptor.attributes[1].bufferIndex = 1

        VertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        VertexDescriptor.layouts[1].stride = MemoryLayout<SIMD4<Float>>.stride
        
        RenderPipelineDescriptor.vertexDescriptor = VertexDescriptor
        
        do {
            let RenderPipelineState = try m_Device.makeRenderPipelineState(descriptor: RenderPipelineDescriptor)
            return RenderPipelineState
        } catch {
            fatalError("Error creating RenderPipelineState: \(error)")
        }
    }
}
