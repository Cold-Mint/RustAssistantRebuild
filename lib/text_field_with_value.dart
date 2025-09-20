import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldWithValue extends StatefulWidget {
  final String value;
  final Function(String) onValueChange;
  final TextInputType keyboardType;
  final InputDecoration? decoration;
  final List<TextInputFormatter>? inputFormatters;

  const TextFieldWithValue({
    super.key,
    required this.value,
    required this.onValueChange,
    required this.keyboardType,
    this.decoration,
    this.inputFormatters,
  });

  @override
  State<StatefulWidget> createState() {
    return _TextFieldWithValueState();
  }
}

class _TextFieldWithValueState extends State<TextFieldWithValue> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      decoration: widget.decoration,
      onChanged: widget.onValueChange,
    );
  }
}
