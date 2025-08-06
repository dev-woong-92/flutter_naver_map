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
  /// [preloadImages]가 `true`일 경우, 위젯 내부의 이미지를 미리 로드한 후 렌더링합니다.
  /// 이미지가 포함된 위젯을 사용할 때는 반드시 `preloadImages: true`로 설정하세요.
  static Future<NOverlayImage> fromWidget({
    required Widget widget,
    Size? size,
    required BuildContext context,
    bool preloadImages = false,
  }) async {
    if (!preloadImages) {
      assert(
          widget.runtimeType != Image,
          "Do not use Image widget without preloadImages: true.\n"
          "Set preloadImages: true or use `NOverlayImage.fromAssetImage` or `.fromFile` or `.fromByteArray` Constructor.");
    }

    Widget finalWidget = widget;

    if (preloadImages) {
      finalWidget = await _preloadImagesInWidget(widget, context);
    }

    final imageBytes = await WidgetToImageUtil.widgetToImageByte(finalWidget,
        size: size, context: context);
    final path = await ImageUtil.saveImage(imageBytes);
    return NOverlayImage._(path: path, mode: _NOverlayImageMode.widget);
  }

  /// 위젯 내부의 모든 이미지를 미리 로드합니다.
  static Future<Widget> _preloadImagesInWidget(
      Widget widget, BuildContext context) async {
    // 🔥 성능 최적화: 간단한 문자열 체크로 이미지 존재 여부 확인
    final widgetString = widget.toString();
    final hasImages = widgetString.contains('Image') ||
        widgetString.contains('DecorationImage') ||
        widgetString.contains('AssetImage');

    if (!hasImages) {
      return widget; // 이미지가 없으면 바로 반환
    }

    // 이미지가 있을 때만 재귀 탐색 수행
    final imageProviders = <ImageProvider>[];
    _findImageProviders(widget, imageProviders);

    // 모든 이미지 pre-load
    for (final provider in imageProviders) {
      try {
        await precacheImage(provider, context);
      } catch (e) {
        // 개별 이미지 로드 실패는 무시하고 계속 진행
        print('Failed to preload image: $e');
      }
    }

    return widget;
  }

  /// 재귀적으로 위젯 트리에서 이미지 프로바이더를 찾습니다.
  static void _findImageProviders(Widget widget, List<ImageProvider> providers,
      {int depth = 0}) {
    // 🔥 성능 최적화: 깊이 제한 (너무 깊은 위젯 트리 방지)
    if (depth > 10) return;

    if (widget is Image) {
      providers.add(widget.image);
    } else if (widget is Container) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration) {
        final backgroundImage = decoration.image;
        if (backgroundImage != null) {
          providers.add(backgroundImage.image);
        }
      }
    } else if (widget is DecoratedBox) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration) {
        final backgroundImage = decoration.image;
        if (backgroundImage != null) {
          providers.add(backgroundImage.image);
        }
      }
    }

    // 🔥 성능 최적화: 이미 충분한 이미지를 찾았으면 조기 종료
    if (providers.length >= 5) return;

    // 자식 위젯들도 재귀적으로 검사
    final child = _getChild(widget);
    if (child != null) {
      _findImageProviders(child, providers, depth: depth + 1);
    }

    final children = _getChildren(widget);
    for (final child in children) {
      _findImageProviders(child, providers, depth: depth + 1);
      // 🔥 성능 최적화: 이미 충분한 이미지를 찾았으면 조기 종료
      if (providers.length >= 5) break;
    }
  }

  /// 위젯에서 자식 위젯을 추출합니다.
  static Widget? _getChild(Widget widget) {
    if (widget is SizedBox) return widget.child;
    if (widget is Container) return widget.child;
    if (widget is Padding) return widget.child;
    if (widget is Center) return widget.child;
    if (widget is Align) return widget.child;
    if (widget is ClipRRect) return widget.child;
    if (widget is GestureDetector) return widget.child;
    if (widget is Expanded) return widget.child;
    if (widget is Flexible) return widget.child;
    // 필요한 위젯 타입들을 추가
    return null;
  }

  /// 위젯에서 자식 위젯들을 추출합니다.
  static List<Widget> _getChildren(Widget widget) {
    if (widget is Row) return widget.children;
    if (widget is Column) return widget.children;
    if (widget is Stack) return widget.children;
    if (widget is Wrap) return widget.children;
    // ListView는 children이 없으므로 제거
    // 필요한 위젯 타입들을 추가
    return [];
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
