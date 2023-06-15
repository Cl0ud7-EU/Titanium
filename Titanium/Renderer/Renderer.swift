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

let MaxFramesInFlight = 3;

var m_Device: MTLDevice!
let MinBufferAlignment = 256

struct EntityConstants {
    var m_ModelMatrix: simd_float4x4
    var m_ModelViewMatrix: simd_float4x4
}

struct FrameConstants {
    var m_ProjectionMatrix: simd_float4x4
    var m_LightCount: UInt32
}

class Renderer: NSObject, MTKViewDelegate {
    
    let m_CommandQueue: MTLCommandQueue!
    let m_View: MTKView!

    private var m_Library: MTLLibrary!
    private var m_RenderPipelineState: MTLRenderPipelineState!
    private var m_DepthStencilState: MTLDepthStencilState!
    
    private var m_FrameSempahore = DispatchSemaphore(value: MaxFramesInFlight)
    private var m_FrameIndex: Int
    
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
    private var m_Entities: [Entity] = []
    private var m_Meshes: [Mesh] = []
    
    private var m_Draws: [Draw] = []
    
    // Lights
    private var m_Lights: [PointLight] = []
    private let m_MaxLights: Int = 32
    private var m_LightBuffer: MTLBuffer!
    private let m_LightSize: Int
    private let m_LightBufferStride: Int
    private var m_LightBufferOffset: Int
    
    private var currentConstantBufferOffset = 0
    
