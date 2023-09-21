//
//  ImageGalleryView.swift
//  ImagePickerViewController
//
//  Created by LC on 2023/9/19.
//

import UIKit
import Photos

protocol ImageGalleryPanGestureDelegate: AnyObject {
    func panGestureDidStart()
    func panGestureDidChange(_ translation: CGPoint)
    func panGestureDidEnd(translation: CGPoint, velocity: CGPoint)

}

open class ImageGalleryView: UIView {
    
    struct Dimensions {
        static let galleryBarHeight: CGFloat = 30
    }
    
    var configuration = ImagePickerConfiguration()
    
    lazy private var collectionView: UICollectionView = { [unowned self] in
        let collectionView = UICollectionView(frame: CGRect.zero,
                                              collectionViewLayout: self.collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = self.configuration.mainColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
    
    lazy var collectionViewLayout: UICollectionViewLayout = { [unowned self] in
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = self.configuration.cellSpacing
        layout.minimumLineSpacing = self.configuration.cellSpacing
        layout.sectionInset = UIEdgeInsets.zero
        
        return layout
    }()
    
    lazy var topSeparator: UIView = { [unowned self] in
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(self.panGestureRecognizer)
        view.backgroundColor = self.configuration.gallerySeparatorColor
        
        return view
    }()
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(handlePanGestureRecognizer(_:)))
        
        return gesture
    }()
        
    open lazy var selectedStack = ImageStack()
    lazy var assets = [PHAsset]() 
    
    weak var delegate: ImageGalleryPanGestureDelegate?
    var shouldTransform = false
    var imagesBeforeLoading = 0
    var fetchResult: PHFetchResult<AnyObject>?
    var imageLimit = 0
    // MARK: - Initializers
    
    public init(configuration: ImagePickerConfiguration? = nil) {
        if let configuration = configuration {
            self.configuration = configuration
        }
        super.init(frame: .zero)
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        
        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topSeparator)
        NSLayoutConstraint.activate([
            topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparator.topAnchor.constraint(equalTo: topAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: Dimensions.galleryBarHeight)
        ])

        let indicatorView = UIView()
        indicatorView.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        indicatorView.layer.cornerRadius = 4
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        topSeparator.addSubview(indicatorView)
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: topSeparator.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: topSeparator.centerYAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: 40),
            indicatorView.heightAnchor.constraint(equalToConstant: 8)
        ])

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: topSeparator.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        backgroundColor = configuration.mainColor
        
        collectionView.register(ImageGalleryViewCell.self,
                                forCellWithReuseIdentifier: CollectionView.reusableIdentifier)
        
        
        
        imagesBeforeLoading = 0
        fetchPhotos()
    }
    
    // MARK: - Photos handler
    
    func reloadData() {
        collectionView.reloadData()
    }
    func fetchPhotos(_ completion: (() -> Void)? = nil) {
        AssetManager.fetch(withImageConfiguration: configuration) { assets in
            self.assets.removeAll()
            self.assets.append(contentsOf: assets)
            self.collectionView.reloadData()
            
            completion?()
        }
    }
    
    // MARK: - Pan gesture recognizer
    
    @objc func handlePanGestureRecognizer(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        
        switch gesture.state {
        case .began:
            delegate?.panGestureDidStart()
        case .changed:
            delegate?.panGestureDidChange(gesture.translation(in: superview))
        case .ended:
            delegate?.panGestureDidEnd(translation: gesture.translation(in: superview), velocity: gesture.velocity(in: superview))
        default: break
        }
    }
    
}

// MARK: CollectionViewFlowLayout delegate methods

extension ImageGalleryView: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let column = CGFloat(configuration.cellColumn)
        let w = (collectionView.frame.width - configuration.cellSpacing * column - 1)/column
        return CGSizeMake(w, w)
    }
}

// MARK: CollectionView delegate methods

extension ImageGalleryView: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath)
                as? ImageGalleryViewCell else { return }
        if configuration.allowMultiplePhotoSelection == false {
            // Clear selected photos array
            for asset in self.selectedStack.assets {
                self.selectedStack.dropAsset(asset)
            }
            // Animate deselecting photos for any selected visible cells
            guard let visibleCells = collectionView.visibleCells as? [ImageGalleryViewCell] else { return }
            for cell in visibleCells where cell.selectedView?.isHidden == false {
                cell.selectedView?.isHidden = true
            }
        }
        
        let asset = assets[(indexPath as NSIndexPath).row]
        
        AssetManager.resolveAsset(asset, size: CGSize(width: 100, height: 100), shouldPreferLowRes: configuration.useLowResolutionPreviewImage) { image in
            guard image != nil else { return }
            
            if cell.selectedView?.isHidden == false  {
                cell.selectedView?.isHidden = true
                self.selectedStack.dropAsset(asset)
            } else if self.imageLimit == 0 || self.imageLimit > self.selectedStack.assets.count {
                cell.selectedView?.isHidden = false
                self.selectedStack.pushAsset(asset)
            }
        }
    }
}

extension ImageGalleryView: UICollectionViewDataSource {
    
    struct CollectionView {
        static let reusableIdentifier = "imagesReusableIdentifier"
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionView.reusableIdentifier,
                                                            for: indexPath) as? ImageGalleryViewCell else { return UICollectionViewCell() }
        
        let asset = assets[(indexPath as NSIndexPath).row]
        
        AssetManager.resolveAsset(asset, size: CGSize(width: 160, height: 240), shouldPreferLowRes: configuration.useLowResolutionPreviewImage) { [unowned self] image in
            if let image = image {
                cell.configureCell(image)
                
                if (indexPath as NSIndexPath).row == 0 && self.shouldTransform {
                    cell.transform = CGAffineTransform(scaleX: 0, y: 0)
                    
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIView.AnimationOptions(), animations: {
                        cell.transform = CGAffineTransform.identity
                    }) { _ in }
                    
                    self.shouldTransform = false
                }
                
                if cell.selectedView == nil {
                    if let selectedView = self.configuration.selectedBackgroundView?() {
                        selectedView.isUserInteractionEnabled = false
                        cell.addSelectedView(selectedView)
                    } else {
                        let selectedView = UIView()
                        selectedView.layer.borderColor = UIColor.yellow.withAlphaComponent(0.7).cgColor
                        selectedView.layer.borderWidth = 1
                        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                        cell.addSelectedView(selectedView)
                    }
                }
                
                cell.selectedView?.isHidden = !self.selectedStack.containsAsset(asset)
                cell.duration = asset.duration
            }
        }
        
        return cell
    }
}
