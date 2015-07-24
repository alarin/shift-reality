import UIKit


class FilterDisplayViewController: UIViewController, UISplitViewControllerDelegate {

    @IBOutlet var filterSlider: UISlider?
    @IBOutlet var filterView: GPUImageView?
    
    let videoCamera: GPUImageVideoCamera
    var blendImage: GPUImagePicture?
  
  var filterViewLeft: GPUImageView?
  var filterViewRight: GPUImageView?
  
  var brightness: CGFloat!
  
    required init(coder aDecoder: NSCoder)
    {
//        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
      videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset1280x720, cameraPosition: .Back)  
//      videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset1920x1080, cameraPosition: .Back)
        videoCamera.outputImageOrientation = .Portrait;

        super.init(coder: aDecoder)
    }
  
    var filterOperation: FilterOperationInterface? {
        didSet {
            self.configureView()
        }
    }

    func configureView() {
        if let currentFilterConfiguration = self.filterOperation {
            self.title = currentFilterConfiguration.titleName
            
            // Configure the filter chain, ending with the view
            if let view1 = self.filterViewLeft {
              let view2 = self.filterViewRight!
                switch currentFilterConfiguration.filterOperationType {
                case .SingleInput:
                    videoCamera.addTarget((currentFilterConfiguration.filter as! GPUImageInput))
                    currentFilterConfiguration.filter.addTarget(view1)
                    currentFilterConfiguration.filter.addTarget(view2)
                case .Blend:
                    videoCamera.addTarget((currentFilterConfiguration.filter as! GPUImageInput))
                    let inputImage = UIImage(named:"WID-small.jpg")
                    self.blendImage = GPUImagePicture(image: inputImage)
                    self.blendImage?.addTarget((currentFilterConfiguration.filter as! GPUImageInput))
                    self.blendImage?.processImage()
                    currentFilterConfiguration.filter.addTarget(view1)
                    currentFilterConfiguration.filter.addTarget(view2)
                case let .Custom(filterSetupFunction:setupFunction):
                   let inputToFunction:(GPUImageOutput, GPUImageOutput?) = setupFunction(camera:videoCamera, outputView:view1) // Type inference falls down, for now needs this hard cast
                    inputToFunction.1?.addTarget(view2)
                    currentFilterConfiguration.configureCustomFilter(inputToFunction)
                }
                
                videoCamera.startCameraCapture()
            }

            // Hide or display the slider, based on whether the filter needs it
            if let slider = self.filterSlider {
                switch currentFilterConfiguration.sliderConfiguration {
                case .Disabled:
                    slider.hidden = true
//                case let .Enabled(minimumValue, initialValue, maximumValue, filterSliderCallback):
                case let .Enabled(minimumValue, maximumValue, initialValue):
                    slider.minimumValue = minimumValue
                    slider.maximumValue = maximumValue
                    slider.value = initialValue
                    slider.hidden = false
                    self.updateSliderValue()
                }
            }
            
        }
    }
    
    @IBAction func updateSliderValue() {
        if let currentFilterConfiguration = self.filterOperation {
            switch (currentFilterConfiguration.sliderConfiguration) {
            case let .Enabled(minimumValue, maximumValue, initialValue):
                currentFilterConfiguration.updateBasedOnSliderValue(CGFloat(self.filterSlider!.value)) // If the UISlider isn't wired up, I want this to throw a runtime exception
            case .Disabled:
                break
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
      
        let tapGesture = UITapGestureRecognizer(target:self, action:Selector("handleTapGesture:"))
        tapGesture.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapGesture)
      
      let frame = view.layer.frame
      self.filterViewLeft = GPUImageView(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height/2))
      self.filterViewLeft!.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
      self.filterViewLeft!.fillMode =      kGPUImageFillModeStretch
      self.filterViewRight = GPUImageView(frame: CGRect(x: frame.origin.x, y: frame.origin.y + frame.height/2, width: frame.width, height: frame.height/2))
      self.filterViewRight!.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
      self.filterViewRight!.fillMode =      kGPUImageFillModeStretch
      self.filterView!.addSubview(self.filterViewLeft!)
      self.filterView!.addSubview(self.filterViewRight!)
      self.filterView!.addSubview(self.filterSlider!)
      
      self.configureView()
  }
  
  override func viewWillAppear(animated: Bool) {
    UIApplication.sharedApplication().idleTimerDisabled = true;
    self.brightness = UIScreen.mainScreen().brightness
    UIScreen.mainScreen().brightness = 1.0
  }
  
  override func viewWillDisappear(animated: Bool) {
    UIScreen.mainScreen().brightness = self.brightness
  }
  
  func handleTapGesture(sender: UITapGestureRecognizer) {
    if (sender.state == UIGestureRecognizerState.Ended) {
      let navHidden:Bool! = self.navigationController?.navigationBarHidden
      self.navigationController?.setNavigationBarHidden(!navHidden, animated: true)
      self.filterSlider?.hidden = !navHidden
    }
  }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
  override func prefersStatusBarHidden() -> Bool {
    return true;
  }
}

