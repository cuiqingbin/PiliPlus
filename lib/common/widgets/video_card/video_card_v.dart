import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models_new/video/video_detail/dimension.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/extension/dimension_ext.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 垂直布局（首页推荐，对齐官方 Bilibili）
class VideoCardV extends StatelessWidget {
  final BaseRcmdVideoItemModel videoItem;
  final VoidCallback? onRemove;

  const VideoCardV({
    super.key,
    required this.videoItem,
    this.onRemove,
  });

  Future<void> onPushDetail() async {
    switch (videoItem.goto) {
      case 'bangumi':
        PageUtils.viewPgc(epId: videoItem.param!);
        break;
      case 'av':
        var bvid = videoItem.bvid ?? IdUtils.av2bv(videoItem.aid!);
        var cid = videoItem.cid;
        bool isVertical = false;
        Dimension? dimension;
        if (videoItem is RcmdVideoItemAppModel) {
          if (videoItem.uri case final uri?) {
            isVertical = uri.isVerticalFromUri;
          }
        }
        if (cid == null) {
          if (await SearchHttp.ab2cWithDimension(aid: videoItem.aid, bvid: bvid)
              case final res?) {
            cid = res.cid;
            dimension = res.dimension;
          }
        }
        if (cid != null) {
          PageUtils.toVideoPage(
            aid: videoItem.aid,
            bvid: bvid,
            cid: cid,
            cover: videoItem.cover,
            title: videoItem.title,
            isVertical: isVertical,
            dimension: dimension,
          );
        }
        break;
      // 动态
      case 'picture':
        try {
          PiliScheme.routePushFromUrl(videoItem.uri!);
        } catch (err) {
          SmartDialog.showToast(err.toString());
        }
        break;
      default:
        if (videoItem.uri?.isNotEmpty == true) {
          PiliScheme.routePushFromUrl(videoItem.uri!);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    void onLongPress() => imageSaveDialog(
      title: videoItem.title,
      cover: videoItem.cover,
      bvid: videoItem.bvid,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: Style.mdRadius,
          clipBehavior: .antiAlias,
          child: InkWell(
            onTap: onPushDetail,
            onLongPress: onLongPress,
            onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                _cover(),
                content(context),
              ],
            ),
          ),
        ),
        if (videoItem.goto == 'av')
          Positioned(
            right: -4,
            bottom: -4,
            width: 28,
            height: 28,
            child: VideoPopupMenu(
              iconSize: 16,
              videoItem: videoItem,
              onRemove: onRemove,
            ),
          ),
      ],
    );
  }

  Widget _cover() {
    final isLive = videoItem.isLive;
    return AspectRatio(
      aspectRatio: Style.aspectRatio,
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          final maxWidth = boxConstraints.maxWidth;
          final maxHeight = boxConstraints.maxHeight;
          return ClipRRect(
            borderRadius: Style.mdRadius,
            child: Stack(
              fit: .expand,
              children: [
                NetworkImgLayer(
                  src: videoItem.cover,
                  width: maxWidth,
                  height: maxHeight,
                  borderRadius: .zero,
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: .topCenter,
                        end: .bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: SizedBox(height: 36),
                  ),
                ),
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 5,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRect(
                          child: Row(
                            children: [
                              StatWidget(
                                type: .play,
                                value: videoItem.stat.view,
                                color: Colors.white,
                                iconSize: 13,
                                fontSize: 11,
                              ),
                              if (videoItem.goto != 'picture') ...[
                                const SizedBox(width: 8),
                                StatWidget(
                                  type: .danmaku,
                                  value: videoItem.stat.danmu,
                                  color: Colors.white,
                                  iconSize: 13,
                                  fontSize: 11,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isLive)
                        const PBadge(
                          text: '直播',
                          isStack: false,
                          size: .small,
                          type: .primary,
                          fontSize: 10,
                          padding: .symmetric(horizontal: 4, vertical: 1.5),
                        )
                      else if (videoItem.duration > 0)
                        PBadge(
                          text: DurationUtils.formatDuration(
                            videoItem.duration,
                          ),
                          isStack: false,
                          size: .small,
                          type: .gray,
                          fontSize: 10,
                          padding: const .symmetric(
                            horizontal: 4,
                            vertical: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline;
    final rcmdReason = videoItem.rcmdReason;
    return Expanded(
      child: Padding(
        padding: const .fromLTRB(6, 7, 6, 5),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: Text(
                videoItem.title,
                maxLines: 2,
                overflow: .ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.25,
                  fontWeight: .w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              spacing: 4,
              children: [
                if (videoItem.goto == 'bangumi')
                  PBadge(
                    text: videoItem.pgcBadge,
                    isStack: false,
                    size: .small,
                    type: .line_primary,
                    fontSize: 9,
                  ),
                if (videoItem.goto == 'picture')
                  const PBadge(
                    text: '动态',
                    isStack: false,
                    size: .small,
                    type: .line_primary,
                    fontSize: 9,
                  ),
                if (rcmdReason != null)
                  Expanded(
                    child: Text(
                      rcmdReason,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: outline,
                      ),
                    ),
                  )
                else ...[
                  if (videoItem.goto != 'picture')
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const .all(.circular(2)),
                        border: .all(color: outline, width: 0.7),
                      ),
                      child: Padding(
                        padding: const .symmetric(horizontal: 3, vertical: 1),
                        child: Text(
                          'UP',
                          style: TextStyle(
                            fontSize: 8,
                            height: 1,
                            color: outline,
                            fontWeight: .w600,
                          ),
                          strutStyle: const StrutStyle(
                            fontSize: 8,
                            height: 1,
                            leading: 0,
                            fontWeight: .w600,
                          ),
                        ),
                      ),
                    ),
                  if (videoItem.isFollowed)
                    const PBadge(
                      text: '已关注',
                      isStack: false,
                      size: .small,
                      type: .secondary,
                      fontSize: 9,
                    ),
                  Expanded(
                    child: Text(
                      videoItem.owner.name.toString(),
                      maxLines: 1,
                      overflow: .ellipsis,
                      semanticsLabel: 'UP：${videoItem.owner.name}',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: outline,
                      ),
                    ),
                  ),
                ],
                if (videoItem.goto == 'av') const SizedBox(width: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static final shortFormat = DateFormat('M-d');
  static final longFormat = DateFormat('yy-M-d');
}
