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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: VisualinColors.primaryOrange,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Text(l10n.homePrompt, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 28),
          _FeatureCard(
            primary: true,
            icon: Icons.sign_language_outlined,
            title: l10n.fslToText,
            body: l10n.fslToTextBody,
            onTap: () => Navigator.pushNamed(context, '/camera'),
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.keyboard_alt_outlined,
            title: l10n.textToFsl,
            body: l10n.textToFslBody,
            onTap: () => Navigator.pushNamed(context, '/text-to-fsl'),
          ),
          const SizedBox(height: 32),
          Text(l10n.recentTranslations,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: VisualinColors.orangeTint,
                    borderRadius: VisualinRadii.iconBackground,
                  ),
                  child: const Icon(
                    Icons.history_outlined,
                    color: VisualinColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noTranslations,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.noTranslationsBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const VisualinBottomNav(index: 0),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 96),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: VisualinColors.orangeTint,
                borderRadius: VisualinRadii.iconBackground,
              ),
              child: Icon(icon, color: VisualinColors.primaryOrange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 28,
              color: VisualinColors.secondaryText,
              semanticLabel: '',
            ),
          ],
        ),
      ),
    );
  }
}
