import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/visualin_tokens.dart';
import '../widgets/app_scaffold.dart';

enum ComingSoonFeature { textToFsl, history }

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.feature});

  final ComingSoonFeature feature;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTextToFsl = feature == ComingSoonFeature.textToFsl;
    final title = isTextToFsl ? l10n.textToFsl : l10n.history;
    final message = isTextToFsl ? l10n.textToFslStub : l10n.historyStub;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isTextToFsl ? Icons.sign_language_outlined : Icons.history_outlined,
                size: 56,
                color: VisualinColors.primaryOrange,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          isTextToFsl ? null : const VisualinBottomNav(index: 2),
    );
  }
}
