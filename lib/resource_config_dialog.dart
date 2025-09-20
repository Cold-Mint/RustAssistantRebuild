import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/databeans/resource_ref.dart';
import 'package:rust_assistant/highlight_text.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:rust_assistant/text_field_with_value.dart';

class ResourceConfigDialog extends StatefulWidget {
  final List<ResourceRef> globalResource;
  final Function(String) onRequestOpenFile;
  final List<ResourceRef> Function() getLocalResource;

  final String value;
  const ResourceConfigDialog({
    super.key,
    required this.getLocalResource,
    required this.globalResource,
    required this.value,
    required this.onRequestOpenFile,
  });

  @override
  State<StatefulWidget> createState() {
    return _ResourceConfigDialoglState();
  }
}

class _ResourceConfigDialoglState extends State<ResourceConfigDialog> {
  final List<_ResKeyValue> _allResKeyValue = [];
  final List<_ResKeyValue> _nonredundantResKeyValue = [];
  final StringBuffer _addition = StringBuffer();
  int _type = Constant.typeUsedRes;
  final TextEditingController _searchController = TextEditingController();
  final List<ResourceRef> _allResource = [];
  final List<ResourceRef> _nonredundantResource = [];
  @override
  void initState() {
    super.initState();
    _allResource.clear();
    _allResource.addAll(widget.getLocalResource());
    _allResource.addAll(widget.globalResource);
    _parseKeyvalue();
    _generateNonredundantResource();
  }

  void _generateNonredundantResource() {
    setState(() {
      _nonredundantResource.clear();
      _nonredundantResKeyValue.clear();
      for (final ref in _allResource) {
        if (_searchController.text.isNotEmpty) {
          bool matchKey = false;
          var name = ref.name;
          if (name != null) {
            var lowerCaseName = name.toLowerCase();
            if (lowerCaseName.contains(_searchController.text.toLowerCase())) {
              matchKey = true;
            }
          }
          var displayName = ref.displayName;
          if (!matchKey && displayName != null) {
            var lowerCaseDisplayName = displayName.toLowerCase();
            if (lowerCaseDisplayName.contains(
              _searchController.text.toLowerCase(),
            )) {
              matchKey = true;
            }
          }
          if (!matchKey) {
            continue;
          }
        }

        bool matched = false;
        for (var element in _allResKeyValue) {
          if (ref.name == element.key) {
            matched = true;
            break;
          }
        }
        if (!matched) {
          _nonredundantResource.add(ref);
        }
      }
      for (final ref in _allResKeyValue) {
        if (_searchController.text.isNotEmpty) {
          bool matchKey = false;
          var name = ref.key;
          if (name != null) {
            var lowerCaseName = name.toLowerCase();
            if (lowerCaseName.contains(_searchController.text.toLowerCase())) {
              matchKey = true;
            }
          }
          var displayName = ref.displayName;
          if (!matchKey && displayName != null) {
            var lowerCaseDisplayName = displayName.toLowerCase();
            if (lowerCaseDisplayName.contains(
              _searchController.text.toLowerCase(),
            )) {
              matchKey = true;
            }
          }
          if (!matchKey) {
            continue;
          }
        }
        _nonredundantResKeyValue.add(ref);
      }
    });
  }

  void _parseKeyvalue() {
    setState(() {
      _allResKeyValue.clear();
      _nonredundantResKeyValue.clear();
      _addition.clear();
    });
    final String str = widget.value;
    if (str.isEmpty) {
      return;
    }
    str.split(',').forEach((element) {
      var index = element.indexOf('=');
      if (index == -1) {
        if (_addition.isNotEmpty) {
          _addition.write(',');
        }
        _addition.write(element);
        return;
      }
      _allResKeyValue.add(
        _ResKeyValue()
          ..key = element.substring(0, index)
          ..value = element.substring(index + 1)
          ..displayName = _getHelpText(element.substring(0, index)),
      );
    });
    _nonredundantResKeyValue.addAll(_allResKeyValue);
  }

