import 'package:flutter/material.dart';
import 'package:rust_assistant/highlight_link_text.dart';
import 'package:rust_assistant/highlight_text.dart';
import 'package:sprintf/sprintf.dart';

import 'code_detail_dialog.dart';
import 'l10n/app_localizations.dart';

class SearchMultipleSelectionDialog extends StatefulWidget {
  final DataSource dataSource;
  final void Function(List selected) onSelected;

  const SearchMultipleSelectionDialog({
    super.key,
    required this.dataSource,
    required this.onSelected,
  });

  @override
  State<StatefulWidget> createState() {
    return _SearchMultipleSelectionStatus();
  }
}

class _SearchMultipleSelectionStatus
    extends State<SearchMultipleSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";
  bool _hideExisting = true;
  final List _selectedItems = List.empty(growable: true);
  List _filteredList = List.empty();

  @override
  void initState() {
    super.initState();
    _filteredList = widget.dataSource.generateFilteredList(
      _searchKeyword,
      _hideExisting,
    );

    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.toLowerCase();
        _filteredList = widget.dataSource.generateFilteredList(
          _searchKeyword,
          _hideExisting,
        );
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(dynamic item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.dataSource.dialogTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.dataSource.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedItems.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 72),
                child: SingleChildScrollView(
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _selectedItems.map((item) {
                            return Chip(
                              label: Text(widget.dataSource.getTitle(item)),
                              onDeleted: () => _toggleSelection(item),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.dataSource.existedList.isNotEmpty)
              SwitchListTile(
                dense: true,
                title: Text(AppLocalizations.of(context)!.hideExistingItems),
                value: _hideExisting,
                onChanged: (val) {
                  setState(() {
                    _hideExisting = val;
                    _filteredList = widget.dataSource.generateFilteredList(
                      _searchKeyword,
                      _hideExisting,
                    );
                  });
                },
              ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredList.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.allAvailableCodesHaveBeenAdded,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredList.length,
                      itemBuilder: (context, index) {
                        final object = _filteredList[index];
                        final isSelected = _selectedItems.contains(object);
                        var subTitle = widget.dataSource.getSubTitle(object);
                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(object),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: HighlightText(
                            text: widget.dataSource.getTitle(object),
                            searchKeyword: _searchKeyword,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: subTitle == null
                              ? null
                              : HighlightLinkText(
                                  text: subTitle,
                                  searchKeyword: _searchKeyword,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  onSeeTap: (String code, String section) {
                                    showDialog(
                                      context: context,
                                      builder: (_) => CodeDetailDialog(
                                        code: code,
                                        section: section,
                                        searchKeyword: "",
                                      ),
                                    );
                                  },
                                ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: _selectedItems.isEmpty
                      ? null
                      : () {
                          widget.onSelected.call(_selectedItems);
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    sprintf(widget.dataSource.confirmButtonText, [
                      _selectedItems.length,
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

abstract class DataSource<T> {
  List<T> allList = List.empty(growable: true);
  List<T> existedList = List.empty(growable: true);

  final String dialogTitle;
  final String searchHint;
  final String confirmButtonText;

  DataSource(this.dialogTitle, this.searchHint, this.confirmButtonText);

  List<T> generateFilteredList(String keyword, bool hideExisting);

  String getTitle(T item);

  String? getSubTitle(T item);
}
