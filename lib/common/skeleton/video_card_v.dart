import 'package:PiliPlus/common/skeleton/skeleton.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:material_ui/material_ui.dart';

class VideoCardVSkeleton extends StatelessWidget {
  const VideoCardVSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final color = colorScheme.onInverseSurface;
    return Skeleton(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: Style.mdRadius,
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            AspectRatio(
              aspectRatio: Style.aspectRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: Style.mdRadius,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const .fromLTRB(6, 7, 6, 5),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Container(width: 200, height: 13, color: color),
                    Container(
                      height: 13,
                      width: 140,
                      color: color,
                      margin: const .only(top: 4),
                    ),
                    const Spacer(),
                    Container(
                      height: 11,
                      width: 80,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
