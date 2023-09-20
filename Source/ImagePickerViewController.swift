//
//  ImagePickerViewController.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit
import MediaPlayer
import Photos

public protocol ImagePickerDelegate: AnyObject {
    
    func stackButtonDidSelect(_ imagePicker: ImagePickerViewController, images: [UIImage])
    func doneButtonDidSelect(_ imagePicker: ImagePickerViewController, images: [UIImage])
    func cancelButtonDidSelect(_ imagePicker: ImagePickerViewController)
}

open class ImagePickerViewController: UIViewController {
    
    let configuration: ImageConfiguration
    
    open lazy var galleryView: ImageGalleryView = { [unowned self] in
        let galleryView = ImageGalleryView(configuration: self.configuration)
        galleryView.delegate = self
        galleryView.selectedStack = self.stack
        galleryView.imageLimit = self.imageLimit
        
        return galleryView
    }()
    
    open lazy var bottomContainer: BottomContainerView = { [unowned self] in
        let view = BottomContainerView(configuration: self.configuration)
        view.backgroundColor = self.configuration.bottomContainerColor
        view.delegate = self
        
        return view
    }()
    
    open lazy var topView: TopView = { [unowned self] in
        let view = TopView(configuration: self.configuration)
        view.backgroundColor = UIColor.clear
        view.delegate = self
        
        return view
    }()
    
    lazy var cameraController: CameraView = { [unowned self] in
        let controller = CameraView(configuration: self.configuration)
        controller.delegate = self
        controller.startOnFrontCamera = self.startOnFrontCamera
        
        return controller
    }()
    
    lazy var volumeView: MPVolumeView = { [unowned self] in
        let view = MPVolumeView()
        view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        return view
    }()
    
    private var volume = AVAudioSession.sharedInstance().outputVolume
    
    open weak var delegate: ImagePickerDelegate?
    open var stack = ImageStack()
    open var imageLimit = 0
    open var preferredImageSize: CGSize?
    open var startOnFrontCamera = false
    private var numberOfCells: Int?
    private var statusBarHidden = true
    private var galleryViewTop: NSLayoutConstraint?
    private var galleryViewTopStart: CGFloat = 0
    fileprivate var isTakingPicture = false
    open var doneButtonTitle: String? {
        didSet {
            if let doneButtonTitle = doneButtonTitle {
                bottomContainer.doneButton.setTitle(doneButtonTitle, for: UIControl.State())
            }
        }
    }
    
    // MARK: - Initialization
    
    public init(configuration: ImageConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.configuration = ImageConfiguration()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.configuration = ImageConfiguration()
        super.init(coder: aDecoder)
    }
    
    // MARK: - View lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        for subview in [cameraController.view, galleryView, bottomContainer, topView] {
            view.addSubview(subview!)
            subview?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        view.addSubview(volumeView)
        view.sendSubviewToBack(volumeView)
        
        view.backgroundColor = UIColor.white
        view.backgroundColor = configuration.mainColor
        
