import 'package:flutter/material.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/databeans/unit_ref.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';

class UnitDialog extends StatefulWidget {
  const UnitDialog({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UnitDialogStatus();
  }
}

class _UnitDialogStatus extends State<UnitDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<UnitRef> _builtInUnit = List.empty(growable: true);
  @override
  void initState() {
    super.initState();
    _builtInUnit.addAll(CodeDataBase.builtInUnit);
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
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _builtInUnit.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_builtInUnit[index].name ?? ""),
                    subtitle: Text(_builtInUnit[index].displayName ?? ""),
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
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
