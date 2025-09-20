import 'package:flutter/material.dart';

class ValueLogicalBooleanChildInterpreter extends StatefulWidget {
  const ValueLogicalBooleanChildInterpreter({
    super.key,
    required this.value,
    required this.displayValue,
  });

  final String value;
  final String displayValue;

  @override
  State<StatefulWidget> createState() {
    return _ValueLogicalBooleanChildInterpreterStatus();
  }
}

class _ValueLogicalBooleanChildInterpreterStatus
    extends State<ValueLogicalBooleanChildInterpreter> {
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 使用 Expanded 限制文字区域大小
          Flexible(
            child: Text(
              widget.displayValue,
              style: const TextStyle(fontFamily: 'Mono'),
              overflow: TextOverflow.ellipsis, // 超出显示省略号
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          // 操作按钮始终固定可见
          // Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     IconButton(
          //       onPressed: null,
          //       visualDensity: VisualDensity.compact,
          //       icon: const Icon(Icons.delete_outline),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
