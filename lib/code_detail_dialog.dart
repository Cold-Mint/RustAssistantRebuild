import 'package:flutter/material.dart';

import 'code_data_base.dart';
import 'highlight_link_text.dart';
import 'l10n/app_localizations.dart';

/// 可复用的详情弹窗，支持内部 <see> 跳转
class CodeDetailDialog extends StatefulWidget {
  final String code;
  final String section;
  final String searchKeyword;

  const CodeDetailDialog({
    super.key,
    required this.code,
    required this.section,
    this.searchKeyword = '',
  });

  @override
  State<CodeDetailDialog> createState() => _CodeDetailDialogState();
}

class _CodeDetailDialogState extends State<CodeDetailDialog> {
  late String _currentCode;
  late String _currentSection;

  @override
  void initState() {
    super.initState();
    _currentCode = widget.code;
    _currentSection = widget.section;
  }

  /* ---------- 内部再次点击 <see> 时直接刷新当前弹窗 ---------- */
  void _onInnerSeeTap(String code, String section) {
    setState(() {
      _currentCode = code;
      _currentSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final codeInfo = CodeDataBase.getCodeInfo(_currentCode, _currentSection);
    final codeObj = CodeDataBase.getCode(_currentCode, _currentSection);

    return AlertDialog(
      title: Text(codeObj?.defaultKey ?? ''),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              codeInfo?.translate ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            HighlightLinkText(
              text: codeInfo?.description ?? '',
              searchKeyword: widget.searchKeyword,
              style: Theme.of(context).textTheme.bodyMedium,
              onSeeTap: _onInnerSeeTap, // 内部跳转
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.confirm),
        ),
      ],
    );
  }
}
