//
//  ViewController.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import Metal
import MetalKit

#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

#if os(macOS)
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
#elseif os(iOS)
class ViewController: UIViewController {

    @IBOutlet weak var metalView: MTKView!
    @IBOutlet weak var GPULabel: UILabel!
    var m_Renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let Device = MTLCreateSystemDefaultDevice()!
        GPULabel.text = Device.name + " [Metal]" 
        m_Renderer = Renderer(device: Device, view: metalView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
#endif

