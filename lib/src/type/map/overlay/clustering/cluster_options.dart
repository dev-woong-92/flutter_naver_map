part of "../../../../../flutter_naver_map.dart";

/// 클러스터링 기능에 대한 옵션들입니다.
class NaverMapClusteringOptions with NMessageableWithMap {
  /// 클러스터링 기능이 활성화 될 줌 범위를 지정합니다.
  ///
  /// 기본 값은 [defaultClusteringZoomRange] (0 ~ 20).
  final NInclusiveRange<int> enableZoomRange;

  /// 클러스터링이 이루어질 때 실행되는 애니메이션의 시간을 지정합니다.
  ///
  /// 기본 값은 `300ms`.
  final Duration animationDuration;

  /// 클러스터가 병합될 기본 전략을 지정합니다.
  ///
  /// 기본 값은 `NClusterMergeStrategy()` 기본 생성자.
  final NClusterMergeStrategy mergeStrategy;

  /// 클러스터 마커의 속성을 지정할 수 있습니다.
  ///
  /// 기본 값은 null이며, 이때는 기본적으로 [NaverMapClusteringOptions.defaultClusterMarkerBuilder]가 실행됩니다.
  final Function(NClusterInfo info, NClusterMarker clusterMarker)?
  clusterMarkerBuilder;

  const NaverMapClusteringOptions({
    this.enableZoomRange = defaultClusteringZoomRange,
    this.animationDuration = const Duration(milliseconds: 300),
    this.mergeStrategy = const NClusterMergeStrategy(),
    this.clusterMarkerBuilder,
  });

  void _handleClusterMarkerBuilder(
    Object args,
    _NOverlayController overlayController,
  ) {
    try {
      print("[NaverMapClusteringOptions] _handleClusterMarkerBuilder 시작");
      print("[NaverMapClusteringOptions] args 타입: ${args.runtimeType}");
      print("[NaverMapClusteringOptions] args 내용: $args");

      if (args is! Map) {
        print(
          "[NaverMapClusteringOptions] 오류: args가 Map이 아님 - ${args.runtimeType}",
        );
        return;
      }

      final info = NClusterInfo._fromMessageable(args);
      print("[NaverMapClusteringOptions] NClusterInfo 생성 성공: $info");

      final clusterMarker = NClusterMarker._(
        id: info._id,
        position: info.position,
      );
      print(
        "[NaverMapClusteringOptions] NClusterMarker 생성 성공: ${clusterMarker.id}",
      );

      final builder = clusterMarkerBuilder ?? defaultClusterMarkerBuilder;
      print(
        "[NaverMapClusteringOptions] 사용할 builder: ${builder == defaultClusterMarkerBuilder ? 'default' : 'custom'}",
      );

      try {
        builder.call(info, clusterMarker);
        print("[NaverMapClusteringOptions] builder 호출 성공");
      } catch (e, stackTrace) {
        print("[NaverMapClusteringOptions] builder 호출 실패: $e");
        print("[NaverMapClusteringOptions] stackTrace: $stackTrace");
        return;
      }

      try {
        clusterMarker._apply(overlayController);
        print("[NaverMapClusteringOptions] clusterMarker._apply 성공");
      } catch (e, stackTrace) {
        print("[NaverMapClusteringOptions] clusterMarker._apply 실패: $e");
        print("[NaverMapClusteringOptions] stackTrace: $stackTrace");
      }
    } catch (e, stackTrace) {
      print(
        "[NaverMapClusteringOptions] _handleClusterMarkerBuilder 전체 실패: $e",
      );
      print("[NaverMapClusteringOptions] stackTrace: $stackTrace");
    }
  }

  static void defaultClusterMarkerBuilder(
    NClusterInfo info,
    NClusterMarker clusterMarker,
  ) {
    try {
      print("[NaverMapClusteringOptions] defaultClusterMarkerBuilder 시작");
      print("[NaverMapClusteringOptions] info: $info");
      print("[NaverMapClusteringOptions] clusterMarker: ${clusterMarker.id}");

      final caption = NOverlayCaption(
        text: info.size.toString(),
        color: Colors.white,
        haloColor: Colors.transparent,
      );
      print("[NaverMapClusteringOptions] NOverlayCaption 생성: $caption");

      clusterMarker.setCaption(caption);
      print("[NaverMapClusteringOptions] setCaption 성공");
    } catch (e, stackTrace) {
      print("[NaverMapClusteringOptions] defaultClusterMarkerBuilder 실패: $e");
      print("[NaverMapClusteringOptions] stackTrace: $stackTrace");
    }
  }

  @override
  NPayload toNPayload() => NPayload.make({
    "enableZoomRange": enableZoomRange,
    "animationDuration": animationDuration.inMilliseconds,
    "mergeStrategy": mergeStrategy,
  });

  @override
  String toString() => "$runtimeType: ${toNPayload().map}";

  NaverMapClusteringOptions copyWith({
    NInclusiveRange<int>? enableZoomRange,
    Duration? animationDuration,
    NClusterMergeStrategy? mergeStrategy,
    Function(NClusterInfo info, NClusterMarker clusterMarker)?
    clusterMarkerBuilder,
  }) => NaverMapClusteringOptions(
    enableZoomRange: enableZoomRange ?? this.enableZoomRange,
    animationDuration: animationDuration ?? this.animationDuration,
    mergeStrategy: mergeStrategy ?? this.mergeStrategy,
    clusterMarkerBuilder: clusterMarkerBuilder ?? this.clusterMarkerBuilder,
  );

  static const defaultClusteringZoomRange = NInclusiveRange(0, 20);

  //region equals & hashCodes
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NaverMapClusteringOptions &&
          runtimeType == other.runtimeType &&
          enableZoomRange == other.enableZoomRange &&
          animationDuration == other.animationDuration &&
          mergeStrategy == other.mergeStrategy;

  // clusterMarkerBuilder is Unstable for equality (lambda)

  @override
  int get hashCode =>
      enableZoomRange.hashCode ^
      animationDuration.hashCode ^
      mergeStrategy.hashCode;
  // clusterMarkerBuilder is Unstable for equality (lambda)
  //endregion
}
