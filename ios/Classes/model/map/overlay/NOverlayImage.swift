import NMapsMap

internal struct NOverlayImage {
    let path: String
    let mode: NOverlayImageMode

    var overlayImage: NMFOverlayImage? {
        print("[NOverlayImage] overlayImage 호출 - path: \(path), mode: \(mode)")
        
        let result: NMFOverlayImage?
        switch mode {
        case .file, .temp, .widget: 
            print("[NOverlayImage] file/temp/widget 모드로 처리")
            result = makeOverlayImageWithPath()
        case .asset: 
            print("[NOverlayImage] asset 모드로 처리")
            result = makeOverlayImageWithAssetPath()
        }
        
        print("[NOverlayImage] overlayImage 결과: \(result != nil ? "성공" : "실패")")
        return result
    }

    private func makeOverlayImageWithPath() -> NMFOverlayImage? {
        print("[NOverlayImage] makeOverlayImageWithPath 시작 - path: \(path)")
        
        // 파일 존재 여부 확인
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: path)
        print("[NOverlayImage] 파일 존재 여부: \(fileExists) - path: \(path)")
        
        if !fileExists {
            print("[NOverlayImage] 파일이 존재하지 않음 - path: \(path)")
            return nil
        }
        
        // 파일 크기 확인
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("[NOverlayImage] 파일 크기: \(fileSize) bytes - path: \(path)")
            
            if fileSize == 0 {
                print("[NOverlayImage] 파일 크기가 0입니다 - path: \(path)")
                return nil
            }
        } catch {
            print("[NOverlayImage] 파일 속성 확인 실패: \(error) - path: \(path)")
        }
        
        guard let image = UIImage(contentsOfFile: path) else {
            print("[NOverlayImage] UIImage 생성 실패 (file/temp/widget) - path: \(path)")
            return nil
        }
        print("[NOverlayImage] UIImage 생성 성공 - size: \(image.size), scale: \(image.scale)")
        
        guard let pngData = image.pngData() else {
            print("[NOverlayImage] PNG 데이터 변환 실패 - path: \(path)")
            return nil
        }
        print("[NOverlayImage] PNG 데이터 변환 성공 - size: \(pngData.count) bytes")
        
        guard let scaledImage = UIImage(data: pngData, scale: UIScreen.main.scale) else {
            print("[NOverlayImage] 이미지 스케일 변환 실패 (file/temp/widget) - path: \(path), screen scale: \(UIScreen.main.scale)")
            return nil
        }
        print("[NOverlayImage] 이미지 스케일 변환 성공 - size: \(scaledImage.size), scale: \(scaledImage.scale)")
        
        let overlayImage = NMFOverlayImage(image: scaledImage)
        print("[NOverlayImage] NMFOverlayImage 생성 성공")
        return overlayImage
    }

    private func makeOverlayImageWithAssetPath() -> NMFOverlayImage? {
        print("[NOverlayImage] makeOverlayImageWithAssetPath 시작 - path: \(path)")
        
        let key = SwiftFlutterNaverMapPlugin.getAssets(path: path)
        print("[NOverlayImage] Asset key: \(key)")
        
        let assetPath = Bundle.main.path(forResource: key, ofType: nil) ?? ""
        print("[NOverlayImage] Asset path: \(assetPath)")
        
        guard !assetPath.isEmpty else {
            print("[NOverlayImage] asset 경로 탐색 실패 - key: \(key)")
            return nil
        }
        
        // 파일 존재 여부 확인
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: assetPath)
        print("[NOverlayImage] Asset 파일 존재 여부: \(fileExists) - path: \(assetPath)")
        
        if !fileExists {
            print("[NOverlayImage] Asset 파일이 존재하지 않음 - path: \(assetPath)")
            return nil
        }
        
        guard let image = UIImage(contentsOfFile: assetPath) else {
            print("[NOverlayImage] asset 이미지 로드 실패 - assetPath: \(assetPath)")
            return nil
        }
        print("[NOverlayImage] Asset UIImage 생성 성공 - size: \(image.size), scale: \(image.scale)")
        
        guard let pngData = image.pngData() else {
            print("[NOverlayImage] Asset PNG 데이터 변환 실패 - assetPath: \(assetPath)")
            return nil
        }
        print("[NOverlayImage] Asset PNG 데이터 변환 성공 - size: \(pngData.count) bytes")
        
        guard let scaledImage = UIImage(data: pngData, scale: UIScreen.main.scale) else {
            print("[NOverlayImage] asset 이미지 스케일 변환 실패 - assetPath: \(assetPath), screen scale: \(UIScreen.main.scale)")
            return nil
        }
        print("[NOverlayImage] Asset 이미지 스케일 변환 성공 - size: \(scaledImage.size), scale: \(scaledImage.scale)")
        
        let overlayImage = NMFOverlayImage(image: scaledImage, reuseIdentifier: assetPath)
        print("[NOverlayImage] Asset NMFOverlayImage 생성 성공 - reuseIdentifier: \(assetPath)")
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
