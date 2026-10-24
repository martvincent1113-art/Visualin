import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/visualin_tokens.dart';
import '../widgets/app_scaffold.dart';

enum ComingSoonFeature { textToFsl, history }

/// Keeps the existing route contract while giving both unfinished features a
/// complete, honest UI. No sign content or translation result is fabricated.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.feature});

  final ComingSoonFeature feature;

  @override
  Widget build(BuildContext context) {
    return feature == ComingSoonFeature.textToFsl
        ? const _TextToFslScreen()
        : const _HistoryScreen();
  }
}

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScreen(
      tabIndex: 2,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VisualinSpacing.screen,
            18,
            VisualinSpacing.screen,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: l10n.history),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: EmptyState(
                      icon: Icons.history_outlined,
                      title: l10n.noTranslations,
                      description: l10n.historyEmptyBody,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextToFslScreen extends StatefulWidget {
  const _TextToFslScreen();

  @override
  State<_TextToFslScreen> createState() => _TextToFslScreenState();
}

class _TextToFslScreenState extends State<_TextToFslScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _showUnavailable = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() => _showUnavailable = false);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSubmit = _controller.text.trim().isNotEmpty;
    return AppScreen(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(l10n.textToFsl),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            VisualinSpacing.screen,
            16,
            VisualinSpacing.screen,
            32,
          ),
          children: [
            SectionHeader(label: l10n.enterText),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 7,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.textInputHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: canSubmit
                  ? () {
                      FocusScope.of(context).unfocus();
                      setState(() => _showUnavailable = true);
                    }
                  : null,
              icon: const Icon(Icons.sign_language_outlined),
              label: Text(l10n.viewSigns),
            ),
            if (_showUnavailable) ...[
              const SizedBox(height: VisualinSpacing.section),
              SectionCard(
                child: Column(
                  children: [
                    const VisualinIconTile(
                      icon: Icons.sign_language_outlined,
                      size: 52,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.textToFslUnavailable,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
