import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ScrollableTabBarWithMouseWheel extends StatelessWidget {
  final TabBar tabBar;

  const ScrollableTabBarWithMouseWheel({super.key, required this.tabBar});

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final newOffset = controller.offset + event.scrollDelta.dy * 2.5;
          controller.animateTo(
            newOffset.clamp(
              controller.position.minScrollExtent,
              controller.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
          );
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: tabBar,
            ),
          );
        },
      ),
    );
  }
}