    init(device: MTLDevice, view: MTKView ) {
        
        
        // perform some initialization here
        m_Device = device
        self.m_View = view
        self.m_Library = m_Device.makeDefaultLibrary()
        self.m_CommandQueue = m_Device.makeCommandQueue()!
        print("Graphics Device name: \(m_Device.name)")
        
        self.m_FrameIndex = 0
        
        // FrameConstants
        self.m_ConstantsSize = MemoryLayout<FrameConstants>.stride // MemoryLayout<SIMD3<Float>>.size
        self.m_ConstantsStride = align(m_ConstantsSize, upTo: 256) // Maybe change it to 64 if the GPU Support it ????
        self.m_ConstantsBufferOffset = 0
        
        // EntityConstants
        self.m_EntityConstsSize = MemoryLayout<EntityConstants>.stride
        self.m_EntityConstsStride = align(m_EntityConstsSize, upTo: 256)
        self.m_EntityConstsBufferOffset = 0
        
        // Lights
        self.m_LightSize = MemoryLayout<PointLight>.stride
        self.m_LightBufferStride = align(m_LightSize, upTo: 288)
        self.m_LightBufferOffset = 0
        
        super.init()

        m_View.device = device
        m_View.delegate = self
        m_View.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        m_View.depthStencilPixelFormat = .depth32Float
        
        m_LightBuffer = m_Device.makeBuffer(length: m_MaxLights * m_LightBufferStride * MaxFramesInFlight, options: .storageModeShared)
        CreateScene()
        m_RenderPipelineState = CreateRenderPipelineState()
    
        m_ConstantBuffer = m_Device.makeBuffer(length: m_ConstantsStride * MaxFramesInFlight, options: .storageModeShared)
        
        m_EntityConstBuffer = m_Device.makeBuffer(length: m_EntityConstsStride * MaxFramesInFlight * m_MaxDrawableEntities, options: .storageModeShared)
        
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
        
        UpdateConstants()
        
        RenderCommandEncoder.setFragmentBuffer(m_LightBuffer, offset: m_LightBufferOffset, index: 4)
        
        for (Index, Entity) in m_Entities.enumerated() {
            
            UpdateEntityConstants(Translation: Entity.m_Translation, Rotation: Entity.m_Rotation, Scale: Entity.m_Scale, EntityIndex: Index)
            RenderCommandEncoder.setVertexBuffer(Entity.m_Mesh.m_Draw.m_VertexBuffer, offset: 0, index: 0)
            RenderCommandEncoder.setVertexBuffer(Entity.m_Mesh.m_Draw.m_VertexColorBuffer, offset: 0, index: 1)
            RenderCommandEncoder.setVertexBuffer(Entity.m_Mesh.m_NormalsBuffer, offset: 0, index: 2)
            
            RenderCommandEncoder.setVertexBuffer(m_ConstantBuffer, offset: m_ConstantsBufferOffset, index: 3)
            RenderCommandEncoder.setVertexBuffer(m_EntityConstBuffer, offset: m_EntityConstsBufferOffset, index: 4)
            
            
            RenderCommandEncoder.setFragmentBuffer(m_ConstantBuffer, offset: m_ConstantsBufferOffset, index: 2)
            RenderCommandEncoder.setFragmentBuffer(m_EntityConstBuffer, offset: m_EntityConstsBufferOffset, index: 3)
        
            
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
        let CameraPosition = SIMD3<Float>(0, 0, 0)
        let ViewMatrix = simd_float4x4(Translate: -CameraPosition, M: matrix_identity_float4x4)
        
        let ModelViewMatrix = ViewMatrix * ModelMatrix
        var Constants = EntityConstants(m_ModelMatrix: ModelMatrix, m_ModelViewMatrix: ModelViewMatrix)
        
        m_EntityConstsBufferOffset = ((m_FrameIndex % MaxFramesInFlight) * m_MaxDrawableEntities) + m_EntityConstsStride * (EntityIndex)
        let BufferData = m_EntityConstBuffer.contents().advanced(by: m_EntityConstsBufferOffset)
        BufferData.copyMemory(from: &Constants, byteCount: m_EntityConstsSize)
    }
    
    func UpdateConstants() {
        
        let AspectRatio = Float(m_View.drawableSize.width / m_View.drawableSize.height)
//        let CanvasWidth: Float = 1280
//        let CanvasHeight = CanvasWidth / AspectRatio
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
        
        var Constants = FrameConstants(m_ProjectionMatrix: ProjectionMatrix, m_LightCount: UInt32(m_Lights.count))
        
        m_ConstantsBufferOffset = (m_FrameIndex % MaxFramesInFlight) * m_ConstantsStride
        let BufferData = m_ConstantBuffer.contents().advanced(by: m_ConstantsBufferOffset)
        BufferData.copyMemory(from: &Constants, byteCount: m_ConstantsSize)
    }
    
//    func UpdateLightConstants(Light: inout DirectionalLight, LightIndex: Int) {
//        m_LightBufferOffset = ((m_FrameIndex % MaxFramesInFlight) * m_MaxLights) + m_LightBufferStride * (LightIndex)
//        let BufferData = m_LightBuffer.contents().advanced(by: m_LightBufferOffset)
//        BufferData.copyMemory(from: &Light , byteCount: m_LightSize)
//    }
    
    func CreateCube(Translation: SIMD3<Float>, Rotation: SIMD3<Float>, Scale: SIMD3<Float>) {

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
            0, 16, 3,    // Triangle 1
            3, 16, 6,    // Triangle 2

            // Back face
            12, 11, 21,    // Triangle 1
            11, 18, 21,    // Triangle 2

            // Top face
            15, 19, 7,    // Triangle 1
            7, 19, 10,    // Triangle 2

            // Bottom face
            4, 13, 1,    // Triangle 1
            23, 1, 13,    // Triangle 2

            // Left face
            2, 20, 17,    // Triangle 1
            2, 22, 20,    // Triangle 2

            // Right face
            5, 8, 14,    // Triangle 1
            9, 14, 8     // Triangle 2
        ]
        
        var vertices: [Vertex] = []
        var normal = SIMD3<Float>(0,0,0)
        // Create Verts
        for i in 0...7
        {
            for e in 0...2
            {
                vertices.append(Vertex(m_Position: Positions[i], m_Color: Colors[i], m_Normal: normal))
            }
        }
        
        // Calculate normal per vertex
        for i in stride(from: 0, to: Indices.count-1, by: 3*2)
        {
            var vertexCalculated: [UInt16] = []
            let vectorA = vertices[Int(Indices[i+1])].m_Position - vertices[Int(Indices[i])].m_Position
            let vectorB = vertices[Int(Indices[i+2])].m_Position - vertices[Int(Indices[i])].m_Position
//
            let normal = normalize(simd_cross(vectorB, vectorA))
            for index in 0...5
            {
                if (!vertexCalculated.contains(Indices[index+i]))
                {
                    vertices[Int(Indices[index+i])].m_Normal = normal
                    vertexCalculated.append(Indices[index+i])
                }
            }
        }
        
        var PosArray: [SIMD3<Float>] = []
        var ColorArray: [SIMD4<Float>] = []
        var NormalArray: [SIMD3<Float>] = []
//
        for vert in vertices
        {
            PosArray.append(vert.m_Position)
            ColorArray.append(vert.m_Color)
            NormalArray.append(vert.m_Normal)
            print(vert.m_Normal)
        }
        print("finish")
        m_Entities.append(Entity(Translation: Translation, Rotation: Rotation, Scale: Scale, Mesh: Mesh(Positions: PosArray, Colors: ColorArray, Indices: Indices, Normals: NormalArray)))
    }
    
    func CreateLight(Intensity: Float, Direction: SIMD3<Float>, Color: SIMD3<Float>) {
        //m_Lights.append(DirectionalLight(Direction: Direction, Color: Color, Intensity: Intensity))
    }
    func CreatePointLight(Position: SIMD3<Float>, Color: SIMD3<Float>, Intensity: Float, Radius: Float) {
        m_Lights.append(PointLight(Position: Position, Color: Color, Intensity: Intensity, Radius: Radius))
    }
    
