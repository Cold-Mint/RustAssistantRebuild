import 'package:flutter/services.dart';

class SignedNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // 允许空输入
    if (text.isEmpty) {
      return newValue;
    }

    // 允许单个 "-"，或者 "-" 开头后跟数字
    final regExp = RegExp(r'^-?\d*$');
    if (regExp.hasMatch(text)) {
      return newValue;
    }

    // 否则不更新（保持旧值）
    return oldValue;
  }
}
