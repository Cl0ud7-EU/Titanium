//
//  ViewController.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController {

    @IBOutlet weak var metalView: MTKView!
    var m_Renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let Device = MTLCreateSystemDefaultDevice()!
        m_Renderer = Renderer(device: Device, view: metalView)
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

