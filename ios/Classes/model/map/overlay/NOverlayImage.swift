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
        // 파일 존재 여부 확인
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: path)
        // print("[NOverlayImage] 파일이 존재하지 않음 - path: \(path)")
        if !fileExists {
            // print("[NOverlayImage] 파일이 존재하지 않음 - path: \(path)")
            return nil
        }
        // 파일 크기 확인
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            if fileSize == 0 {
                // print("[NOverlayImage] 파일 크기가 0입니다 - path: \(path)")
                return nil
            }
        } catch {
            // print("[NOverlayImage] 파일 속성 확인 실패: \(error)")
        }
        guard let image = UIImage(contentsOfFile: path) else {
            // print("[NOverlayImage] UIImage 생성 실패 (file/temp/widget) - path: \(path)")
            return nil
        }
        guard let pngData = image.pngData() else {
            // print("[NOverlayImage] PNG 데이터 변환 실패 - path: \(path)")
            return nil
        }
        guard let scaledImage = UIImage(data: pngData, scale: UIScreen.main.scale) else {
            // print("[NOverlayImage] 이미지 스케일 변환 실패 (file/temp/widget) - path: \(path)")
            return nil
        }
        let overlayImage = NMFOverlayImage(image: scaledImage)
        return overlayImage
    }

    private func makeOverlayImageWithAssetPath() -> NMFOverlayImage? {
        let key = SwiftFlutterNaverMapPlugin.getAssets(path: path)
        let assetPath = Bundle.main.path(forResource: key, ofType: nil) ?? ""
        guard !assetPath.isEmpty else {
            // print("[NOverlayImage] asset 경로 탐색 실패 - key: \(key)")
            return nil
        }
        // 파일 존재 여부 확인
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: assetPath)
        if !fileExists {
            // print("[NOverlayImage] Asset 파일이 존재하지 않음 - path: \(assetPath)")
            return nil
        }
        guard let image = UIImage(contentsOfFile: assetPath) else {
            // print("[NOverlayImage] asset 이미지 로드 실패 - assetPath: \(assetPath)")
            return nil
        }
        guard let pngData = image.pngData() else {
            // print("[NOverlayImage] Asset PNG 데이터 변환 실패 - assetPath: \(assetPath)")
            return nil
        }
        guard let scaledImage = UIImage(data: pngData, scale: UIScreen.main.scale) else {
            // print("[NOverlayImage] asset 이미지 스케일 변환 실패 - assetPath: \(assetPath)")
            return nil
        }
        let overlayImage = NMFOverlayImage(image: scaledImage, reuseIdentifier: assetPath)
        return overlayImage
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
