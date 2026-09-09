import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/visualin_tokens.dart';

class VisualinBottomNav extends StatelessWidget {
  const VisualinBottomNav({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <String>[l10n.home, l10n.fslToText, l10n.history, l10n.settings];
    final icons = <IconData>[
      Icons.home_outlined,
      Icons.camera_alt_outlined,
      Icons.history_outlined,
      Icons.settings_outlined,
    ];
    final routes = <String>['/home', '/camera', '/history', '/profile'];

    void navigate(int destination) {
      if (routes[destination] != ModalRoute.of(context)?.settings.name) {
        Navigator.pushReplacementNamed(context, routes[destination]);
      }
    }

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: VisualinColors.surface,
          border: Border(top: BorderSide(color: VisualinColors.divider)),
        ),
        child: SizedBox(
          height: 72,
          child: Row(
            children: List<Widget>.generate(4, (destination) {
              final isSelected = destination == index;
              final color = isSelected
                  ? VisualinColors.primaryOrange
                  : VisualinColors.inactive;
              final icon = icons[destination];
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: labels[destination],
                  excludeSemantics: true,
                    child: InkWell(
                    onTap: () => navigate(destination),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? VisualinColors.orangeTint
                                : Colors.transparent,
                            borderRadius: VisualinRadii.iconBackground,
                          ),
                          child: Icon(icon, color: color, size: 25),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[destination],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Ink(
      decoration: BoxDecoration(
        color: VisualinColors.surface,
        borderRadius: VisualinRadii.card,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: VisualinRadii.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: card),
      ),
    );
  }
}
