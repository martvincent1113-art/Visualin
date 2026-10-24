import 'package:flutter/material.dart';

/// Shared visual tokens for the lightweight, native-feeling Visualin UI.
///
/// Keeping these values together prevents the orange accent and surface
/// treatment from drifting between features.
abstract final class VisualinColors {
  static const primaryOrange = Color(0xFFFF6B0A);
  static const orangeTint = Color(0xFFFFF0E8);
  static const orangeTintSoft = Color(0xFFFFF3EC);
  static const background = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const primaryText = Color(0xFF1C1C1E);
  static const secondaryText = Color(0xFF6E6E73);
  static const tertiaryText = Color(0xFF8E8E93);
  static const divider = Color(0xFFE5E5EA);
  static const border = Color(0xFFDADADF);
  static const inactive = Color(0xFFAEAEB2);
  static const highContrastOrange = Color(0xFFC94F00);
}

abstract final class VisualinRadii {
  static const card = BorderRadius.all(Radius.circular(22));
  static const control = BorderRadius.all(Radius.circular(16));
  static const iconBackground = BorderRadius.all(Radius.circular(14));
}

abstract final class VisualinSpacing {
  static const screen = 24.0;
  static const screenCompact = 20.0;
  static const section = 32.0;
  static const card = 20.0;
  static const cardGap = 16.0;
  static const minimumTapTarget = 44.0;
}
