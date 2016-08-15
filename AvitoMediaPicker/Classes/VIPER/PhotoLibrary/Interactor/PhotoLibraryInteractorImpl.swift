import Foundation
import Photos

final class PhotoLibraryInteractorImpl: PhotoLibraryInteractor {
    
    private var selectedItems = [PhotoLibraryItem]()
    private var maxSelectedItemsCount: Int?
    
    // MARK: - Dependencies
    
    private let photoLibraryItemsService: PhotoLibraryItemsService
    
    private var _imageManager: PHImageManager?

    // Нельзя сразу создавать PHImageManager, иначе он крэшнется при деаллокации, если доступ к photo library запрещен
    private var imageManager: PHImageManager {
        if let imageManager = _imageManager {
            return imageManager
        } else {
            let imageManager = PHImageManager()
            _imageManager = imageManager
            return imageManager
        }
    }
    
    // MARK: - Init
    
    init(
        selectedItems: [PhotoLibraryItem],
        maxSelectedItemsCount: Int? = nil,
        photoLibraryItemsService: PhotoLibraryItemsService
    ) {
        self.selectedItems = selectedItems
        self.maxSelectedItemsCount = maxSelectedItemsCount
        self.photoLibraryItemsService = photoLibraryItemsService
    }
    
    // MARK: - PhotoLibraryInteractor
    
    func setMaxSelectedItemsCount(count: Int?) {
        maxSelectedItemsCount = count
    }
    
    func authorizationStatus(completion: (accessGranted: Bool) -> ()) {
        completion(accessGranted: photoLibraryItemsService.authorizationStatus == .Authorized)
    }
    
    func observeItems(handler: (items: [PhotoLibraryItem], selectionState: PhotoLibraryItemSelectionState) -> ()) {
        
        photoLibraryItemsService.observePhotos { [weak self] assets in
            guard let strongSelf = self else { return }
            
            strongSelf.removeSelectedItemsNotPresentedAmongAssets(assets)
            
            dispatch_async(dispatch_get_main_queue()) {
                handler((
                    items: strongSelf.photoLibraryItems(from: assets),
                    selectionState: strongSelf.selectionState()
                ))
            }
        }
    }
    
    func selectItem(item: PhotoLibraryItem, completion: PhotoLibraryItemSelectionState -> ()) {
        
        if canSelectMoreItems() {
            selectedItems.append(item)
        }
        
        completion(selectionState())
    }
    
    func deselectItem(item: PhotoLibraryItem, completion: PhotoLibraryItemSelectionState -> ()) {
        
        if let index = selectedItems.indexOf(item) {
            selectedItems.removeAtIndex(index)
        }
        
        completion(selectionState())
    }
    
    func selectedItems(completion: [PhotoLibraryItem] -> ()) {
        completion(selectedItems)
    }
    
    // MARK: - Private
    
    private func canSelectMoreItems() -> Bool {
        return maxSelectedItemsCount.flatMap { selectedItems.count < $0 } ?? true
    }
    
    private func selectionState() -> PhotoLibraryItemSelectionState {
        return PhotoLibraryItemSelectionState(
            isAnyItemSelected: selectedItems.count > 0,
            canSelectMoreItems: canSelectMoreItems()
        )
    }
    
    private func removeSelectedItemsNotPresentedAmongAssets(assets: [PHAsset]) {
        let assetIds = Set(assets.map { $0.localIdentifier })
        selectedItems = selectedItems.filter { assetIds.contains($0.identifier) }
    }
    
    private func photoLibraryItems(from assets: [PHAsset]) -> [PhotoLibraryItem] {
        
        return assets.map { asset in
            
            let identifier = asset.localIdentifier
            let image = PHAssetImageSource(asset: asset, imageManager: imageManager)
            
            return PhotoLibraryItem(
                identifier: identifier,
                image: image,
                selected: selectedItems.contains { $0.identifier == identifier }
            )
        }
    }
}