import 'package:flutter/material.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/databeans/unit_ref.dart';
import 'package:rust_assistant/highlight_text.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';

class UnitDialog extends StatefulWidget {
  final List<UnitRef> modUnit;
  final String value;
  final bool multiple;
  final Function(String) onSave;
  const UnitDialog({
    super.key,
    required this.modUnit,
    required this.value,
    required this.multiple,
    required this.onSave,
  });

  @override
  State<StatefulWidget> createState() {
    return _UnitDialogStatus();
  }
}

class _UnitDialogStatus extends State<UnitDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<UnitRefData> _allUnit = List.empty(growable: true);
  final List<UnitRefData> _filteredUnit = List.empty(growable: true);
  final Set<String> _unitList = {};
  @override
  void initState() {
    super.initState();
    var builtInUnit = CodeDataBase.builtInUnit;
    //添加内置单位
    for (UnitRef unitRef in builtInUnit) {
      var data = UnitRefData.fromUnitRef(unitRef);
      data.builtIn = true;
      _allUnit.add(data);
    }
    //添加模组单位
    for (UnitRef unitRef in widget.modUnit) {
      var data = UnitRefData.fromUnitRef(unitRef);
      data.builtIn = false;
      _allUnit.add(data);
    }
    _allUnit.sort((a, b) {
      final aName = a.name?.toLowerCase() ?? "";
      final bName = b.name?.toLowerCase() ?? "";
      return aName.compareTo(bName);
    });
    _filteredUnit.addAll(_allUnit);
    var unitList = widget.value.split(',');
    for (String unitName in unitList) {
      var unitNameTrim = unitName.trim();
      if (unitNameTrim.isNotEmpty && !_unitList.contains(unitNameTrim)) {
        _unitList.add(unitNameTrim);
      }
    }
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
                  AppLocalizations.of(context)!.unitSelector,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                var lowerCaseValue = value.toLowerCase();
                List<UnitRefData> newData = List.empty(growable: true);
                for (UnitRefData unitRef in _allUnit) {
                  var name = unitRef.name;
                  if (name == null) {
                    continue;
                  }
                  bool match = false;
                  if (name.toLowerCase().contains(lowerCaseValue)) {
                    match = true;
                  }
                  if (!match) {
                    var displayName = unitRef.displayName;
                    if (displayName == null) {
                      continue;
                    }
                    if (displayName.toLowerCase().contains(lowerCaseValue)) {
                      match = true;
                    }
                  }
                  if (match) {
                    newData.add(unitRef);
                  }
                }
                setState(() {
                  _filteredUnit.clear();
                  _filteredUnit.addAll(newData);
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(
                  context,
                )!.searchByTitleAndDescription,
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUnit.length,
                itemBuilder: (context, index) {
                  var unitData = _filteredUnit[index];
                  if (widget.multiple) {
                    return CheckboxListTile(
                      title: unitData.builtIn
                          ? Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    AppLocalizations.of(context)!.builtIn,
                                  ),
                                ),
                                HighlightText(
                                  text:
                                      unitData.name ??
                                      AppLocalizations.of(context)!.none,
                                  searchKeyword: _searchController.text,
                                ),
                              ],
                            )
                          : HighlightText(
                              text:
                                  unitData.name ??
                                  AppLocalizations.of(context)!.none,
                              searchKeyword: _searchController.text,
                            ),
                      subtitle: unitData.displayName == null
                          ? null
                          : HighlightText(
                              text: unitData.displayName!,
                              searchKeyword: _searchController.text,
                            ),
                      value: unitData.name == null
                          ? false
                          : _unitList.contains(unitData.name),
                      onChanged: (newValue) {
                        if (newValue == null) {
                          return;
                        }
                        setState(() {
                          if (newValue) {
                            _unitList.add(unitData.name!);
                          } else {
                            _unitList.remove(unitData.name!);
                          }
                        });
                      },
                    );
                  }
                  // 单选模式
                  return RadioListTile<String>(
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: unitData.builtIn
                        ? Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  AppLocalizations.of(context)!.builtIn,
                                ),
                              ),
                              HighlightText(
                                text:
                                    unitData.name ??
                                    AppLocalizations.of(context)!.none,
                                searchKeyword: _searchController.text,
                              ),
                            ],
                          )
                        : HighlightText(
                            text:
                                unitData.name ??
                                AppLocalizations.of(context)!.none,
                            searchKeyword: _searchController.text,
                          ),
                    subtitle: unitData.displayName == null
                        ? null
                        : HighlightText(
                            text: unitData.displayName!,
                            searchKeyword: _searchController.text,
                          ),
                    value: unitData.name ?? "",
                    groupValue: _unitList.isEmpty ? null : _unitList.first,
                    onChanged: (newValue) {
                      if (newValue == null) return;
                      setState(() {
                        _unitList
                          ..clear()
                          ..add(newValue);
                      });
                    },
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
                  onPressed: () {
                    final StringBuffer stringBuffer = StringBuffer();
                    for (String unitName in _unitList) {
                      if (stringBuffer.length > 0) {
                        stringBuffer.write(',');
                      }
                      stringBuffer.write(unitName);
                    }
                    widget.onSave.call(stringBuffer.toString());
                    Navigator.of(context).pop();
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

class UnitRefData extends UnitRef {
  bool builtIn = false;

  static UnitRefData fromUnitRef(UnitRef unitRef) {
    var result = UnitRefData();
    result.builtIn = false;
    result.description = unitRef.description;
    result.displayName = unitRef.displayName;
    result.name = unitRef.name;
    result.path = unitRef.path;
    return result;
  }
}
