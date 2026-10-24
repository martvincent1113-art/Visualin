import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_preferences.dart';
import '../theme/visualin_tokens.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScreen(
      tabIndex: 0,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VisualinSpacing.screen,
            18,
            VisualinSpacing.screen,
            32,
          ),
          children: [
            _VisualinWordmark(label: l10n.appName),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                l10n.homePrompt,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            const SizedBox(height: 28),
            _FeatureCard(
              icon: Icons.sign_language_outlined,
              title: l10n.fslToText,
              body: l10n.fslToTextBody,
              onTap: () => Navigator.pushNamed(context, '/camera'),
            ),
            const SizedBox(height: VisualinSpacing.cardGap),
            _FeatureCard(
              icon: Icons.keyboard_alt_outlined,
              title: l10n.textToFsl,
              body: l10n.textToFslBody,
              onTap: () => Navigator.pushNamed(context, '/text-to-fsl'),
            ),
            const SizedBox(height: VisualinSpacing.section),
            SectionHeader(label: l10n.recentTranslations),
            const SizedBox(height: 14),
            EmptyState(
              icon: Icons.history_outlined,
              title: l10n.noTranslations,
              description: l10n.noTranslationsBody,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualinWordmark extends StatelessWidget {
  const _VisualinWordmark({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleMedium;
    final split = label.length >= 2 ? label.length - 2 : label.length;
    return Semantics(
      label: label,
      header: true,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: label.substring(0, split), style: baseStyle),
            TextSpan(
              text: label.substring(split),
              style: baseStyle?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      child: Row(
        children: [
          VisualinIconTile(icon: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const ExcludeSemantics(
            child: Icon(
              Icons.chevron_right,
              size: 26,
              color: VisualinColors.tertiaryText,
            ),
          ),
        ],
      ),
    );
  }
}
