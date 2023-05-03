//
//  Renderer.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal
import MetalKit

func align(_ value: Int, upTo alignment: Int) -> Int {
    return ((value + alignment - 1) / alignment) * alignment
}

let MaxFramesInFlight = 3;

class Renderer: NSObject, MTKViewDelegate
{
    let m_Device: MTLDevice!
    let m_CommandQueue: MTLCommandQueue!
    let m_View: MTKView!

    private var m_Library: MTLLibrary!
    private var m_CommandBuffer: MTLCommandBuffer!
    private var m_VertexBuffer: MTLBuffer!
    private var m_VertexColorBuffer: MTLBuffer!
    private var m_RenderPipelineState: MTLRenderPipelineState!
    
    private var m_FrameSempahore = DispatchSemaphore(value: MaxFramesInFlight)
    private var m_FrameIndex: Int
    
    private var m_ConstantBuffer: MTLBuffer!
    private let m_ConstantsSize: Int
    private let m_ConstantsStride: Int
    private var m_ConstantsBufferOffset: Int
    
    
    init(device: MTLDevice, view: MTKView ) {
        
        
        // perform some initialization here
        self.m_Device = device
        self.m_View = view
        self.m_Library = m_Device.makeDefaultLibrary()
        self.m_CommandQueue = m_Device.makeCommandQueue()!
        print("Graphics Device name: \(m_Device.name)")
        
        self.m_FrameIndex = 0
        
        self.m_ConstantsSize = MemoryLayout<SIMD3<Float>>.size
        self.m_ConstantsStride = align(m_ConstantsSize, upTo: 256)
        self.m_ConstantsBufferOffset = 0
        
        super.init()

        m_View.device = device
        m_View.delegate = self
        m_View.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        
    }
    
    func draw(in view: MTKView) {
        
        m_FrameSempahore.wait()
        
        
        BuildShaders()
        BuildBuffers()
        UpdateConstants()
        
        guard let RenderPassDescriptor = view.currentRenderPassDescriptor
        else {
            return;
        }

        m_CommandBuffer = m_CommandQueue.makeCommandBuffer()!

        let RenderCommandEconder =  m_CommandBuffer.makeRenderCommandEncoder(descriptor: RenderPassDescriptor)!

        RenderCommandEconder.setRenderPipelineState(m_RenderPipelineState)
        RenderCommandEconder.setVertexBuffer(m_VertexBuffer, offset: 0, index: 0)
        RenderCommandEconder.setVertexBuffer(m_VertexColorBuffer, offset: 0, index: 1)
        RenderCommandEconder.setVertexBuffer(m_ConstantBuffer, offset: m_ConstantsBufferOffset, index: 2)
        
        RenderCommandEconder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        RenderCommandEconder.endEncoding();

        m_CommandBuffer.present(view.currentDrawable!);
        
        m_CommandBuffer.addCompletedHandler { [weak self] _ in
                    self?.m_FrameSempahore.signal()
        }
        
        m_CommandBuffer.commit();
        
        m_FrameIndex += 1
    }
    
    func BuildShaders()
    {
        for name in m_Library.functionNames {
            let function = m_Library.makeFunction(name: name)!
            //print("\(function)")
        }
        
        let RenderPipelineDescriptor = MTLRenderPipelineDescriptor();
        
        RenderPipelineDescriptor.vertexFunction = m_Library.makeFunction(name: "vertex_main")!
        RenderPipelineDescriptor.fragmentFunction = m_Library.makeFunction(name: "fragment_main")!
        RenderPipelineDescriptor.colorAttachments[0].pixelFormat = m_View.colorPixelFormat
        
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
            m_RenderPipelineState = try m_Device.makeRenderPipelineState(descriptor: RenderPipelineDescriptor)
        } catch {
            fatalError("Error creating RenderPipelineState: \(error)")
        }
        
        
    }
    
    func BuildBuffers()
    {
        var Positions = [
            SIMD3<Float>(-0.8,  0.8, 0.0),
            SIMD3<Float>(0.0, -0.8, 0.0),
            SIMD3<Float>(+0.8,  0.8, 0.0),
        ]
        
        var Colors = [
            SIMD4<Float>(1.0, 0.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 1.0, 0.0, 1.0),
            SIMD4<Float>(0.0, 0.0, 1.0, 1.0),
        ]
        
        // Creates the VertexBuffer and copies the vertex positions.
        // MemoryLayout<SIMD3<Float>>.stride returns the size taking into account the aligment, so this would be 4+4+4 = 12 + 4bytes for aligment
        //print(MemoryLayout<SIMD3<Float>>.stride)
        m_VertexBuffer = m_Device.makeBuffer(bytes: &Positions, length: MemoryLayout<SIMD3<Float>>.stride * Positions.count, options: .storageModeShared)
        
        m_VertexColorBuffer = m_Device.makeBuffer(bytes: &Colors, length: MemoryLayout<SIMD4<Float>>.stride * Colors.count, options: .storageModeShared)
        
        m_ConstantBuffer = m_Device.makeBuffer(length: m_ConstantsStride * MaxFramesInFlight, options: .storageModeShared)
    }
    
    func UpdateConstants()
    {
        let Speed = 3.0
        let Time = CACurrentMediaTime()
        let RotationMagnitude: Float = 0.1
        let RotationAngle = Float(fmod(Speed * Time, .pi * 2))
        var PositionOffset = RotationMagnitude * SIMD3<Float>(cos(RotationAngle), sin(RotationAngle), 0.0)
        
        print(PositionOffset)
        
        m_ConstantsBufferOffset = (m_FrameIndex % MaxFramesInFlight) * m_ConstantsStride
        let Constants = m_ConstantBuffer.contents().advanced(by: m_ConstantsBufferOffset)
        Constants.copyMemory(from: &PositionOffset, byteCount: m_ConstantsSize)
    }
}
