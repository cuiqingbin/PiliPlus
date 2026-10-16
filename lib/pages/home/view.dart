import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/custom_height_widget.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/scroll_behavior.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart'
    show platformClampingPhysics, tabBarView;
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends CommonPageState<HomePage>
    with AutomaticKeepAliveClientMixin {
  late ColorScheme _colorScheme;
  final _homeController = Get.putOrFind(HomeController.new);
  final _mainController = Get.find<MainController>();

  @override
  bool get needsCorrection =>
      _homeController.hideTopBar && !_homeController.useNestedHeader;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = ColorScheme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget tabBar;
    if (_homeController.tabs.length > 1) {
      tabBar = SizedBox(
        height: 36,
        width: double.infinity,
        child: TabBar(
          controller: _homeController.tabController,
          tabs: _homeController.tabs
              .map((e) => Tab(text: e.label, height: 36))
              .toList(),
          isScrollable: true,
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          splashBorderRadius: Style.mdRadius,
          tabAlignment: TabAlignment.center,
          indicatorSize: TabBarIndicatorSize.label,
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          onTap: (_) {
            feedBack();
            if (!_homeController.tabController.indexIsChanging) {
              _homeController.animateToTop();
            }
          },
        ),
      );
      if (_homeController.hideTopBar) {
        tabBar = Material(
          color: _colorScheme.surface,
          child: tabBar,
        );
      }
    } else {
      tabBar = const SizedBox(height: 6);
    }
    final tabs = tabBarView(
      controller: _homeController.tabController,
      children: _homeController.tabs.map((e) => e.page).toList(),
    );
    final showAppBar =
        !_mainController.useSideBar && MediaQuery.sizeOf(context).isPortrait;
    if (showAppBar && _homeController.useNestedHeader) {
      return onBuild(
        HomeNestedScope(
          child: ExtendedNestedScrollView(
            key: _homeController.nestedScrollKey,
            onlyOneScrollInBody: true,
            floatHeaderSlivers: true,
            pinnedHeaderSliverHeightBuilder: () => 0,
            physics: platformClampingPhysics,
            scrollBehavior: const NoOverscrollIndicator(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: false,
                  floating: true,
                  snap: false,
                  primary: false,
                  automaticallyImplyLeading: false,
                  toolbarHeight: Style.topBarHeight,
                  titleSpacing: 0,
                  backgroundColor: _colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  flexibleSpace: searchBarRow(),
                ),
              ];
            },
            body: Column(
              children: [
                tabBar,
                Expanded(child: tabs),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        if (showAppBar) customAppBar(),
        tabBar,
        Expanded(child: onBuild(tabs)),
      ],
    );
  }

  Widget searchBarRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        children: [
          userAvatar(colorScheme: _colorScheme, mainController: _mainController),
          const SizedBox(width: 8),
          searchBar(),
          const SizedBox(width: 2),
          msgBadge(_mainController),
        ],
      ),
    );
  }

  Widget customAppBar() {
    if (_homeController.hideTopBar) {
      if (_mainController.barOffset case final barOffset?) {
        return Obx(
          () {
            final offset = barOffset.value;
            return CustomHeightWidget(
              offset: Offset(0, -offset),
              height: Style.topBarHeight - offset,
              child: searchBarRow(),
            );
          },
        );
      }
      if (_homeController.showTopBar case final showTopBar?) {
        return Obx(() {
          final showSearchBar = showTopBar.value;
          return AnimatedOpacity(
            opacity: showSearchBar ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              curve: Curves.easeInOutCubicEmphasized,
              duration: const Duration(milliseconds: 500),
              height: showSearchBar ? Style.topBarHeight : 0,
              child: searchBarRow(),
            ),
          );
        });
      }
    }
    return SizedBox(
      height: Style.topBarHeight,
      child: searchBarRow(),
    );
  }

  Widget searchBar() {
    const borderRadius = BorderRadius.all(Radius.circular(16));
    return Expanded(
      child: SizedBox(
        height: 32,
        child: Material(
          borderRadius: borderRadius,
          color: _colorScheme.onSecondaryContainer.withValues(alpha: 0.06),
          child: InkWell(
            borderRadius: borderRadius,
            splashColor: _colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
            onTap: () => Get.toNamed(
              '/search',
              parameters: _homeController.enableSearchWord
                  ? {'hintText': _homeController.defaultSearch.value}
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(
                  Icons.search_outlined,
                  size: 18,
                  color: _colorScheme.outline,
                  semanticLabel: '搜索',
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Obx(
                    () => Text(
                      _homeController.defaultSearch.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: _colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget userAvatar({
  required ColorScheme colorScheme,
  required MainController mainController,
}) {
  return Semantics(
    label: "我的",
    child: Obx(
      () {
        if (mainController.accountService.isLogin.value) {
          return Stack(
            clipBehavior: .none,
            children: [
              NetworkImgLayer(
                type: .avatar,
                width: 32,
                height: 32,
                src: mainController.accountService.face.value,
              ),
              Positioned.fill(
                child: Material(
                  type: .transparency,
                  child: InkWell(
                    onTap: mainController.toMinePage,
                    splashColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    customBorder: const CircleBorder(),
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Obx(
                  () => MineController.anonymity.value
                      ? IgnorePointer(
                          child: Container(
                            padding: const .all(2),
                            decoration: BoxDecoration(
                              shape: .circle,
                              color: colorScheme.secondaryContainer,
                            ),
                            child: Icon(
                              size: 14,
                              MdiIcons.incognito,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          );
        }
        return Material(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            onTap: mainController.toMinePage,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                '登录',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget msgBadge(MainController mainController) {
  return Obx(
    () {
      final isLogin = mainController.accountService.isLogin.value;
      final count = mainController.msgUnReadCount.value;
      final isNumBadge = mainController.msgBadgeMode == .number;
      return IconButton(
        tooltip: '消息',
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.all(6),
          minimumSize: const Size(32, 32),
        ),
        onPressed: () {
          if (!isLogin) {
            mainController.toMinePage();
            return;
          }
          mainController
            ..clearUnreadMsg()
            ..lastCheckUnreadAt = DateTime.now().millisecondsSinceEpoch;
          Get.toNamed('/whisper');
        },
        icon: Badge(
          isLabelVisible:
              isLogin &&
              mainController.msgBadgeMode != .hidden &&
              count != null,
          alignment: isNumBadge
              ? const Alignment(0.0, -0.85)
              : const Alignment(1.0, -0.85),
          label: isNumBadge && count != null ? Text(count) : null,
          child: const Icon(Icons.mail_outline, size: 22),
        ),
      );
    },
  );
}
