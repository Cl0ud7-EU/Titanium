//
//  Renderer.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Foundation
import Metal
import MetalKit

class Renderer: NSObject, MTKViewDelegate
{
    let m_Device: MTLDevice!
    let m_CommandQueue: MTLCommandQueue!
    let m_View: MTKView!

    var m_Library: MTLLibrary!
    var m_CommandBuffer: MTLCommandBuffer!
    var m_VertexBuffer: MTLBuffer!
    var m_RenderPipelineState: MTLRenderPipelineState!
    
    
    
    
    init(device: MTLDevice, view: MTKView ) {
        
        
        // perform some initialization here
        self.m_Device = device
        self.m_View = view
        self.m_Library = m_Device.makeDefaultLibrary()
        self.m_CommandQueue = m_Device.makeCommandQueue()!
        print("Graphics Device name: \(m_Device.name)")
        
        super.init()
        
        m_View.device = device
        m_View.delegate = self
        m_View.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        
    }
    
    func draw(in view: MTKView) {
        
        BuildShaders()
        BuildBuffers()
        
        guard let RenderPassDescriptor = view.currentRenderPassDescriptor
        else {
            return;
        }
        
        m_CommandBuffer = m_CommandQueue.makeCommandBuffer()!
        
        let RenderCommandEconder =  m_CommandBuffer.makeRenderCommandEncoder(descriptor: RenderPassDescriptor)!
        
        RenderCommandEconder.setRenderPipelineState(m_RenderPipelineState)
        RenderCommandEconder.setVertexBuffer(m_VertexBuffer, offset: 0, index: 0)
        RenderCommandEconder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        RenderCommandEconder.endEncoding();
        
        m_CommandBuffer.present(view.currentDrawable!);
        
        m_CommandBuffer.commit();
    }
    
    func BuildShaders()
    {
        for name in m_Library.functionNames {
            let function = m_Library.makeFunction(name: name)!
            print("\(function)")
        }
        
        let RenderPipelineDescriptor = MTLRenderPipelineDescriptor();
        
        RenderPipelineDescriptor.vertexFunction = m_Library.makeFunction(name: "vertex_main")!
        RenderPipelineDescriptor.fragmentFunction = m_Library.makeFunction(name: "fragment_main")!
        RenderPipelineDescriptor.colorAttachments[0].pixelFormat = m_View.colorPixelFormat
        
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
        
        // Creates the VertexBuffer and copies the vertex positions.
        // MemoryLayout<SIMD3<Float>>.stride returns the size taking into account the aligment, so this would be 4+4+4 = 12 + 4bytes for aligment
        //print(MemoryLayout<SIMD3<Float>>.stride)
        m_VertexBuffer = m_Device.makeBuffer(bytes: &Positions, length: MemoryLayout<SIMD3<Float>>.stride * Positions.count, options: .storageModeShared)
        
        
        
    }
}
