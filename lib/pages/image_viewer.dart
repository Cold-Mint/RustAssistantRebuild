import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rust_assistant/global_depend.dart';

class ImageViewer extends StatefulWidget {
  final String path;

  const ImageViewer({super.key, required this.path});

  @override
  State<StatefulWidget> createState() {
    return _ImageViewStatus();
  }
}

class _ImageViewStatus extends State<ImageViewer> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  void _loadBytes() async {
    setState(() {
      _loading = true;
    });
    _bytes = await GlobalDepend.getFileSystemOperator().readAsBytes(
      widget.path,
    );
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_bytes == null) {
      return InteractiveViewer(child: Icon(Icons.image_not_supported_outlined));
    } else {
      return InteractiveViewer(child: Image.memory(_bytes!));
    }
  }
}
