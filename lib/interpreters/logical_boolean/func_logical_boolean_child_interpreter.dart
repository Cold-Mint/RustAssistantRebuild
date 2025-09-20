import 'package:flutter/material.dart';

import '../../databeans/logical_boolean.dart' hide Argument;
import '../../databeans/logical_boolean_translate.dart';
import '../../mod/func_parser.dart';

class FuncLogicalBooleanChildInterpreter extends StatefulWidget {
  const FuncLogicalBooleanChildInterpreter({
    super.key,
    required this.value,
    required this.logicalBoolean,
    this.logicalBooleanTranslate,
  });

  final String value;
  final LogicalBoolean logicalBoolean;
  final LogicalBooleanTranslate? logicalBooleanTranslate;

  @override
  State<StatefulWidget> createState() {
    return _FuncLogicalBooleanChildInterpreterStatus();
  }
}

class _FuncLogicalBooleanChildInterpreterStatus
    extends State<FuncLogicalBooleanChildInterpreter> {
  late FuncParser _funcParser;

  @override
  void initState() {
    super.initState();
    _funcParser = FuncParser(widget.value);
  }

  /// 获取参数的翻译
  String getArgumentKey(String argumentKey) {
    var logicalBooleanTranslate = widget.logicalBooleanTranslate;
    if (logicalBooleanTranslate == null ||
        logicalBooleanTranslate.argument == null) {
      return argumentKey;
    }
    for (Argument argument in logicalBooleanTranslate.argument!) {
      if (argument.name == argumentKey) {
        return argument.translate ?? argumentKey;
      }
    }
    return argumentKey;
  }

  @override
  void didUpdateWidget(covariant FuncLogicalBooleanChildInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _funcParser = FuncParser(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final args = _funcParser.getArguments();

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主体部分 - 左侧函数名 + 参数列表
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 函数名文本
                Text(
                  widget.logicalBooleanTranslate?.translate ??
                      _funcParser.getFuncName(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),

                // 参数列表 - 使用 Wrap 可自动换行，但限制空间
                Flexible(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: args.map((arg) {
                      final displayText = arg.value.isEmpty
                          ? getArgumentKey(arg.key)
                          : '${getArgumentKey(arg.key)}=${arg.value}';
                      return Chip(
                        label: Text(
                          displayText,
                          style: const TextStyle(
                            fontFamily: 'Mono',
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 操作按钮区域，固定不挤出
          // Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     IconButton(
          //       onPressed: null,
          //       visualDensity: VisualDensity.compact,
          //       icon: const Icon(Icons.add),
          //     ),
          //     IconButton(
          //       onPressed: null,
          //       visualDensity: VisualDensity.compact,
          //       icon: const Icon(Icons.edit_outlined),
          //     ),
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
