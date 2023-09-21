//
//  CameraView.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit
import AVFoundation
import PhotosUI

protocol CameraViewDelegate: AnyObject {
    func setFlashButtonHidden(_ hidden: Bool)
    func imageToLibrary()
    func cameraNotAvailable()
}

class CameraView: UIViewController, CLLocationManagerDelegate, CameraManagerDelegate {
    
    var configuration = ImagePickerConfiguration()
    
    lazy var blurView: UIVisualEffectView = { [unowned self] in
        let effect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: effect)
        
        return blurView
    }()
    
    lazy var focusImageView: UIImageView = { [unowned self] in
        let imageView = UIImageView()
        imageView.image = AssetManager.getImage("focusIcon")
        imageView.backgroundColor = UIColor.clear
        imageView.frame = CGRect(x: 0, y: 0, width: 110, height: 110)
        imageView.alpha = 0
        
        return imageView
    }()
    
    lazy var capturedImageView: UIView = { [unowned self] in
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.alpha = 0
        
        return view
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.alpha = 0
        
        return view
    }()
    
    lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(tapGestureRecognizerHandler(_:)))
        
        return gesture
    }()
    
    lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = { [unowned self] in
        let gesture = UIPinchGestureRecognizer()
        gesture.addTarget(self, action: #selector(pinchGestureRecognizerHandler(_:)))
        
        return gesture
    }()
    
    let cameraManager = CameraManager()
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: CameraViewDelegate?
    var animationTimer: Timer?
    var locationManager: LocationManager?
    var startOnFrontCamera: Bool = false
    
    private let minimumZoomFactor: CGFloat = 1.0
    private let maximumZoomFactor: CGFloat = 3.0
    
    private var currentZoomFactor: CGFloat = 1.0
    private var previousZoomFactor: CGFloat = 1.0
    
    public init(configuration: ImagePickerConfiguration? = nil) {
        if let configuration = configuration {
            self.configuration = configuration
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if configuration.recordLocation {
            locationManager = LocationManager()
        }
        
        view.backgroundColor = configuration.mainColor
        
        view.addSubview(containerView)
        containerView.addSubview(blurView)
        
        [focusImageView, capturedImageView].forEach {
            view.addSubview($0)
        }
        
        [blurView, containerView, capturedImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        view.addGestureRecognizer(tapGestureRecognizer)
        
        if configuration.allowPinchToZoom {
            view.addGestureRecognizer(pinchGestureRecognizer)
        }
        
        cameraManager.delegate = self
        cameraManager.setup(self.startOnFrontCamera)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        previewLayer?.connection?.videoOrientation = .portrait
        locationManager?.startUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager?.stopUpdatingLocation()
    }
    
    func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        layer.backgroundColor = configuration.mainColor.cgColor
        layer.autoreverses = true
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        layer.frame = view.layer.frame
        view.clipsToBounds = true
        
        previewLayer = layer
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    // MARK: - Camera actions
    
    func rotateCamera() {
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.alpha = 1
        }, completion: { _ in
            self.cameraManager.switchCamera {
                UIView.animate(withDuration: 0.7, animations: {
                    self.containerView.alpha = 0
                })
            }
        })
    }
    
    func flashCamera(_ title: String) {
        let mapping: [String: AVCaptureDevice.FlashMode] = [
            "ON": .on,
            "OFF": .off
        ]
        
        cameraManager.flash(mapping[title] ?? .auto)
    }
    
    func takePicture(_ completion: @escaping () -> Void) {
        guard let previewLayer = previewLayer else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.capturedImageView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.capturedImageView.alpha = 0
            })
        })
        
        cameraManager.takePhoto(previewLayer, location: locationManager?.latestLocation) {
            completion()
            self.delegate?.imageToLibrary()
        }
    }
    
    // MARK: - Timer methods
    
    @objc func timerDidFire() {
        UIView.animate(withDuration: 0.3, animations: { [unowned self] in
            self.focusImageView.alpha = 0
        }, completion: { _ in
            self.focusImageView.transform = CGAffineTransform.identity
        })
    }
    
    // MARK: - Camera methods
    
    func focusTo(_ point: CGPoint) {
        let convertedPoint = CGPoint(x: point.x / UIScreen.main.bounds.width,
                                     y: point.y / UIScreen.main.bounds.height)
        
        cameraManager.focus(convertedPoint)
        
        focusImageView.center = point
        UIView.animate(withDuration: 0.5, animations: {
            self.focusImageView.alpha = 1
            self.focusImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }, completion: { _ in
            self.animationTimer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                                       selector: #selector(CameraView.timerDidFire), userInfo: nil, repeats: false)
        })
    }
    
    func zoomTo(_ zoomFactor: CGFloat) {
        guard let device = cameraManager.currentInput?.device else { return }
        
        let maximumDeviceZoomFactor = device.activeFormat.videoMaxZoomFactor
        let newZoomFactor = previousZoomFactor * zoomFactor
        currentZoomFactor = min(maximumZoomFactor, max(minimumZoomFactor, min(newZoomFactor, maximumDeviceZoomFactor)))
        
        cameraManager.zoom(currentZoomFactor)
    }
    
    // MARK: - Tap
    
    @objc func tapGestureRecognizerHandler(_ gesture: UITapGestureRecognizer) {
        let touch = gesture.location(in: view)
        
        focusImageView.transform = CGAffineTransform.identity
        animationTimer?.invalidate()
        focusTo(touch)
    }
    
    // MARK: - Pinch
    
    @objc func pinchGestureRecognizerHandler(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            fallthrough
        case .changed:
            zoomTo(gesture.scale)
        case .ended:
            zoomTo(gesture.scale)
            previousZoomFactor = currentZoomFactor
        default: break
        }
    }
        
    // cameraManagerDelegate
    func cameraManagerNotAvailable(_ cameraManager: CameraManager) {
        focusImageView.isHidden = true
        delegate?.cameraNotAvailable()
    }
    
    func cameraManager(_ cameraManager: CameraManager, didChangeInput input: AVCaptureDeviceInput) {
        if !configuration.flashButtonAlwaysHidden {
            delegate?.setFlashButtonHidden(!input.device.hasFlash)
        }
    }
    
    func cameraManagerDidStart(_ cameraManager: CameraManager) {
        setupPreviewLayer()
    }
}