  String? _getHelpText(String? key) {
    if (key == null) {
      return null;
    }
    for (var element in _allResource) {
      if (element.name == key) {
        return element.displayName;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.resourceAllocation,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: <ButtonSegment<int>>[
                    ButtonSegment(
                      value: Constant.typeUsedRes,
                      label: Text(AppLocalizations.of(context)!.used),
                      icon: Icon(Icons.inbox_outlined),
                    ),
                    ButtonSegment(
                      value: Constant.typeAllRes,
                      label: Text(AppLocalizations.of(context)!.all),
                      icon: Icon(Icons.all_inbox_outlined),
                    ),
                  ],
                  selected: <int>{_type},
                  showSelectedIcon: false,
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _type = newSelection.first;
                      _searchController.text = "";
                      _generateNonredundantResource();
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _generateNonredundantResource();
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  )!.searchByTitleAndDescription,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),

            Expanded(
              child: _type == Constant.typeAllRes
                  ? Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_nonredundantResource.isEmpty &&
                            _searchController.text.isEmpty)
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.thereAreNoAvailableCustomResources,
                          ),
                        if (_nonredundantResource.isEmpty &&
                            _searchController.text.isNotEmpty)
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.customResourcesCannotBeFound,
                          ),
                        if (_nonredundantResource.isNotEmpty)
                          Expanded(
                            child: ListView.builder(
                              itemCount: _nonredundantResource.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        children: [
                                          if (_nonredundantResource[index]
                                              .globalResource)
                                            Chip(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              labelPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 0,
                                                  ),
                                              label: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.global,
                                              ),
                                            ),
                                          HighlightText(
                                            text:
                                                _nonredundantResource[index]
                                                    .name ??
                                                AppLocalizations.of(
                                                  context,
                                                )!.none,
                                            searchKeyword:
                                                _searchController.text,
                                            softWrap: true, // 允许换行
                                            overflow: TextOverflow.visible,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  subtitle:
                                      _nonredundantResource[index]
                                              .displayName ==
                                          null
                                      ? null
                                      : HighlightText(
                                          text: _nonredundantResource[index]
                                              .displayName!,
                                          searchKeyword: _searchController.text,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                  trailing: Wrap(
                                    children: [
                                      IconButton(
                                        tooltip: AppLocalizations.of(
                                          context,
                                        )!.add,
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          setState(() {
                                            _allResKeyValue.add(
                                              _ResKeyValue()
                                                ..key =
                                                    _nonredundantResource[index]
                                                        .name
                                                ..value = "1"
                                                ..displayName =
                                                    _nonredundantResource[index]
                                                        .displayName,
                                            );
                                          });
                                          _generateNonredundantResource();
                                        },
                                      ),
                                      IconButton(
                                        tooltip: AppLocalizations.of(
                                          context,
                                        )!.openAnExistingFile,
                                        icon: const Icon(
                                          Icons.open_in_new_outlined,
                                        ),
                                        onPressed: () {
                                          var path =
                                              _nonredundantResource[index].path;
                                          if (path == null) {
                                            return;
                                          }
                                          widget.onRequestOpenFile.call(path);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_nonredundantResKeyValue.isEmpty)
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.customResourceHaveNotBeenUsedYet,
                          ),
                        if (_nonredundantResKeyValue.isEmpty)
                          SizedBox(height: 8),
                        if (_nonredundantResKeyValue.isEmpty)
                          TextButton(
                            child: Text(
                              AppLocalizations.of(context)!.viewAllResources,
                            ),
                            onPressed: () {
                              _type = Constant.typeAllRes;
                              _searchController.text = "";
                              _generateNonredundantResource();
                            },
                          ),
                        if (_nonredundantResKeyValue.isNotEmpty)
                          Expanded(
                            child: ListView.builder(
                              itemCount: _nonredundantResKeyValue.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: TextFieldWithValue(
                                    value:
                                        _nonredundantResKeyValue[index].value ??
                                        "",
                                    onValueChange: (String newValue) {
                                      _nonredundantResKeyValue[index].value =
                                          newValue;
                                    },
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          signed: true,
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^[+-]?\d*\.?\d*'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText:
                                          _nonredundantResKeyValue[index].key ??
                                          AppLocalizations.of(context)!.none,
                                      helperText:
                                          _nonredundantResKeyValue[index]
                                              .displayName,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      setState(() {
                                        var obj =
                                            _nonredundantResKeyValue[index];
                                        _nonredundantResKeyValue.remove(obj);
                                        _allResKeyValue.remove(obj);
                                      });
                                      _generateNonredundantResource();
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
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
                  onPressed: () {
                    final StringBuffer stringBuffer = StringBuffer();
                    stringBuffer.write(_addition.toString());
                    for (var element in _allResKeyValue) {
                      if (stringBuffer.length > 0) {
                        stringBuffer.write(',');
                      }
                      stringBuffer.write(element.key);
                      stringBuffer.write('=');
                      stringBuffer.write(element.value);
                    }
                    Navigator.of(context).pop(stringBuffer.toString());
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResKeyValue {
  String? key;
  String? value;
  String? displayName;
}
