import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart'; // xml: ^6.3.0

typedef OnSeeTap = void Function(String code, String section);

class HighlightLinkText extends StatelessWidget {
  final String text;
  final String searchKeyword;
  final OnSeeTap? onSeeTap;
  final TextStyle? style; // 允许外部覆盖

  const HighlightLinkText({
    super.key,
    required this.text,
    this.searchKeyword = '',
    this.onSeeTap,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _parse(context);
    return RichText(
      text: TextSpan(
        style: style ?? Theme.of(context).textTheme.bodyMedium,
        children: spans,
      ),
    );
  }

  /* ---------------- 解析 ---------------- */
  List<InlineSpan> _parse(BuildContext context) {
    final result = <InlineSpan>[];
    final regex = RegExp(r'<see\s+[^>]*\/>');
    int last = 0;

    for (final m in regex.allMatches(text)) {
      // 普通文本
      if (m.start > last) {
        result.add(_highlightLeaf(text.substring(last, m.start), context));
      }

      // <see .../> 超链接
      final attr = _readAttributes(m.group(0)!);
      final code = attr['code'] ?? '';
      final section = attr['section'] ?? '';
      result.add(
        TextSpan(
          text: code,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onSeeTap?.call(code, section),
        ),
      );

      last = m.end;
    }

    // 剩余
    if (last < text.length) {
      result.add(_highlightLeaf(text.substring(last), context));
    }
    return result;
  }

  /* ---------------- 高亮叶子节点 ---------------- */
  InlineSpan _highlightLeaf(String leaf, BuildContext context) {
    if (searchKeyword.isEmpty) return TextSpan(text: leaf);

    final keyword = searchKeyword.toLowerCase();
    final lower = leaf.toLowerCase();
    final idx = lower.indexOf(keyword);

    if (idx == -1) return TextSpan(text: leaf);

    return TextSpan(
      children: [
        TextSpan(text: leaf.substring(0, idx)),
        TextSpan(
          text: leaf.substring(idx, idx + keyword.length),
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        TextSpan(text: leaf.substring(idx + keyword.length)),
      ],
    );
  }

  /* ---------------- 读取属性 ---------------- */
  Map<String, String> _readAttributes(String tag) {
    try {
      final doc = XmlDocument.parse('<root>$tag</root>');
      final see = doc.rootElement.firstChild as XmlElement;
      return {for (final a in see.attributes) a.name.local: a.value};
    } catch (_) {
      return {};
    }
  }
}
