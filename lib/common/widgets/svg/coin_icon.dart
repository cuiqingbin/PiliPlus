import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Official Bilibili 投币 icon (circle + 币), 28×28 viewBox.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 28" fill="none">'
      '<path fill="currentColor" fill-rule="evenodd" clip-rule="evenodd" d="'
      'M14 26C7.373 26 2 20.627 2 14S7.373 2 14 2s12 5.373 12 12-5.373 12-12 12zm0-1.75c5.66 0 10.25-4.59 10.25-10.25S19.66 3.75 14 3.75 3.75 8.34 3.75 14 8.34 24.25 14 24.25z'
      'M14.89 8.664h3.276c.541 0 .979-.4.979-.892s-.438-.892-.979-.892H9.681c-.541 0-.979.4-.979.892s.438.892.979.892h3.425v1.637a5.64 5.64 0 0 0-5.355 5.616v1.19a.892.892 0 1 0 1.784.001v-1.19a3.855 3.855 0 0 1 3.57-3.831v8.329a.892.892 0 0 0 1.784 0v-8.329a3.855 3.855 0 0 1 3.57 3.831v1.19a.892.892 0 0 0 1.784 0v-1.19a5.64 5.64 0 0 0-5.355-5.616V8.664z'
      '"/></svg>';

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconSize = size ?? iconTheme.size ?? 18;
    final iconColor = iconTheme.color ?? color ?? const Color(0xFF61666D);
    return SvgPicture.string(
      _svg,
      width: iconSize,
      height: iconSize,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}
