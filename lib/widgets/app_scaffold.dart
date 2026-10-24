import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/visualin_tokens.dart';

class VisualinBottomNav extends StatelessWidget {
  const VisualinBottomNav({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scaledLabelHeight = MediaQuery.textScalerOf(context).scale(12) * 1.2;
    final barContentHeight = (42 + scaledLabelHeight).clamp(58.0, 74.0);
    final labels = <String>[
      l10n.home,
      l10n.cameraTab,
      l10n.history,
      l10n.settings,
    ];
    final icons = <IconData>[
      Icons.home_outlined,
      Icons.camera_alt_outlined,
      Icons.history_outlined,
      Icons.settings_outlined,
    ];
    final routes = <String>['/home', '/camera', '/history', '/profile'];

    void navigate(int destination) {
      if (destination == index) return;
      if (routes[destination] != ModalRoute.of(context)?.settings.name) {
        Navigator.pushReplacementNamed(context, routes[destination]);
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: VisualinColors.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 6),
        child: SizedBox(
          height: barContentHeight,
          child: Row(
            children: List<Widget>.generate(4, (destination) {
              final isSelected = destination == index;
              final color = isSelected
                  ? Theme.of(context).colorScheme.primary
                  : VisualinColors.secondaryText;
              final icon = icons[destination];
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: labels[destination],
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => navigate(destination),
                    customBorder: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? VisualinColors.orangeTintSoft
                                : Colors.transparent,
                            borderRadius: VisualinRadii.iconBackground,
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          labels[destination],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
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

/// Shared light-screen scaffold. It keeps system chrome legible and gives all
/// primary destinations the same background and bottom navigation treatment.
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.body,
    this.tabIndex,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final int? tabIndex;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final navigationBarColor = tabIndex == null
        ? Theme.of(context).scaffoldBackgroundColor
        : VisualinColors.surface;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: navigationBarColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: appBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: body,
        bottomNavigationBar:
            tabIndex == null ? null : VisualinBottomNav(index: tabIndex!),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.displaySmall,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label, this.uppercase = false});

  final String label;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        uppercase ? label.toUpperCase() : label,
        style: uppercase
            ? Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: VisualinColors.secondaryText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                )
            : Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class VisualinIconTile extends StatelessWidget {
  const VisualinIconTile({
    super.key,
    required this.icon,
    this.size = 48,
    this.iconSize = 25,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: VisualinColors.orangeTint,
        borderRadius: VisualinRadii.iconBackground,
      ),
      child: ExcludeSemantics(
        child: Icon(
          icon,
          size: iconSize,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.symmetric(
        horizontal: VisualinSpacing.card,
        vertical: compact ? 18 : 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VisualinIconTile(icon: icon, size: compact ? 44 : 52),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(VisualinSpacing.card),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final card = Ink(
      decoration: BoxDecoration(
        color: VisualinColors.surface,
        borderRadius: VisualinRadii.card,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(padding: padding, child: child),
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
