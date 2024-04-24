//
//  ImagePickerViewController.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit
import MediaPlayer
import Photos

public protocol ImagePickerViewControllerDelegate: AnyObject {
    func didLookAtPicking(_ imagePicker: ImagePickerViewController, items: [MediaItem])
    func didFinishPicking(_ imagePicker: ImagePickerViewController, items: [MediaItem])
    func didCancelPicking(_ imagePicker: ImagePickerViewController)
    func shouldSelectItem(_ imagePicker: ImagePickerViewController, asset: PHAsset) -> Bool
}

public extension ImagePickerViewControllerDelegate {
    func shouldSelectItem(_ imagePicker: ImagePickerViewController, asset: PHAsset) -> Bool {
        return true
    }
}

open class ImagePickerViewController: UIViewController {
    
    public let configuration: ImagePickerConfiguration
    
    open lazy var galleryView: ImageGalleryView = { [unowned self] in
        let galleryView = ImageGalleryView(configuration: self.configuration)
        galleryView.delegate = self
        galleryView.selectedStack = self.stack
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
    
    open weak var delegate: ImagePickerViewControllerDelegate?
    open var stack = ImageStack()
    open var preferredImageSize: CGSize?
    open var startOnFrontCamera = false
    private var numberOfCells: Int?
    private var galleryViewTop: NSLayoutConstraint?
    private var galleryViewTopStart: CGFloat = 0
    fileprivate var isTakingPicture = false
    open var finishButtonTitle: String? {
        didSet {
            if let finishButtonTitle = finishButtonTitle {
                bottomContainer.doneButton.setTitle(finishButtonTitle, for: UIControl.State())
            }
        }
    }
    
    // MARK: - Initialization
    
    public init(configuration: ImagePickerConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.configuration = ImagePickerConfiguration()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.configuration = ImagePickerConfiguration()
        super.init(coder: aDecoder)
    }
    
    // MARK: - View lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(bottomContainer)
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomContainer.heightAnchor.constraint(equalToConstant: BottomContainerView.Dimensions.height)
        ])

        switch configuration.sourceType {
        case .default:
            setupCamera()
            setupPhotoLibrary()
        case .photoLibrary:
            setupPhotoLibrary()
            galleryView.hideTopSeparator()
            galleryViewTop?.constant = 0
            bottomContainer.pickerButton.isHidden = true
            bottomContainer.borderPickerButton.isHidden = true
        case .camera:
            setupCamera()
        }
        
        view.backgroundColor = configuration.mainColor
        view.bringSubviewToFront(bottomContainer)
        subscribe()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if configuration.sourceType != .photoLibrary && configuration.managesAudioSession {
            _ = try? AVAudioSession.sharedInstance().setActive(true)
        }
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
        if configuration.sourceType == .camera {
            return 
        }
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
    
    fileprivate func hideViews() {
        enableGestures(false)
    }
    
    fileprivate func permissionGranted() {
        galleryView.fetchPhotos()
        enableGestures(true)
    }
    
    // MARK: - Notifications
    
    deinit {
        if configuration.sourceType != .photoLibrary && configuration.managesAudioSession {
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

        if configuration.sourceType != .camera {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleRotation(_:)),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
        }
        
        if configuration.sourceType != .photoLibrary {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(volumeChanged(_:)),
                                                   name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
                                                   object: nil)
        }

        
    }
    
    @objc func didReloadAssets(_ notification: Notification) {
        adjustButtonTitle(notification)
        if configuration.sourceType != .camera {
            galleryView.reloadData()
        }
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
        configuration.finishButtonTitle : configuration.cancelButtonTitle
        bottomContainer.doneButton.setTitle(title, for: UIControl.State())
    }
    
    @objc public func handleRotation(_ note: Notification?) {
        self.galleryViewTop?.constant = 0
        DispatchQueue.main.async {
            self.galleryView.collectionViewLayout.invalidateLayout()
        }
    }
    
    // MARK: - DeviceHelpers
    
    fileprivate func enableGestures(_ enabled: Bool) {
        galleryView.alpha = enabled ? 1 : 0
        bottomContainer.pickerButton.isEnabled = enabled
        bottomContainer.tapGestureRecognizer.isEnabled = enabled
        if configuration.sourceType != .photoLibrary {
            topView.flashButton.isEnabled = enabled
            topView.rotateCamera.isEnabled = configuration.canRotateCamera
        }
    }
    
    fileprivate func isBelowImageLimit() -> Bool {
        return (configuration.imageLimit == 0 || configuration.imageLimit > galleryView.selectedStack.assets.count)
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
    
    func didFinishPicking() {
        var images: [MediaItem]
        if let preferredImageSize = preferredImageSize {
            images = AssetManager.resolveAssets(stack.assets, size: preferredImageSize)
        } else {
            images = AssetManager.resolveAssets(stack.assets)
        }
        
        delegate?.didFinishPicking(self, items: images)
    }
    
    func didCancelPicking() {
        delegate?.didCancelPicking(self)
    }
    
    func imageStackViewDidPress() {
        var images: [MediaItem]
        if let preferredImageSize = preferredImageSize {
            images = AssetManager.resolveAssets(stack.assets, size: preferredImageSize)
        } else {
            images = AssetManager.resolveAssets(stack.assets)
        }
        
        delegate?.didLookAtPicking(self, items: images)
    }
}

