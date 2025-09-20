import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class TextDifference extends StatefulWidget {
  final String original;
  final String newText;

  const TextDifference({
    super.key,
    required this.original,
    required this.newText,
  });

  @override
  State<StatefulWidget> createState() {
    return _TextDifferenceStatus();
  }
}

enum DiffMode { diff, memory, file }

class _TextDifferenceStatus extends State<TextDifference> {
  DiffMode _mode = DiffMode.diff;
  bool _showEscapeChars = false;

  List<InlineSpan> _buildPlainText(String text) {
    return text.runes.map((rune) {
      final char = String.fromCharCode(rune);
      final isEscape = _showEscapeChars && _isEscapeChar(char);
      final visualChar = _showEscapeChars ? _escapeCharToSymbol(char) : char;

      return TextSpan(
        text: visualChar,
        style: TextStyle(
          backgroundColor: isEscape
              ? Colors.purple.withAlpha((0.3 * 255).round())
              : null,
        ),
      );
    }).toList();
  }

  List<InlineSpan> _buildDiffText() {
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(widget.original, widget.newText);

    return diffs.expand((diff) {
      final List<InlineSpan> spans = [];

      for (final rune in diff.text.runes) {
        final char = String.fromCharCode(rune);
        final isEscape = _showEscapeChars && _isEscapeChar(char);
        final visualChar = _showEscapeChars ? _escapeCharToSymbol(char) : char;

        spans.add(
          TextSpan(
            text: visualChar,
            style: TextStyle(
              backgroundColor: isEscape
                  ? Colors.purple.withAlpha((0.3 * 255).round())
                  : (diff.operation == DIFF_INSERT
                        ? Colors.green.withAlpha((0.3 * 255).round())
                        : diff.operation == DIFF_DELETE
                        ? Colors.red.withAlpha((0.3 * 255).round())
                        : null),
              color: diff.operation == DIFF_DELETE && !isEscape
                  ? Colors.red
                  : null,
              decoration: diff.operation == DIFF_DELETE && !isEscape
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        );
      }

      return spans;
    }).toList();
  }

  bool _isEscapeChar(String char) {
    return ['\n', '\r', '\t'].contains(char);
  }

  String _escapeCharToSymbol(String char) {
    switch (char) {
      case '\n':
        return r'\n';
      case '\r':
        return r'\r';
      case '\t':
        return r'\t';
      default:
        return char;
    }
  }

  Widget _buildContent() {
    switch (_mode) {
      case DiffMode.diff:
        return RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(fontFamily: 'Mono'),
            children: _buildDiffText(),
          ),
        );
      case DiffMode.memory:
        return RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(fontFamily: 'Mono'),
            children: _buildPlainText(widget.newText),
          ),
        );
      case DiffMode.file:
        return RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(fontFamily: 'Mono'),
            children: _buildPlainText(widget.original),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部模式选择
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<DiffMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: DiffMode.diff,
                label: Text(AppLocalizations.of(context)!.difference),
                icon: const Icon(Icons.compare_arrows_outlined),
              ),
              ButtonSegment(
                value: DiffMode.memory,
                label: Text(AppLocalizations.of(context)!.memory),
                icon: Icon(Icons.memory_outlined),
              ),
              ButtonSegment(
                value: DiffMode.file,
                label: Text(AppLocalizations.of(context)!.file),
                icon: Icon(Icons.insert_drive_file_outlined),
              ),
            ],
            selected: <DiffMode>{_mode},
            onSelectionChanged: (newSelection) {
              setState(() {
                _mode = newSelection.first;
              });
            },
          ),
        ),

        // 转义字符显示开关
        Row(
          children: [
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.displayEscapeCharacters),
            const Spacer(),
            Switch(
              value: _showEscapeChars,
              onChanged: (val) {
                setState(() {
                  _showEscapeChars = val;
                });
              },
            ),
          ],
        ),

        if (_showEscapeChars)
          SizedBox(
            width: double.infinity,
            child: Card.outlined(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  AppLocalizations.of(context)!.escapeCharacterGuide,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // 内容区域
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(width: double.infinity, child: _buildContent()),
          ),
        ),
      ],
    );
  }
}
