class LiveRoomScheduleTab {
  final String title;
  final String url;
  final bool isSchedule;

  const LiveRoomScheduleTab({
    required this.title,
    required this.url,
    this.isSchedule = false,
  });

  static List<LiveRoomScheduleTab> fromRoomData(Map<String, dynamic>? data) {
    if (data == null) {
      return const [];
    }
    final outer = data['new_tab_info']?['outer_list'];
    if (outer is! List) {
      return const [];
    }

    final tabs = <LiveRoomScheduleTab>[];
    for (final raw in outer) {
      if (raw is! Map) {
        continue;
      }
      final title = raw['title'] as String? ?? '';
      var url = raw['jump_url'] as String? ?? '';
      if (title.isEmpty || url.isEmpty) {
        continue;
      }
      if (url.startsWith('//')) {
        url = 'https:$url';
      } else if (url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }

      final tab = raw['tab'];
      final bizType = tab is Map ? tab['biz_type'] as String? ?? '' : '';
      final aggregation = tab is Map ? tab['aggregation'] : 0;
      final isSchedule = title.contains('赛程') || bizType == 'schedule';
      if (isSchedule || aggregation == 1) {
        tabs.add(
          LiveRoomScheduleTab(
            title: title,
            url: url,
            isSchedule: isSchedule,
          ),
        );
      }
    }

    if (!tabs.any((e) => e.isSchedule)) {
      return const [];
    }
    return tabs;
  }
}
