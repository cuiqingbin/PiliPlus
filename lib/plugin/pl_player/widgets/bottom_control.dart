import 'package:PiliPlus/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:PiliPlus/common/widgets/progress_bar/segment_progress_bar.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/progress_style.dart';
import 'package:PiliPlus/plugin/pl_player/view/view.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class BottomControl extends StatelessWidget {
  const BottomControl({
    super.key,
    required this.maxWidth,
    required this.isFullScreen,
    required this.controller,
    required this.buildBottomControl,
    required this.videoDetailController,
  });

  final double maxWidth;
  final bool isFullScreen;
  final PlPlayerController controller;
  final ValueGetter<Widget> buildBottomControl;
  final VideoDetailController videoDetailController;

  void onDragStart(ThumbDragDetails duration) {
    feedBack();
    controller.onSeekStart(duration.seconds);
  }

  void onDragUpdate(ThumbDragDetails duration) {
    if (!controller.isFileSource && controller.showSeekPreview) {
      controller.updatePreviewIndex(duration.seconds);
    }
    controller.seekPosition.value = duration.seconds;
  }

  void onSeek(int milliseconds) {
    controller
      ..position.value = milliseconds ~/ 1000
      ..onSeekEnd()
      ..seekTo(Duration(milliseconds: milliseconds), isSeek: false);
  }

  @override
  Widget build(BuildContext context) {
    const progressPink = PlayerProgressStyle.played;

    return Padding(
      padding: const .symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
            child: Obx(
              () => Offstage(
                offstage: !controller.showControls.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Obx(
                      () => ProgressBar(
                        progress: controller.progress,
                        buffered: controller.buffered.value,
                        total: controller.duration.value,
                        progressBarColor: progressPink,
                        baseBarColor: PlayerProgressStyle.background,
                        bufferedBarColor: PlayerProgressStyle.buffered,
                        thumbColor: PlayerProgressStyle.thumb,
                        thumbGlowColor: PlayerProgressStyle.thumbGlow,
                        barHeight: PlayerProgressStyle.barHeight,
                        thumbRadius: PlayerProgressStyle.thumbRadius,
                        thumbGlowRadius: PlayerProgressStyle.thumbGlowRadius,
                        thumbShape: ProgressThumbShape.biliTv,
                        onDragStart: onDragStart,
                        onDragUpdate: onDragUpdate,
                        onSeek: onSeek,
                      ),
                    ),
                    if (controller.enableBlock &&
                        videoDetailController.segmentProgressList.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SegmentProgressBar(
                          height: PlayerProgressStyle.barHeight,
                          segments: videoDetailController.segmentProgressList,
                        ),
                      ),
                    if (controller.showViewPoints &&
                        videoDetailController.viewPointList.isNotEmpty &&
                        videoDetailController.showVP.value)
                      Padding(
                        padding: const .only(bottom: 2),
                        child: ViewPointSegmentProgressBar(
                          segments: videoDetailController.viewPointList,
                          onSeek: PlatformUtils.isDesktop
                              ? (position) =>
                                    controller.seekTo(position, isSeek: false)
                              : null,
                        ),
                      ),
                    if (videoDetailController.showDmTrendChart.value)
                      if (videoDetailController.dmTrend.value?.dataOrNull
                          case final list?)
                        buildDmChart(
                          progressPink,
                          list,
                          videoDetailController,
                          4.5,
                        ),
                  ],
                ),
              ),
            ),
          ),
          buildBottomControl(),
        ],
      ),
    );
  }
}
