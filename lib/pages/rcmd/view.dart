import 'package:PiliPlus/common/skeleton/video_card_v.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart'
    show platformAlwaysClampingPhysics;
import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/rcmd/controller.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class RcmdPage extends StatefulWidget {
  const RcmdPage({super.key});

  @override
  State<RcmdPage> createState() => _RcmdPageState();
}

class _RcmdPageState extends State<RcmdPage>
    with AutomaticKeepAliveClientMixin {
  final controller = Get.put(RcmdController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = ColorScheme.of(context);
    final isDark = colorScheme.brightness == Brightness.dark;
    final nested = HomeNestedScope.of(context);
    return ColoredBox(
      color: isDark ? colorScheme.surfaceContainerLow : Style.feedBackground,
      child: refreshIndicator(
        onRefresh: controller.onRefresh,
        isClampingScrollPhysics: nested,
        child: CustomScrollView(
          controller: HomeNestedScope.controllerFor(
            context,
            controller.scrollController,
          ),
          cacheExtent: 800,
          physics: nested
              ? const AlwaysScrollableScrollPhysics()
              : platformAlwaysClampingPhysics,
          slivers: [
            SliverPadding(
              padding: const .fromLTRB(8, Style.cardSpace, 8, 100),
              sliver: Obx(
                () => _buildBody(colorScheme, controller.loadingState.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: 7,
    crossAxisSpacing: 7,
    maxCrossAxisExtent: Pref.recommendCardWidth,
    childAspectRatio: Style.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(70),
  );

  Widget _buildBody(
    ColorScheme colorScheme,
    LoadingState<List<dynamic>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => _buildSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? _buildContent(colorScheme, response)
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _buildContent(ColorScheme colorScheme, List<dynamic> response) {
    final lastRefreshAt = controller.lastRefreshAt;
    if (lastRefreshAt == null ||
        lastRefreshAt <= 0 ||
        lastRefreshAt >= response.length) {
      return _buildGrid(response, start: 0, count: response.length);
    }
    return SliverMainAxisGroup(
      slivers: [
        _buildGrid(response, start: 0, count: lastRefreshAt),
        SliverToBoxAdapter(child: _buildSeenHereTip(colorScheme)),
        _buildGrid(
          response,
          start: lastRefreshAt,
          count: response.length - lastRefreshAt,
        ),
      ],
    );
  }

  Widget _buildSeenHereTip(ColorScheme colorScheme) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (HomeNestedScope.of(context)) {
          Get.find<HomeController>().animateToTop();
        } else {
          controller.animateToTop();
        }
        controller.onRefresh();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Text(
              '刚刚看到这里，点击刷新',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.vipColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.refresh,
              size: 16,
              color: colorScheme.vipColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    List<dynamic> response, {
    required int start,
    required int count,
  }) {
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemCount: count,
      itemBuilder: (context, index) {
        final actualIndex = start + index;
        if (actualIndex == response.length - 1) {
          controller.onLoadMore();
        }
        return VideoCardV(
          videoItem: response[actualIndex],
          onRemove: () {
            if (controller.lastRefreshAt != null &&
                actualIndex < controller.lastRefreshAt!) {
              controller.lastRefreshAt = controller.lastRefreshAt! - 1;
              if (controller.lastRefreshAt == 0) {
                controller.lastRefreshAt = null;
              }
            }
            controller.loadingState
              ..value.data!.removeAt(actualIndex)
              ..refresh();
          },
        );
      },
    );
  }

  Widget get _buildSkeleton => SliverGrid(
    gridDelegate: gridDelegate,
    delegate: const SliverSingleChildDelegate(
      count: 10,
      child: VideoCardVSkeleton(),
    ),
  );
}
