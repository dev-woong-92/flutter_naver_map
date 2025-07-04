part of "../../flutter_naver_map.dart";

/// 네이버 맵을 띄울 수 있는 위젯입니다.
class NaverMap extends StatefulWidget {
  /// 네이버 맵의 보여지는 여러 UI 속성들을 컨트롤 할 수 있는 옵션입니다.
  ///
  /// 기본 값은 `NaverMapViewOptions()`입니다.
  final NaverMapViewOptions options;

  /// 클러스터링 기능에 대한 옵션들입니다.
  ///
  /// 이 옵션들은 클러스터링 기능을 사용할 때, 즉 `NClusterableMarker`가 추가 되었을 때 확인할 수 있습니다.
  ///
  /// 기본 값은 `NaverMapClusterOptions()`입니다.
  final NaverMapClusteringOptions clusterOptions;

  /// 스크롤 가능한 뷰 안에서 사용할 때, 지도에 제스처가 먼저 전달되도록 하는 옵션입니다.
  ///
  /// 기본값은 `false`입니다.
  final bool forceGesture;

  @visibleForTesting
  final bool? forceHybridComposition;

  @visibleForTesting
  final bool? forceGLSurfaceView;

  /*
    --- Events ---
  */

  /// 지도가 조작할 수 있는 첫 시점에 실행 되는 함수입니다.
  /// 위젯 첫 빌드 시에 한 번만 실행 됩니다.
  /// 이 콜백을 통해, [NaverMapController]를 매개변수로 얻을 수 있습니다.
  final void Function(NaverMapController controller)? onMapReady;

  /// 지도가 사용자에 의해 터치 되었을 때 실행 되는 함수입니다.
  ///
  /// 사용자가 화면의 어디를 터치 했는지 [NPoint]를,
  /// 지도에서 어느 장소를 터치 했는지 [NLatLng]를 매개변수로 제공합니다.
  ///
  /// 하지만 심볼을 터치 하는 때에는 해당 메서드가 실행 되지 않습니다. 대신, [onSymbolTapped]이 실행됩니다.
  /// 만약, 심볼 여부와 상관 없이 onMapTapped 메서드를 실행 시키도록 하고 싶다면,
  /// [options.consumeSymbolTapEvents]을 `false`로 설정하세요.
  final void Function(NPoint point, NLatLng latLng)? onMapTapped;

  /// 심볼이 사용자에 의해 터치될 때, 실행 되는 함수입니다.
  /// 사용자가 터치한 심볼의 정보인 [NSymbolInfo]를 매개변수로 제공합니다.
  final void Function(NSymbolInfo symbolInfo)? onSymbolTapped;

  /// 지도의 어느 영역을 보여줄지 지정하는 카메라가, 다른 위치로 변경 되는 중에 실행 되는 함수입니다.
  /// 어떤 이유로 카메라가 이동했는지 알 수 있는 [NCameraUpdateReason]과,
  /// 애니메이션과 함께 부드럽게 이동했는지 알 수 있는 [bool]값을 매개변수로 제공합니다.
  final void Function(NCameraUpdateReason reason, bool animated)?
      onCameraChange;

  /// 카메라가 완전히 멈추었을 때, 실행 되는 함수입니다.
  /// 매 카메라 이동마다 [onCameraChange] 다음에 한번만 실행됩니다.
  final void Function()? onCameraIdle;

  /// 보이는 실내 지도가 바뀔 때, 실행되는 함수입니다.
  /// 현재 보이는 실내 지도의 정보 [NSelectedIndoor]를 매개변수로 제공합니다.
  /// 실내 지도 영역에서 벗어나는 때에 해당 값은 `null`로 제공됩니다.
  ///
  /// 실내 지도 옵션[option.indoorEnable]이 설정되어 있는 경우에만 실행됩니다.
  final void Function(NSelectedIndoor? selectedIndoor)? onSelectedIndoorChanged;

  const NaverMap({
    super.key,
    this.options = const NaverMapViewOptions(),
    this.clusterOptions = const NaverMapClusteringOptions(),
    this.forceGesture = false,
    this.onMapReady,
    this.onMapTapped,
    this.onSymbolTapped,
    this.onCameraChange,
    this.onCameraIdle,
    this.onSelectedIndoorChanged,
    @visibleForTesting this.forceHybridComposition,
    @visibleForTesting this.forceGLSurfaceView,
  });

  @override
  State<NaverMap> createState() => _NaverMapState();
}

