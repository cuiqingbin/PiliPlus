import 'package:PiliPlus/utils/bili_colors.dart';
import 'package:flutter/widgets.dart' show Color;

/// 官方播放器进度条样式（对齐 bilibili App / 粉色主题网页播放器）。
abstract final class PlayerProgressStyle {
  /// 已播放轨道，官方 `#FB7299`
  static const Color played = BiliColors.playerPink;

  /// 缓冲轨道
  static const Color buffered = Color(0x59FFFFFF);

  /// 未播放轨道
  static const Color background = Color(0x33FFFFFF);

  static const Color thumb = Color(0xFFFFFFFF);
  static const Color thumbGlow = Color(0x4DFFFFFF);

  static const double barHeight = 2.0;
  static const double thumbRadius = 6.0;
  static const double thumbGlowRadius = 11.0;

  static const double miniBarHeight = 2.0;
  static const double miniThumbRadius = 2.0;
}