    func CreateScene() {
        
        CreateCube(Translation: SIMD3<Float>(-5.0, 0.0, 10.0), Rotation: SIMD3<Float>(0.0, 90.0, 90.0), Scale: SIMD3<Float>(1.0, 1.0, 1.0))
        CreateCube(Translation: SIMD3<Float>(5.0, 0.0, 10.0), Rotation: SIMD3<Float>(45.0, 0.0, 45.0), Scale: SIMD3<Float>(1.0, 1.0, 1.0))
        CreateCube(Translation: SIMD3<Float>(0.0, 0.0, 10.0), Rotation: SIMD3<Float>(45.0, 290.0, 0.0), Scale: SIMD3<Float>(1.0, 1.0, 1.0))
        
        // Floor and Walls
        CreateCube(Translation: SIMD3<Float>(0.0, -3.0, 10.0), Rotation: SIMD3<Float>(0.0, 0.0, 0.0), Scale: SIMD3<Float>(20.0, 1.0, 20.0))
        CreateCube(Translation: SIMD3<Float>(0.0, -3.0, 30.0), Rotation: SIMD3<Float>(90.0, 0.0, 0.0), Scale: SIMD3<Float>(20.0, 1.0, 20.0))
        // Right
        CreateCube(Translation: SIMD3<Float>(20.0, -3.0, 10.0), Rotation: SIMD3<Float>(90.0, 90.0, 0.0), Scale: SIMD3<Float>(20.0, 1.0, 20.0))
        //Left
        CreateCube(Translation: SIMD3<Float>(-20.0, -3.0, 10.0), Rotation: SIMD3<Float>(90.0, 90.0, 0.0), Scale: SIMD3<Float>(20.0, 1.0, 20.0))
        
        //CreateLight(Intensity: 0.4, Direction: SIMD3<Float>(0.0, -1.0, 0.0), Color: SIMD3<Float>(0.4, 0.2, 0.3))
        
        CreatePointLight(Position: SIMD3<Float>(2.0, 0.0, 7.0), Color: SIMD3<Float>(1.0, 1.0, 1.0), Intensity: 1.0, Radius: 20.5)
        //CreatePointLight(Position: SIMD3<Float>(0.0, 0.0, 20.0), Color: SIMD3<Float>(1.0, 1.0, 1.0), Intensity: 1.0, Radius: 10.5)
        
        
        for (Index, Light) in m_Lights.enumerated()
        {
//            let LightsBufferOffset = ((m_FrameIndex % MaxFramesInFlight) * m_MaxLights) + m_LightBufferStride * Index
//            let LightsBufferPointer = m_LightBuffer.contents().advanced(by: LightsBufferOffset).assumingMemoryBound(to: DirectionalLight.self)
//            LightsBufferPointer[Index] = DirectionalLight(Direction: Light.m_Direction,
//                                                          Color: Light.m_Color,
//                                                          Intensity: Light.m_Intensity)
            
            let LightsBufferOffset = ((m_FrameIndex % MaxFramesInFlight) * m_MaxLights) + m_LightBufferStride * Index
            let LightsBufferPointer = m_LightBuffer.contents().advanced(by: LightsBufferOffset).assumingMemoryBound(to: PointLight.self)
            LightsBufferPointer[Index] = PointLight(Position: Light.m_Position,
                                                    Color: Light.m_Color,
                                                    Intensity: Light.m_Intensity,
                                                    Radius: Light.m_Radius)
            
//            self.m_LightBuffer = m_Device.makeBuffer(bytes: Light,
//                                                     length: MemoryLayout<UInt16>.size,
//                                                     options: .storageModeShared)
        }
    }
    
    func allocateConstantStorage(size: Int, alignment: Int) -> Int {
            let effectiveAlignment = lcm(alignment, MinBufferAlignment)
            var allocationOffset = align(0, upTo: effectiveAlignment)
            if (allocationOffset + size >= m_MaxLights) {
                allocationOffset = 0
            }
            currentConstantBufferOffset = allocationOffset + size
            return allocationOffset
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
        
        VertexDescriptor.attributes[2].format = .float3
        VertexDescriptor.attributes[2].offset = 0
        VertexDescriptor.attributes[2].bufferIndex = 2

        VertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        VertexDescriptor.layouts[1].stride = MemoryLayout<SIMD4<Float>>.stride
        VertexDescriptor.layouts[2].stride = MemoryLayout<SIMD3<Float>>.stride
        
        RenderPipelineDescriptor.vertexDescriptor = VertexDescriptor
        
        do {
            let RenderPipelineState = try m_Device.makeRenderPipelineState(descriptor: RenderPipelineDescriptor)
            return RenderPipelineState
        } catch {
            fatalError("Error creating RenderPipelineState: \(error)")
        }
    }
}
