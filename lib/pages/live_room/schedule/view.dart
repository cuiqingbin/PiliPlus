import 'dart:io' show Platform;
import 'dart:math' show max, min;

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/main.dart' show webViewEnvironment;
import 'package:PiliPlus/models_new/live/live_room_tab/item.dart';
import 'package:PiliPlus/plugin/linux_webview.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class LiveSchedulePanel extends StatefulWidget {
  const LiveSchedulePanel({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
  });

  final List<LiveRoomScheduleTab> tabs;
  final int initialIndex;

  static const _bg = Color(0xFF1B1F2A);
  static const _tabHeight = 46.0;

  static Future<void> show(
    BuildContext context, {
    required List<LiveRoomScheduleTab> tabs,
    int initialIndex = 0,
  }) {
    if (tabs.isEmpty) {
      return Future.value();
    }
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.viewPaddingOf(context);
    // Sit fully below the 16:9 player (LiveRoomPage._buildPH), with a small
    // gap so the tab bar does not cover the picture.
    const gap = 12.0;
    final videoHeight = size.width / Style.aspectRatio16x9;
    final videoBottom = padding.top + kToolbarHeight + videoHeight;
    final available = size.height - videoBottom - gap;
    final sheetHeight = size.height > size.width
        ? max(0.0, available)
        : min(size.height * 0.55, size.height - padding.vertical);
    return showModalBottomSheet(
      context: context,
      useSafeArea: false,
      isScrollControlled: true,
      enableDrag: false,
      barrierColor: Colors.transparent,
      backgroundColor: _bg,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: Style.bottomSheetRadius,
      ),
      constraints: BoxConstraints(
        maxWidth: size.shortestSide > 600 ? 520 : size.width,
        maxHeight: sheetHeight,
      ),
      builder: (context) {
        return Theme(
          data: ThemeUtils.darkTheme,
          child: SizedBox(
            height: sheetHeight,
            width: double.infinity,
            child: LiveSchedulePanel(
              tabs: tabs,
              initialIndex: initialIndex.clamp(0, tabs.length - 1),
            ),
          ),
        );
      },
    );
  }

  @override
  State<LiveSchedulePanel> createState() => _LiveSchedulePanelState();
}

class _LiveSchedulePanelState extends State<LiveSchedulePanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Future<void> Function()? _webGoBack;
  var _canGoBack = false;

  bool get _showBack => _canGoBack;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    )..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() => _canGoBack = false);
    }
  }

  Future<void> _onBack() async {
    if (_canGoBack) {
      await _webGoBack?.call();
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final tab = widget.tabs[_tabController.index];
    return PopScope(
      canPop: !_showBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onBack();
        }
      },
      child: Column(
        children: [
          SizedBox(
            height: LiveSchedulePanel._tabHeight,
            child: Row(
              children: [
                if (_showBack)
                  IconButton(
                    tooltip: '返回',
                    onPressed: _onBack,
                    icon: const Icon(Icons.arrow_back, size: 20),
                  ),
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerHeight: 0,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                    labelColor: const Color(0xFFFF6699),
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    indicatorColor: const Color(0xFFFF6699),
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: widget.tabs.map((e) => Tab(text: e.title)).toList(),
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: Get.back,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _ScheduleWebView(
              key: ValueKey(tab.url),
              url: tab.url,
              onGoBackReady: (goBack) => _webGoBack = goBack,
              onCanGoBackChanged: (canGoBack) {
                if (_canGoBack == canGoBack) {
                  return;
                }
                setState(() => _canGoBack = canGoBack);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleWebView extends StatefulWidget {
  const _ScheduleWebView({
    super.key,
    required this.url,
    required this.onGoBackReady,
    required this.onCanGoBackChanged,
  });

  final String url;
  final ValueChanged<Future<void> Function()> onGoBackReady;
  final ValueChanged<bool> onCanGoBackChanged;

  @override
  State<_ScheduleWebView> createState() => _ScheduleWebViewState();
}

class _ScheduleWebViewState extends State<_ScheduleWebView> {
  InAppWebViewController? _controller;
  LinuxWebviewController? _linuxController;

  static final _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    forceDark: ForceDark.AUTO,
    useHybridComposition: true,
    algorithmicDarkeningAllowed: true,
    userAgent: BrowserUa.mob,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    disableVerticalScroll: false,
    disableHorizontalScroll: false,
    verticalScrollBarEnabled: true,
  );

  static final _gestureRecognizers = {
    const Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
  };

  @override
  void initState() {
    super.initState();
    widget.onGoBackReady(goBack);
  }

  Future<void> goBack() async {
    if (Platform.isLinux) {
      await _linuxController?.goBack();
      _notifyHistory();
      return;
    }
    if (await _controller?.canGoBack() == true) {
      await _controller?.goBack();
    }
  }

  Future<void> _notifyHistory() async {
    final current = Platform.isLinux
        ? (_linuxController?.currentUrl ?? widget.url)
        : (await _controller?.getUrl())?.toString() ?? widget.url;
    final leftInitialPage = !_samePage(current, widget.url);
    final hasHistory = Platform.isLinux
        ? leftInitialPage
        : leftInitialPage && await _controller?.canGoBack() == true;
    if (mounted) {
      widget.onCanGoBackChanged(hasHistory);
    }
  }

  static bool _samePage(String a, String b) {
    final ua = Uri.tryParse(a);
    final ub = Uri.tryParse(b);
    if (ua == null || ub == null) {
      return a.split('#').first == b.split('#').first;
    }
    return ua.host == ub.host && ua.path == ub.path;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux) {
      return LinuxWebview(
        initialUrl: widget.url,
        userAgent: BrowserUa.mob,
        onWebViewCreated: (controller) {
          _linuxController = controller;
        },
        onUrlChanged: (_) => _notifyHistory(),
      );
    }
    return InAppWebView(
      webViewEnvironment: webViewEnvironment,
      initialSettings: _settings,
      gestureRecognizers: _gestureRecognizers,
      initialUrlRequest: URLRequest(
        url: WebUri.uri(Uri.tryParse(widget.url) ?? Uri()),
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStop: (controller, _) => _notifyHistory(),
      onUpdateVisitedHistory: (controller, _, _) => _notifyHistory(),
    );
  }
}
