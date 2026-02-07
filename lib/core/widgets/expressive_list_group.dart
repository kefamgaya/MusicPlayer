import 'package:flutter/material.dart';

class ExpressiveListGroupScope extends InheritedWidget {
  const ExpressiveListGroupScope({super.key, required super.child});

  static ExpressiveListGroupScope? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ExpressiveListGroupScope>();
  }

  @override
  bool updateShouldNotify(ExpressiveListGroupScope oldWidget) => false;
}

class ExpressiveListGroup extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final Widget? header;

  const ExpressiveListGroup({
    super.key,
    required this.children,
    this.title,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF10B981);
    final backgroundColor = Colors.white.withValues(alpha: 0.05);

    Widget? headerWidget = header;

    if (headerWidget == null && title != null) {
      headerWidget = Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
        child: Text(
          title!,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (headerWidget != null) headerWidget,

        ExpressiveListGroupScope(
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                left: BorderSide(color: primary.withValues(alpha: 0.6), width: 2),
                top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                right: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(children: _buildChildrenWithDividers(context)),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final List<Widget> items = [];

    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);

      // Add Divider if not the last item
      if (i < children.length - 1) {
        items.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 76,
            endIndent: 16,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        );
      }
    }
    return items;
  }
}