class _NaverMapState extends State<NaverMap>
    with _NaverMapControlHandler, NChannelWrapper {
  @override
  late final MethodChannel channel;
  late final NaverMapController controller;
  final controllerCompleter = Completer<NaverMapController>();
  late NaverMapViewOptions nowViewOptions = widget.options;
  NaverMapClusteringOptions? nowClusterOptions;
  final legacyMapInitializer = NaverMapSdk.instance;
  final onMapReadyTasksQueue = <Future Function()>[];
  bool isMapReady = false;

  @override
  Widget build(BuildContext context) {
    assert(
        FlutterNaverMap._isInitialized || legacyMapInitializer._isInitialized);

    _updateOptionsIfNeeded();

    return Stack(children: [
      Positioned.fill(
          child: _PlatformViewCreator.createPlatformView(
        viewType: NChannel.naverMapNativeView.str,
        gestureRecognizers: _createGestureRecognizers(widget.forceGesture),
        creationParams: widget.options.toNPayload(),
        onPlatformViewCreated: _onPlatformViewCreated,
        androidSdkVersion: FlutterNaverMap._androidSdkVersion ??
            legacyMapInitializer._androidSdkVersion,
        forceHybridComposition: widget.forceHybridComposition,
        forceGLSurfaceView: widget.forceGLSurfaceView,
      )),
      _naverLogo(widget.options),
    ]);
  }

  Widget _naverLogo(final NaverMapViewOptions options) {
    final align = options.logoAlign;
    final fullPadding = options.contentPadding + options.logoMargin;
    return Positioned(
        left: align.isLeft ? fullPadding.left : null,
        right: align.isRight ? fullPadding.right : null,
        top: align.isTop ? fullPadding.top : null,
        bottom: align.isBottom ? fullPadding.bottom : null,
        child: FutureBuilder(
            future: controllerCompleter.future,
            builder: (context, snapshot) {
              return NMapLogoWidget(
                  naverMapController: snapshot.data,
                  logoClickEnable: options.logoClickEnable);
            }));
  }

  void _onPlatformViewCreated(int id) {
    initChannel(NChannel.naverMapNativeView, id: id, handler: handle);
    controller = NaverMapController._createController(channel,
        viewId: id,
        initialCameraPosition: widget.options.initialCameraPosition);
  }

  Set<Factory<OneSequenceGestureRecognizer>> _createGestureRecognizers(
      bool forceGesture) {
    final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {};
    if (forceGesture) {
      gestureRecognizers
          .add(Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()));
    }
    return gestureRecognizers;
  }

  void _updateOptionsIfNeeded() {
    final List<Future Function()> updateQueue = [];
    if (nowViewOptions != widget.options) {
      nowViewOptions = widget.options;
      updateQueue.add(() => controller.updateOptions(nowViewOptions));
    }
    if (nowClusterOptions != widget.clusterOptions) {
      nowClusterOptions = widget.clusterOptions;
      updateQueue
          .add(() => controller._updateClusteringOptions(nowClusterOptions!));
    }

    if (updateQueue.isNotEmpty) {
      if (isMapReady) {
        for (final update in updateQueue) {
          update.call();
        }
      } else {
        onMapReadyTasksQueue.addAll(updateQueue);
      }
    }
  }

  Future<void> _runOnMapReadyTasks() async {
    final tasks = List<Future Function()>.from(onMapReadyTasksQueue);
    onMapReadyTasksQueue.clear();
    for (final task in tasks) {
      try {
        await task();
      } catch (e) {
        debugPrint("Error on running onMapReadyTasks: $e");
      }
    }
  }

  /*
    --- handler ---
  */

  @override
  void onMapReady() async {
    controllerCompleter.complete(controller);
    await _runOnMapReadyTasks();
    isMapReady = true;
    widget.onMapReady?.call(controller);
  }

  @override
  void onMapTapped(NPoint point, NLatLng latLng) =>
      widget.onMapTapped?.call(point, latLng);

  @override
  void onSymbolTapped(NSymbolInfo symbol) =>
      widget.onSymbolTapped?.call(symbol);

  @override
  void onCameraChange(NCameraUpdateReason reason, bool animated) =>
      widget.onCameraChange?.call(reason, animated);

  // like hot stream. (if needed, migrate to stream based event handling)
  @override
  void onCameraChangeWithCameraPosition(
      NCameraUpdateReason reason, bool animated, NCameraPosition position) {
    controller._updateNowCameraPositionData(position);
    widget.onCameraChange?.call(reason, animated);
  }

  @override
  void onSelectedIndoorChanged(NSelectedIndoor? selectedIndoor) =>
      widget.onSelectedIndoorChanged?.call(selectedIndoor);

  @override
  void onCameraIdle() => widget.onCameraIdle?.call();

  @override
  void onAnotherMethod(String methodName, dynamic args) {
    switch (methodName) {
      case "clusterMarkerBuilder":
        nowClusterOptions?._handleClusterMarkerBuilder(
            args, (controller as _NaverMapControllerImpl).overlayController);
        break;
    }
  }

  @override
  void dispose() {
    controllerCompleter.future.then((_) => controller.dispose());
    disposeChannel();
    super.dispose();
  }
}
