import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_preferences.dart';
import '../theme/visualin_tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.preferences});
  final AppPreferences preferences;
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  Timer? _navigationTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = reducedMotion
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 600);
    _controller.forward();
    _navigationTimer = Timer(reducedMotion
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, widget.preferences.hasOnboarded ? '/home' : '/onboarding');
    });
  }

  @override
  void dispose() { _navigationTimer?.cancel(); _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Center(
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: reducedMotion ? Curves.linear : Curves.easeOutBack)),
          child: FadeTransition(
            opacity: _controller,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(
                'assets/images/visualin_logo.jpg',
                width: 176,
                height: 176,
                fit: BoxFit.cover,
                semanticLabel: l10n.appName,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.appName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: VisualinColors.primaryOrange,
                    ),
              ),
              const SizedBox(height: 8), Text(l10n.tagline, style: Theme.of(context).textTheme.bodyLarge),
            ]),
          ),
        ),
      ),
    );
  }
}
