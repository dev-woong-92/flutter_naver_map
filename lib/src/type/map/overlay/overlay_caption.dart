part of "../../../../flutter_naver_map.dart";

/// 마커에 텍스트로 부가정보를 나타낼 때 사용할 수 있는 캡션 객체입니다.
///
/// 캡션의 크기나, 색깔, 캡션의 테두리 색깔, 폭, 보이는 줌 범위를 지정할 수 있습니다.
class NOverlayCaption with NMessageableWithMap {
  /// 캡션 텍스트
  final String text;

  /// 캡션 텍스트 사이즈
  ///
  /// 기본값은 `12`입니다.
  final double textSize;

  /// 캡션 텍스트 색상
  ///
  /// 기본값은 [Colors.black]입니다.
  final Color color;

  /// 캡션 테두리 색상
  ///
  /// 기본값은 [Colors.white]입니다.
  final Color haloColor;

  /// 캡션이 보이는 최소 줌 레벨
  ///
  /// 기본 값은 지도의 최소 줌 레벨인 [NaverMapViewOptions.minimumZoom] (0)입니다.
  final double minZoom;

  /// 캡션이 보이는 최대 줌 레벨
  ///
  /// 기본 값은 지도의 최대 줌 레벨인 [NaverMapViewOptions.maximumZoom] (21)입니다.
  final double maxZoom;

  /// 개행될 너비를 지정합니다.
  /// 단위는 플러터에서 사용하는 것과 동일한 DP(논리픽셀)입니다.
  ///
  /// 개행은 어절단위로 이루어집니다.
  ///
  /// 기본 값은 제한하지 않음을 의미하는 `0`입니다.
  final double requestWidth;

  /// 텍스트의 최대 줄 수를 제한합니다.
  ///
  /// 지정된 줄 수를 초과하는 텍스트는 잘라내고 "..."을 추가합니다.
  /// null인 경우 줄 수 제한이 없습니다.
  ///
  /// 기본값은 null입니다.
  final int? maxLines;

  const NOverlayCaption({
    required this.text,
    this.textSize = 12.0,
    this.color = Colors.black,
    this.haloColor = Colors.white,
    this.minZoom = NaverMapViewOptions.minimumZoom,
    this.maxZoom = NaverMapViewOptions.maximumZoom,
    this.requestWidth = 0,
    this.maxLines,
  });

  /// maxLines와 requestWidth에 따라 처리된 텍스트를 반환합니다.
  String get processedText {
    String processedText = text;

    // requestWidth 처리 (네이티브 SDK가 제대로 작동하지 않을 경우를 대비)
    if (requestWidth > 0) {
      processedText = _wrapTextByWidth(processedText, requestWidth);
    }

    // maxLines 처리
    if (maxLines != null) {
      final lines = processedText.split('\n');
      if (lines.length > maxLines!) {
        processedText = lines.take(maxLines!).join('\n') + '...';
      }
    }

    return processedText;
  }

  /// 텍스트를 지정된 너비에 맞게 줄바꿈 처리합니다.
  String _wrapTextByWidth(String text, double widthDp) {
    // 간단한 근사치 계산 (실제로는 더 정확한 계산이 필요할 수 있음)
    final approximateCharsPerLine = (widthDp / (textSize * 0.6)).round();

    if (text.length <= approximateCharsPerLine) return text;

    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';

    for (final word in words) {
      if ((currentLine + word).length <= approximateCharsPerLine) {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = word;
        } else {
          // 단어가 한 줄보다 긴 경우 강제로 자름
          lines.add(word.substring(0, approximateCharsPerLine));
          currentLine = word.substring(approximateCharsPerLine);
        }
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.join('\n');
  }

  @override
  NPayload toNPayload() => NPayload.make({
        "text": processedText,
        "textSize": textSize,
        "color": color,
        "haloColor": haloColor,
        "minZoom": minZoom,
        "maxZoom": maxZoom,
        "requestWidth": requestWidth,
        "maxLines": maxLines,
      });
}
