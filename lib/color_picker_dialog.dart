
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const ColorPickerDialog({super.key, required this.initialColor});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _tempColor;

  @override
  void initState() {
    super.initState();
    _tempColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectColor),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _tempColor,
          onColorChanged: (c) => setState(() => _tempColor = c),
          enableAlpha: false,
          displayThumbColor: true,
          paletteType: PaletteType.hsvWithHue,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _tempColor),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}