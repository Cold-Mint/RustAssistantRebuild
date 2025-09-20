import 'package:flutter/material.dart';

/// 仅负责把 [text] 中的 [searchKeyword] 高亮，
/// 没有任何链接/点击事件。
class HighlightText extends StatelessWidget {
  final String text;
  final String searchKeyword;
  final TextStyle? style;
  final bool softWrap;
  final TextOverflow overflow;

  const HighlightText({
    super.key,
    required this.text,
    this.searchKeyword = '',
    this.style,
    this.softWrap = false,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      softWrap: softWrap,
      overflow: overflow,
      text: TextSpan(
        style: style ?? Theme.of(context).textTheme.bodyMedium,
        children: _highlight(context),
      ),
    );
  }

/* ---------------- 高亮逻辑 ---------------- */
List<InlineSpan> _highlight(BuildContext context) {
  final keyword = searchKeyword.trim();
  if (keyword.isEmpty) return [TextSpan(text: text)];

  final lowerText = text.toLowerCase();
  final lowerKey = keyword.toLowerCase();
  final idx = lowerText.indexOf(lowerKey);

  if (idx == -1) return [TextSpan(text: text)];

  return [
    TextSpan(text: text.substring(0, idx)),
    TextSpan(
      text: text.substring(idx, idx + keyword.length),
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
    ),
    TextSpan(text: text.substring(idx + keyword.length)),
  ];
}
}
