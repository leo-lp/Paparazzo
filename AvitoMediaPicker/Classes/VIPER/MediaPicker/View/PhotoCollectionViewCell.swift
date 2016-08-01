import UIKit
import AvitoDesignKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    var image: ImageSource? {
        didSet {
            updateImage()
        }
    }
    
    var selectedBorderColor: UIColor? = .blueColor() {
        didSet {
            adjustBorderColor()
        }
    }
    
    class var imageViewContentMode: UIViewContentMode {
        return .ScaleAspectFill
    }
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        adjustBorderColor()
        
        imageView.contentMode = self.dynamicType.imageViewContentMode
        imageView.clipsToBounds = true
        
        contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = contentView.bounds
        
        updateImage()
    }
    
    override var selected: Bool {
        didSet {
            layer.borderWidth = selected ? 4 : 0
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        image = nil
        imageView.image = nil
    }
    
    // MARK: - Private
    
    private func updateImage() {
        imageView.setImage(image) { [weak self, requestedImage = image, previousImage = imageView.image] in
            if self?.image !== requestedImage {
                self?.imageView.image = previousImage
            }
        }
    }
    
    private func adjustBorderColor() {
        layer.borderColor = selectedBorderColor?.CGColor
    }
}
