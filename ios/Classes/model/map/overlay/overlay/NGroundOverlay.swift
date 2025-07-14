import NMapsMap

internal struct NGroundOverlay: AddableOverlay {
    typealias OverlayType = NMFGroundOverlay
    var overlayPayload: Dictionary<String, Any?> = [:]

    let info: NOverlayInfo
    let bounds: NMGLatLngBounds
    let image: NOverlayImage
    let alpha: CGFloat

    func createMapOverlay() -> OverlayType? {
        guard let image = image.overlayImage else {
            print("[NGroundOverlay] overlayImage가 nil입니다. 오버레이를 생성하지 않습니다.")
            return nil
        }
        let overlay = NMFGroundOverlay(bounds: bounds, image: image)
        return applyAtRawOverlay(overlay)
    }
    
    func applyAtRawOverlay(_ overlay: NMFGroundOverlay) -> NMFGroundOverlay {
        overlay.alpha = alpha
        return overlay
    }

    static func fromMessageable(_ v: Any) -> NGroundOverlay {
        let d = asDict(v)
        return NGroundOverlay(
                info: NOverlayInfo.fromMessageable(d[infoName]!),
                bounds: asLatLngBounds(d[boundsName]!),
                image: NOverlayImage.fromMessageable(d[imageName]!),
                alpha: asCGFloat(d[alphaName]!)
        )
    }

    /*
    --- Messaging Name Define ---
    */

    private static let infoName = "info"
    static let boundsName = "bounds"
    static let imageName = "image"
    static let alphaName = "alpha"
}
