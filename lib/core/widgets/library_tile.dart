import 'package:flutter/material.dart';

class LibraryTile extends StatelessWidget {
  const LibraryTile({
    this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget? title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final void Function()? onTap;
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF10B981);

    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: primary.withValues(alpha: 0.5), width: 2),
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        child: title!,
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontWeight: FontWeight.w600,
                            ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
