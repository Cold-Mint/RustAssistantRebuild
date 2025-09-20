import 'package:flutter/material.dart';
import 'package:rust_assistant/databeans/visual_analytics_result.dart';
import 'package:rust_assistant/highlight_text.dart';
import 'package:sprintf/sprintf.dart';

import '../global_depend.dart';
import '../l10n/app_localizations.dart';

class AnalyticsDialog extends StatefulWidget {
  final VisualAnalyticsResult? result;
  final bool isRuning;
  final Function(String) onRequestOpenFile;
  final Function onCancelAnalytics;
  final Function onRescan;

  const AnalyticsDialog({
    super.key,
    required this.result,
    required this.isRuning,
    required this.onRequestOpenFile,
    required this.onCancelAnalytics,
    required this.onRescan,
  });

  @override
  State<StatefulWidget> createState() {
    return _AnalyticsDialogState();
  }
}

class _AnalyticsDialogState extends State<AnalyticsDialog>
    with TickerProviderStateMixin {
  TabController? _tabController;
  String _filterKeyword = '';

  @override
  void initState() {
    super.initState();
    _createTabController(widget.result?.items ?? []);
  }

  void _createTabController(
    List<VisualAnalyticsResultItem> visualAnalyticsResultItemList,
  ) {
    if (_tabController == null ||
        _tabController?.length != visualAnalyticsResultItemList.length) {
      _tabController?.dispose();
      _tabController = null;
      _tabController = TabController(
        length: visualAnalyticsResultItemList.length,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnalyticsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    var oldStartTime = oldWidget.result?.startTime;
    var newStartTime = widget.result?.startTime;
    if (oldStartTime != newStartTime) {
      _createTabController(widget.result?.items ?? []);
    }
  }

  Widget _getSearchTextField() {
    String? helper;

    final start = widget.result?.startTime;
    final end = widget.result?.endTime;

    if (start != null && end != null) {
      final duration = end.difference(start);
      String durationStr;

      if (duration.inHours >= 1) {
        durationStr = '${duration.inHours}h ${duration.inMinutes % 60}m';
      } else if (duration.inMinutes >= 1) {
        durationStr = '${duration.inMinutes}m ${duration.inSeconds % 60}s';
      } else if (duration.inMilliseconds >= 1000) {
        durationStr = '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
      } else {
        durationStr = '${duration.inMilliseconds}ms';
      }

      final formattedStart =
          '${start.year}-${start.month}-${start.day} ${start.hour}:${start.minute.toString().padLeft(2, '0')}';

      helper = sprintf(AppLocalizations.of(context)!.lastUpdateTime, [
        formattedStart,
        durationStr,
      ]);
    }

    return TextField(
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchByTitle,
        helperText: helper,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _filterKeyword = value;
        });
      },
    );
  }

  //生成过滤后的结果
  List<VisualAnalyticsResultItem> _filteredItems(
    List<VisualAnalyticsResultItem>? items,
  ) {
    if (items == null || items.isEmpty) {
      return [];
    }
    List<VisualAnalyticsResultItem> filteredItems =
        List<VisualAnalyticsResultItem>.empty(growable: true);
    var filterKeywordToLowerCase = _filterKeyword.toLowerCase();
    for (var element in items) {
      var resultList = element.result;
      if (resultList.isEmpty) {
        continue;
      }
      var filtered = resultList
          .where(
            (element) =>
                element.title?.toLowerCase().contains(
                  filterKeywordToLowerCase,
                ) ??
                false,
          )
          .toList();
      if (filtered.isEmpty) {
        continue;
      }
      VisualAnalyticsResultItem resultItem = VisualAnalyticsResultItem();
      resultItem.title = element.title;
      resultItem.result = filtered;
      filteredItems.add(resultItem);
    }
    return filteredItems;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.result?.items ?? [];
    // 提前过滤所有 tab 中的内容
    final filteredItems = _filteredItems(items);
    _createTabController(filteredItems);
    // 是否任意一个 tab 还有匹配结果
    final hasAnyResult = filteredItems.any((list) => list.result.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.globalSearch,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton(
                onPressed: widget.isRuning
                    ? null
                    : () {
                        widget.onRescan.call();
                      },
                child: Text(AppLocalizations.of(context)!.refresh),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- 分析器运行中 ---
          if (widget.isRuning) ...[
            Expanded(
              child: Center(
                //自适应高度
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.indexIsBeingUpdated),
                    TextButton(
                      onPressed: () {
                        widget.onCancelAnalytics.call();
                      },
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                  ],
                ),
              ),
            ),
          ]
          // --- 所有过滤结果为空 ---
          else if (!hasAnyResult) ...[
            if (_filterKeyword.isNotEmpty) _getSearchTextField(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const Icon(Icons.search_off_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noDataAvailableForSearch,
                    ),
                  ],
                ),
              ),
            ),
          ]
          // --- 正常渲染 ---
          else ...[
            _getSearchTextField(),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                for (var entry in filteredItems)
                  Tab(text: "${entry.title}(${entry.result.length})"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(filteredItems.length, (tabIndex) {
                  final filtered = filteredItems[tabIndex];
                  return ListView.builder(
                    key: PageStorageKey("tab_$tabIndex"),
                    itemCount: filtered.result.length,
                    itemBuilder: (context, index) {
                      final data = filtered.result[index];
                      final filePath = data.path;
                      return ListTile(
                        onTap: () {
                          final path = data.path;
                          if (path != null) {
                            widget.onRequestOpenFile.call(path);
                          }
                          Navigator.of(context).pop();
                        },
                        leading: filePath == null
                            ? null
                            : GlobalDepend.getFileIcon(
                                false,
                                filePath,
                                data.bytes,
                              ),
                        title: HighlightText(
                          text:
                              data.title ?? AppLocalizations.of(context)!.none,
                          searchKeyword: _filterKeyword,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: HighlightText(
                          text:
                              data.subTitle ??
                              AppLocalizations.of(context)!.none,
                          searchKeyword: _filterKeyword,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
