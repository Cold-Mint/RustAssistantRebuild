import 'package:flutter/material.dart';

class AddTag extends StatefulWidget {
  final List<String> tags;
  final void Function(String) onAdd;
  const AddTag({super.key, required this.tags, required this.onAdd});

  @override
  State<AddTag> createState() => _AddTagState();
}

class _AddTagState extends State<AddTag> {
  String _keyword = '';
  List<String> _filteredTags = [];

  void _searchTags(String query) {
    setState(() {
      _keyword = query;
      final keyword = _keyword.trim().toLowerCase();
      _filteredTags = keyword.isEmpty
          ? widget.tags
          : widget.tags
              .where((tag) => tag.toLowerCase().contains(keyword))
              .toList();
    });
  }

  void _addTag() {
    widget.onAdd(_keyword.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加标签')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchTags,
              decoration: const InputDecoration(hintText: '搜索标签'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTags.length,
              itemBuilder: (context, index) =>
                  ListTile(title: Text(_filteredTags[index])),
            ),
          ),
          ElevatedButton(
            onPressed: _addTag,
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
