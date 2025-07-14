import NMapsMap

internal struct NOverlayImage {
    let path: String
    let mode: NOverlayImageMode

    var overlayImage: NMFOverlayImage? {
        switch mode {
        case .file, .temp, .widget: return makeOverlayImageWithPath()
        case .asset: return makeOverlayImageWithAssetPath()
        }
    }

    private func makeOverlayImageWithPath() -> NMFOverlayImage? {
        guard let image = UIImage(contentsOfFile: path) else {
            print("[NOverlayImage] 이미지 로드 실패 (file/temp/widget) - path: \(path)")
            return nil
        }
        guard let pngData = image.pngData(),
              let scaledImage = UIImage(data: pngData, scale: UIScreen.main.scale) else {
            print("[NOverlayImage] 이미지 스케일 변환 실패 (file/temp/widget) - path: \(path)")
            return nil
        }
        return NMFOverlayImage(image: scaledImage)
    }

    private func makeOverlayImageWithAssetPath() -> NMFOverlayImage? {
        let key = SwiftFlutterNaverMapPlugin.getAssets(path: path)
        let assetPath = Bundle.main.path(forResource: key, ofType: nil) ?? ""
        guard !assetPath.isEmpty else {
            print("[NOverlayImage] asset 경로 탐색 실패 - key: \(key)")
            return nil
        }
        guard let image = UIImage(contentsOfFile: assetPath) else {
            print("[NOverlayImage] asset 이미지 로드 실패 - assetPath: \(assetPath)")
            return nil
        }
        guard let pngData = image.pngData(),
              let scaledImage = UIImage(data: pngData, scale: UIScreen.main.scale) else {
            print("[NOverlayImage] asset 이미지 스케일 변환 실패 - assetPath: \(assetPath)")
            return nil
        }
        return NMFOverlayImage(image: scaledImage, reuseIdentifier: assetPath)
    }

    func toMessageable() -> Dictionary<String, Any> {
        [
            "path": path,
            "mode": mode.rawValue
        ]
    }

    static func fromMessageable(_ v: Any) -> NOverlayImage {
        let d = asDict(v)
        return NOverlayImage(
                path: asString(d["path"]!),
                mode: NOverlayImageMode(rawValue: asString(d["mode"]!))!
        )
    }

    static let none = NOverlayImage(path: "", mode: .temp)
}