extension ImagePickerViewController: CameraViewDelegate {
    
    func setFlashButtonHidden(_ hidden: Bool) {
        if configuration.sourceType != .photoLibrary && configuration.flashButtonAlwaysHidden {
            topView.flashButton.isHidden = hidden
        }
    }
    
    func imageToLibrary() {
        
        galleryView.fetchPhotos {
            guard let asset = self.galleryView.assets.first else { return }
            if self.configuration.allowMultipleSelection == false {
                self.stack.assets.removeAll()
            }
            self.stack.pushAsset(asset)
        }
        
        galleryView.shouldTransform = true
        
        bottomContainer.pickerButton.isEnabled = true
        
    }
    
    func cameraNotAvailable() {
        if configuration.sourceType != .photoLibrary {
            topView.flashButton.isHidden = true
            topView.rotateCamera.isHidden = true
        }
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
        var offset = galleryViewTopStart + translation.y
        let max = galleryView.frame.height - ImageGalleryView.Dimensions.galleryBarHeight

        if offset <= 0 {
            offset = 0
        } else if offset > max {
            offset = max
        }
        self.galleryViewTop?.constant = offset
    }
    
    func panGestureDidEnd(translation: CGPoint, velocity: CGPoint) {
        
    }
    
    func shouldSelectItemAt(asset: PHAsset) -> Bool {
        delegate?.shouldSelectItem(self, asset: asset) == true
    }
}

extension ImagePickerViewController {
    
    func setupPhotoLibrary() {
        
        let heightView = UIView()
        heightView.isHidden = true
        view.addSubview(heightView)
        heightView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heightView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heightView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor)
        ])

        view.addSubview(galleryView)
        galleryView.translatesAutoresizingMaskIntoConstraints = false
        if configuration.sourceType == .photoLibrary {
            galleryViewTop = galleryView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            NSLayoutConstraint.activate([
                heightView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            ])
        } else {
            galleryViewTop = galleryView.topAnchor.constraint(equalTo: topView.bottomAnchor)
            NSLayoutConstraint.activate([
                heightView.topAnchor.constraint(equalTo: topView.bottomAnchor)
            ])
        }
        NSLayoutConstraint.activate([
            galleryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            galleryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            galleryViewTop!,
            galleryView.heightAnchor.constraint(equalTo: heightView.heightAnchor)
        ])
        
    }
    
    func setupCamera() {
        [cameraController.view,topView].forEach { subview in
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
        
        view.addSubview(volumeView)
        view.sendSubviewToBack(volumeView)
        
        NSLayoutConstraint.activate([
            topView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topView.heightAnchor.constraint(equalToConstant: TopView.Dimensions.height)
        ])

        NSLayoutConstraint.activate([
            cameraController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraController.view.topAnchor.constraint(equalTo: view.topAnchor),
            cameraController.view.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor)
        ])
    }
}
