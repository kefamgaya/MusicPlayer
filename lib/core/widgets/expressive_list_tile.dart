import 'package:flutter/material.dart';
import 'package:gyawun/core/widgets/expressive_list_group.dart';

class ExpressiveListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool enableFeedback;
  final BorderRadiusGeometry? borderRadius;
  final Color? fillColor;

  const ExpressiveListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.enableFeedback = true,
    this.borderRadius,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF10B981);
    final theme = Theme.of(context);

    // Check if we are inside an ExpressiveListGroup
    final isInGroup = ExpressiveListGroupScope.of(context) != null;

    // Determine default values based on context (Standalone vs Grouped)
    final effectiveBorderRadius = borderRadius ?? BorderRadius.zero;

    final effectiveFillColor =
        fillColor ??
        (isInGroup ? Colors.transparent : Colors.white.withValues(alpha: 0.05));

    // Colors
    final selectedColor = primary.withValues(alpha: 0.2);
    final baseColor = selected ? selectedColor : effectiveFillColor;

    // Overlay colors for InkWell (M3 specs)
    final hoverColor = Colors.white.withValues(alpha: 0.05);
    final highlightColor = Colors.white.withValues(alpha: 0.1);
    final splashColor = Colors.white.withValues(alpha: 0.1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: effectiveBorderRadius,
        border: Border(
          left: BorderSide(color: selected ? primary : primary.withValues(alpha: 0.45), width: 2),
          top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveBorderRadius.resolve(
            Directionality.of(context),
          ),
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          enableFeedback: enableFeedback,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Leading
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.8),
                      size: 24,
                    ),
                    child: leading!,
                  ),
                  const SizedBox(width: 16),
                ],

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: selected
                              ? Colors.white
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        DefaultTextStyle(
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: selected
                                ? primary
                                : Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  IconTheme(
                    data: IconThemeData(
                      color: primary,
                      size: 24,
                    ),
                    child: trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
