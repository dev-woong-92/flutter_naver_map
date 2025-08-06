part of "../../../../flutter_naver_map.dart";

// todo 1 : 재사용 식별자(Identifier) 사용

/// 지도에서 사용할 수 있는 이미지 객체입니다.
///
/// 에셋, 파일, byteArray, 위젯을 통해 생성할 수 있습니다.
///
/// 메모리의 효율적인 사용을 위해, 한번 생성한 객체는 되도록 재사용해주세요.
class NOverlayImage with NMessageableWithMap {
  final String _path;
  final _NOverlayImageMode _mode;

  const NOverlayImage._({
    required String path,
    required _NOverlayImageMode mode,
  })  : _path = path,
        _mode = mode;

  /// 이미지 에셋으로 지도에서 사용할 이미지를 생성합니다. (jpg, png supported)
  const NOverlayImage.fromAssetImage(String assetName)
      : _path = assetName,
        _mode = _NOverlayImageMode.asset;

  /// 이미지 파일으로 지도에서 사용할 이미지를 생성합니다. (jpg, png supported)
  NOverlayImage.fromFile(File file)
      : _path = file.path,
        _mode = _NOverlayImageMode.file;

  /// ByteArray로 지도에서 사용할 이미지를 생성합니다. (캐시를 사용합니다)
  static Future<NOverlayImage> fromByteArray(Uint8List imageBytes) async {
    final path = await ImageUtil.saveImage(imageBytes);
    return NOverlayImage._(path: path, mode: _NOverlayImageMode.temp);
  }

  /// 위젯을 지도의 이미지로 생성합니다. (캐시를 사용합니다)
  ///
  /// 위젯을 이미지로 변환한 후 사용하므로, 인터렉션이 불가능함을 알아두세요.
  ///
  /// [size]가 `null`일 경우, 위젯의 사이즈에 맞춰 렌더링됩니다.
  ///
  /// [size]를 `null`로 설정함과 동시에 constraint가 `infinity`가 되지 않도록 유의하세요.
  ///
  /// [appImages]를 전달하면 해당 AppImage들의 이미지를 미리 로드한 후 렌더링합니다.
  /// 이미지가 포함된 위젯을 사용할 때는 반드시 `appImages`를 전달하세요.
  static Future<NOverlayImage> fromWidget({
    required Widget widget,
    Size? size,
    required BuildContext context,
    List<dynamic>? appImages, // AppImage 리스트
  }) async {
    print(
        '🚀 [NOverlayImage] fromWidget called with appImages: ${appImages?.length ?? 0}');
    print('🚀 [NOverlayImage] Widget type: ${widget.runtimeType}');
    print('🚀 [NOverlayImage] Size: $size');

    // AppImage가 없고 Image 위젯을 직접 사용하는 경우 경고
    if (appImages == null || appImages.isEmpty) {
      assert(
          widget.runtimeType != Image,
          "Do not use Image widget without appImages.\n"
          "Pass appImages list or use `NOverlayImage.fromAssetImage` or `.fromFile` or `.fromByteArray` Constructor.");
    }

    // AppImage 직접 전달 방식
    if (appImages != null && appImages.isNotEmpty) {
      print(
          '🔄 [NOverlayImage] Preloading ${appImages.length} AppImages directly...');
      await _preloadAppImages(appImages, context);
      print('✅ [NOverlayImage] AppImage preload completed');
    }

    print('🔄 [NOverlayImage] Converting widget to image bytes...');
    final imageBytes = await WidgetToImageUtil.widgetToImageByte(widget,
        size: size, context: context);
    print(
        '✅ [NOverlayImage] Widget converted to image bytes (${imageBytes.length} bytes)');

    print('🔄 [NOverlayImage] Saving image to file...');
    final path = await ImageUtil.saveImage(imageBytes);
    print('✅ [NOverlayImage] Image saved to: $path');

    final result = NOverlayImage._(path: path, mode: _NOverlayImageMode.widget);
    print('🎉 [NOverlayImage] NOverlayImage created successfully');

    return result;
  }

  /// AppImage 리스트를 직접 pre-load합니다.
  static Future<void> _preloadAppImages(
      List<dynamic> appImages, BuildContext context) async {
    for (final appImage in appImages) {
      try {
        // AppImage에서 imageProvider 추출
        final imageProvider = appImage.imageProvider;
        if (imageProvider != null) {
          print('🔄 [NOverlayImage] Preloading AppImage: ${appImage.path}');
          await precacheImage(imageProvider, context);
          print(
              '✅ [NOverlayImage] Successfully preloaded AppImage: ${appImage.path}');
        } else {
          print(
              '⚠️ [NOverlayImage] AppImage has no imageProvider: ${appImage.path}');
        }
      } catch (e) {
        print('❌ [NOverlayImage] Failed to preload AppImage: $e');
      }
    }
  }

  @override
  NPayload toNPayload() => NPayload.make({
        "path": _path,
        "mode": _mode,
      });

  @override
  String toString() => "NOverlayImage{from: ${_mode.toExplainString()}}";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NOverlayImage &&
          runtimeType == other.runtimeType &&
          _path == other._path &&
          _mode == other._mode;

  @override
  int get hashCode => _path.hashCode ^ _mode.hashCode;
}
