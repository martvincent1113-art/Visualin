import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_preferences.dart';
import '../theme/visualin_tokens.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.preferences,
    required this.onLocaleChanged,
    required this.onHighContrastChanged,
    required this.onReducedMotionChanged,
    required this.textScale,
    required this.onTextScaleChanged,
  });

  final AppPreferences preferences;
  final Future<void> Function(Locale) onLocaleChanged;
  final Future<void> Function(bool) onHighContrastChanged;
  final Future<void> Function(bool) onReducedMotionChanged;
  final double textScale;
  final Future<void> Function(double) onTextScaleChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late bool _highContrast = widget.preferences.highContrast;
  late bool _reducedMotion = widget.preferences.reducedMotion;
  late double _textScale = widget.textScale;

  Future<void> _setHighContrast(bool value) async {
    setState(() => _highContrast = value);
    await widget.onHighContrastChanged(value);
  }

  Future<void> _setReducedMotion(bool value) async {
    setState(() => _reducedMotion = value);
    await widget.onReducedMotionChanged(value);
  }

  Future<void> _setTextScale(double value) async {
    setState(() => _textScale = value);
    await widget.onTextScaleChanged(value);
  }

  Future<void> _showTextSizeSheet() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: RadioGroup<double>(
            groupValue: _textScale,
            onChanged: (value) async {
              if (value == null) return;
              await _setTextScale(value);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.fontSize, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _TextSizeOption(label: l10n.smallText, value: 0.9),
                _TextSizeOption(label: l10n.defaultText, value: 1.0),
                _TextSizeOption(label: l10n.largeText, value: 1.2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUnavailableMessage() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsFeatureUnavailable)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(l10n.settings, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(l10n.settingsSubtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            _SectionLabel(label: l10n.language),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsTextRow(
                  title: l10n.signLanguageValue,
                  subtitle: l10n.signLanguageBody,
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.outputLanguage, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Semantics(
                        label: l10n.outputLanguage,
                        value: l10n.isEnglish ? l10n.english : l10n.filipino,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'fil',
                              label: Text(l10n.filipino),
                              icon: l10n.isEnglish ? null : const Icon(Icons.check),
                            ),
                            ButtonSegment(
                              value: 'en',
                              label: Text(l10n.english),
                              icon: l10n.isEnglish ? const Icon(Icons.check) : null,
                            ),
                          ],
                          selected: {l10n.isEnglish ? 'en' : 'fil'},
                          style: const ButtonStyle(
                            minimumSize: WidgetStatePropertyAll<Size>(
                              Size.fromHeight(44),
                            ),
                          ),
                          onSelectionChanged: (value) =>
                              widget.onLocaleChanged(Locale(value.first)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.outputLanguageBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SectionLabel(label: l10n.accessibility),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsActionRow(
                  icon: Icons.text_fields_outlined,
                  title: l10n.fontSize,
                  subtitle: l10n.textSizeDescription,
                  onTap: _showTextSizeSheet,
                ),
                const Divider(height: 1),
                _SettingsSwitchRow(
                  icon: Icons.contrast_outlined,
                  label: l10n.highContrast,
                  description: l10n.highContrastDescription,
                  value: _highContrast,
                  stateLabel: _highContrast ? l10n.on : l10n.off,
                  onChanged: _setHighContrast,
                ),
                const Divider(height: 1),
                _SettingsSwitchRow(
                  icon: Icons.motion_photos_off_outlined,
                  label: l10n.reducedMotion,
                  description: l10n.reducedMotionDescription,
                  value: _reducedMotion,
                  stateLabel: _reducedMotion ? l10n.on : l10n.off,
                  onChanged: _setReducedMotion,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SectionLabel(label: l10n.app),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsActionRow(
                  icon: Icons.camera_alt_outlined,
                  title: l10n.cameraPreferences,
                  subtitle: l10n.cameraPreferencesDescription,
                  onTap: _showUnavailableMessage,
                ),
                const Divider(height: 1),
                _SettingsActionRow(
                  icon: Icons.help_outline,
                  title: l10n.helpSupport,
                  subtitle: l10n.helpSupportDescription,
                  onTap: _showUnavailableMessage,
                ),
                const Divider(height: 1),
                _SettingsActionRow(
                  icon: Icons.info_outline,
                  title: l10n.about,
                  subtitle: l10n.aboutDescription,
                  onTap: _showUnavailableMessage,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const VisualinBottomNav(index: 3),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: VisualinColors.secondaryText,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
          ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VisualinColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: VisualinRadii.card,
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTextRow extends StatelessWidget {
  const _SettingsTextRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: VisualinColors.secondaryText),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: VisualinColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.stateLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final String stateLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: stateLabel,
      toggled: value,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minTileHeight: 68,
        secondary: Icon(icon, color: VisualinColors.secondaryText),
        title: Text(label, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(description, style: Theme.of(context).textTheme.bodyMedium),
        value: value,
        onChanged: onChanged,
        activeTrackColor: VisualinColors.primaryOrange,
        activeThumbColor: Colors.white,
        inactiveTrackColor: VisualinColors.inactive,
        inactiveThumbColor: Colors.white,
      ),
    );
  }
}

class _TextSizeOption extends StatelessWidget {
  const _TextSizeOption({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<double>(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeColor: VisualinColors.primaryOrange,
      title: Text(label),
    );
  }
}
