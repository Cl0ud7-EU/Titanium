//
//  ViewController.swift
//  Titanium
//
//  Created by Cl0ud7.
//

import MetalKit
import Metal

var sliderValue: Float = 0.0
var angleValue: Float = 0.0

#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

#if os(macOS)
class ViewController: NSViewController {

    @IBOutlet weak var metalView: MTKView!
    @IBOutlet weak var horizontalSlider: NSSlider!
    @IBOutlet weak var horizontalSliderAngle: NSSlider!
    
    
    var m_Renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //let Device = MTLCreateSystemDefaultDevice()!
        let Device = MTLCopyAllDevices().last!
        m_Renderer = Renderer(device: Device, view: metalView)
        
        //Slider Radius
        sliderValue = horizontalSlider.floatValue
        horizontalSlider.target = self
        horizontalSlider.action = #selector(sliderValueChanged(_:))
        
        //Slider Angle
        angleValue = horizontalSliderAngle.floatValue
        horizontalSliderAngle.target = self
        horizontalSliderAngle.action = #selector(sliderAngleValueChanged(_:))
        
    }
    @objc func sliderValueChanged(_ sender: NSSlider) {
        sliderValue = sender.floatValue
        // Additional actions you want to perform when the slider value changes
    }
    @objc func sliderAngleValueChanged(_ sender: NSSlider) {
        angleValue = sender.floatValue
        // Additional actions you want to perform when the slider value changes
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
        //GPULabel.text = Device.name + " [Metal]" 
        m_Renderer = Renderer(device: Device, view: metalView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
#endif