        subscribe()
        setupConstraints()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if configuration.managesAudioSession {
            _ = try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        statusBarHidden = UIApplication.shared.isStatusBarHidden
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkStatus()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: bottomContainer)
    }
    
    open func resetAssets() {
        self.stack.resetAssets([])
    }
    
    func checkStatus() {
        let currentStatus = PHPhotoLibrary.authorizationStatus()
        guard currentStatus != .authorized else { return }
        
        if currentStatus == .notDetermined { hideViews() }
        
        PHPhotoLibrary.requestAuthorization { (authorizationStatus) -> Void in
            DispatchQueue.main.async {
                if authorizationStatus == .denied {
                    self.presentAskPermissionAlert()
                } else if authorizationStatus == .authorized {
                    self.permissionGranted()
                }
            }
        }
    }
    
    func presentAskPermissionAlert() {
        let alertController = UIAlertController(title: configuration.requestPermissionTitle, message: configuration.requestPermissionMessage, preferredStyle: .alert)
        
        let alertAction = UIAlertAction(title: configuration.OKButtonTitle, style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        
        let cancelAction = UIAlertAction(title: configuration.cancelButtonTitle, style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(alertAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func hideViews() {
        enableGestures(false)
    }
    
    func permissionGranted() {
        galleryView.fetchPhotos()
        enableGestures(true)
    }
    
    // MARK: - Notifications
    
    deinit {
        if configuration.managesAudioSession {
            _ = try? AVAudioSession.sharedInstance().setActive(false)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func subscribe() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustButtonTitle(_:)),
                                               name: NSNotification.Name(rawValue: ImageStack.Notifications.imageDidPush),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustButtonTitle(_:)),
                                               name: NSNotification.Name(rawValue: ImageStack.Notifications.imageDidDrop),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReloadAssets(_:)),
                                               name: NSNotification.Name(rawValue: ImageStack.Notifications.stackDidReload),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(volumeChanged(_:)),
                                               name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRotation(_:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        
    }
    
    @objc func didReloadAssets(_ notification: Notification) {
        adjustButtonTitle(notification)
        galleryView.reloadData()
    }
    
    @objc func volumeChanged(_ notification: Notification) {
        guard configuration.allowVolumeWhenTakingPicture,
              let slider = volumeView.subviews.filter({ $0 is UISlider }).first as? UISlider,
              let userInfo = (notification as NSNotification).userInfo,
              let changeReason = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String, changeReason == "ExplicitVolumeChange" else { return }
        
        slider.setValue(volume, animated: false)
        takePicture()
    }
    
    @objc func adjustButtonTitle(_ notification: Notification) {
        guard let sender = notification.object as? ImageStack else { return }
        
        let title = !sender.assets.isEmpty ?
        configuration.doneButtonTitle : configuration.cancelButtonTitle
        bottomContainer.doneButton.setTitle(title, for: UIControl.State())
    }
    
    @objc public func handleRotation(_ note: Notification?) {
        applyOrientationTransforms()
    }
    
    func applyOrientationTransforms() {
        
        self.galleryViewTop?.constant = 0
        let rotate = configuration.rotationTransform
        
        UIView.animate(withDuration: 0.25, animations: {
            [self.topView.rotateCamera, self.bottomContainer.pickerButton,
             self.bottomContainer.stackView, self.bottomContainer.doneButton].forEach {
                $0.transform = rotate
            }
            
            self.galleryView.collectionViewLayout.invalidateLayout()
            
            let translate: CGAffineTransform
            if Helper.previousOrientation.isLandscape {
                translate = CGAffineTransform(translationX: -20, y: 15)
            } else {
                translate = CGAffineTransform.identity
            }
            
            self.topView.flashButton.transform = rotate.concatenating(translate)
        })
    }
    
    // MARK: - Helpers
    
    open override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    func enableGestures(_ enabled: Bool) {
        galleryView.alpha = enabled ? 1 : 0
        bottomContainer.pickerButton.isEnabled = enabled
        bottomContainer.tapGestureRecognizer.isEnabled = enabled
        topView.flashButton.isEnabled = enabled
        topView.rotateCamera.isEnabled = configuration.canRotateCamera
    }
    
    fileprivate func isBelowImageLimit() -> Bool {
        return (imageLimit == 0 || imageLimit > galleryView.selectedStack.assets.count)
    }
    
    fileprivate func takePicture() {
        guard isBelowImageLimit() && !isTakingPicture else { return }
        isTakingPicture = true
        bottomContainer.pickerButton.isEnabled = false
        bottomContainer.stackView.startLoader()
        
        self.cameraController.takePicture { [weak self] in
            self?.isTakingPicture = false
        }
        
    }
}

// MARK: - Action methods

extension ImagePickerViewController: BottomContainerViewDelegate {
    
    func pickerButtonDidPress() {
        takePicture()
    }
    
    func doneButtonDidSelect() {
        var images: [UIImage]
        if let preferredImageSize = preferredImageSize {
            images = AssetManager.resolveAssets(stack.assets, size: preferredImageSize)
        } else {
            images = AssetManager.resolveAssets(stack.assets)
        }
        
        delegate?.doneButtonDidSelect(self, images: images)
    }
    
    func cancelButtonDidSelect() {
        delegate?.cancelButtonDidSelect(self)
    }
    
    func imageStackViewDidPress() {
        var images: [UIImage]
        if let preferredImageSize = preferredImageSize {
            images = AssetManager.resolveAssets(stack.assets, size: preferredImageSize)
        } else {
            images = AssetManager.resolveAssets(stack.assets)
        }
        
        delegate?.stackButtonDidSelect(self, images: images)
    }
}

extension ImagePickerViewController: CameraViewDelegate {
    
    func setFlashButtonHidden(_ hidden: Bool) {
        if configuration.flashButtonAlwaysHidden {
            topView.flashButton.isHidden = hidden
        }
    }
    
    func imageToLibrary() {
        
        galleryView.fetchPhotos {
            guard let asset = self.galleryView.assets.first else { return }
            if self.configuration.allowMultiplePhotoSelection == false {
                self.stack.assets.removeAll()
            }
            self.stack.pushAsset(asset)
        }
        
        galleryView.shouldTransform = true
        bottomContainer.pickerButton.isEnabled = true
        
    }
    
    func cameraNotAvailable() {
        topView.flashButton.isHidden = true
        topView.rotateCamera.isHidden = true
        bottomContainer.pickerButton.isEnabled = false
    }
    
    // MARK: - Rotation
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
}

// MARK: - TopView delegate methods

extension ImagePickerViewController: TopViewDelegate {
    
    func flashButtonDidPress(_ title: String) {
        cameraController.flashCamera(title)
    }
    
    func rotateDeviceDidPress() {
        cameraController.rotateCamera()
    }
}

// MARK: - Pan gesture handler

extension ImagePickerViewController: ImageGalleryPanGestureDelegate {
    
    func panGestureDidStart() {
        galleryViewTopStart = self.galleryViewTop?.constant ?? 0
    }
    
    func panGestureDidChange(_ translation: CGPoint) {
        self.galleryViewTop?.constant = galleryViewTopStart + translation.y
    }
    
    func panGestureDidEnd(translation: CGPoint, velocity: CGPoint) {
        let offset = galleryViewTopStart + translation.y
        let max = galleryView.frame.height - ImageGalleryView.Dimensions.galleryBarHeight - TopView.Dimensions.height
        if offset <= 0 {
            damping(0)
        } else {
            if offset > max {
                damping(max)
            } else {
                if offset < max/2 {
                    damping(0)
                } else {
                    damping(max)
                }
            }
        }
        
        func damping(_ offetValue: CGFloat) {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 30) { [weak self] in
                self?.galleryViewTop?.constant = offetValue
                self?.view.layoutIfNeeded()
            }
        }
        
    }
}

extension ImagePickerViewController {
    
    func setupConstraints() {
        
        NSLayoutConstraint.activate([
            topView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topView.topAnchor.constraint(equalTo: view.topAnchor),
            topView.heightAnchor.constraint(equalToConstant: TopView.Dimensions.height)
        ])
        
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        NSLayoutConstraint.activate([
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomContainer.heightAnchor.constraint(equalToConstant: BottomContainerView.Dimensions.height+bottom)
        ])
        
        NSLayoutConstraint.activate([
            cameraController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraController.view.topAnchor.constraint(equalTo: view.topAnchor),
            cameraController.view.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor)
        ])
        
        galleryViewTop = galleryView.topAnchor.constraint(equalTo: topView.bottomAnchor)
        NSLayoutConstraint.activate([
            galleryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            galleryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            galleryViewTop!,
            galleryView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -TopView.Dimensions.height-BottomContainerView.Dimensions.height)
        ])
        
    }
}