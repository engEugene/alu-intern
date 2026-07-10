import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF10263E);
  static const Color primaryLight = Color(0xFF1A3A5C);
  static const Color accent = Color(0xFF18D26E);
  static const Color accentDark = Color(0xFF12A557);

  static const Color accentGlow = Color(0x2918D26E);
  static const Color accentLight = Color(0x1A18D26E);
  static const Color accentSubtle = Color(0x0D18D26E);
  static const Color accentMuted = Color(0x4018D26E);

  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF18D26E);
  static const Color info = Color(0xFF3B82F6);

  static Color get background => const Color(0xFF070C09);
  static Color get surface => const Color(0xFF0D1511);
  static Color get card => const Color(0xFF151E19);
  static Color get divider => const Color(0xFF1E2B23);

  static Color get textPrimary => Colors.white;
  static Color get textSecondary => const Color(0xB3FFFFFF);
  static Color get textTertiary => const Color(0x80FFFFFF);
  static Color get textMuted => const Color(0x4DFFFFFF);

  static Color get inputFill => const Color(0xFF0E1A14);
  static Color get inputFillFocused => const Color(0xFF142218);
  static Color get popupSurface => const Color(0xFF0C1810);
  static Color get sheetSurface => const Color(0xFF081410);

  static Color get navSurface => const Color(0xD90A1510);

  static const Color purple = Color(0xFF8B5CF6);

  static Color get infoBg => const Color(0xFF0D1A1A);
  static Color get infoText => const Color(0xFF7CC4B8);

  static Color get warningBg => const Color(0xFF12191A);
  static Color get warningText => const Color(0xFFC4B078);

  static Color get successBg => const Color(0xFF071A0E);
  static Color get successText => const Color(0xFF4ADE80);

  static Color get pendingBg => const Color(0xFF1A1708);
  static Color get pendingText => const Color(0xFFB8A87B);

  static Color get failedBg => const Color(0xFF1A1015);
  static Color get failedText => const Color(0xFFBB8A95);

  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.25, 0.55, 0.85, 1.0],
    colors: [
      Color(0xFF0A1A12),
      Color(0xFF08120E),
      Color(0xFF070C09),
      Color(0xFF070C09),
      Color(0xFF08140E),
    ],
  );

  static LinearGradient get heroGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0E2A1A),
      Color(0xFF0A1510),
      Color(0xFF080F14),
    ],
  );

  static LinearGradient gradientAccent({bool vertical = false}) {
    return LinearGradient(
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: const [accent, Color(0xFF10B981)],
    );
  }

  static List<BoxShadow> accentGlowShadow({double blur = 20, double spread = -4}) {
    return [
      BoxShadow(
        color: accentGlow,
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withAlpha(40),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static (Color bg, Color text) statusColors(String status) {
    return switch (status) {
      'success' || 'completed' || 'paid' || 'active' || 'settled' || 'accepted' => (
          successBg,
          successText,
        ),
      'pending' || 'processing' || 'interview' => (
          pendingBg,
          pendingText,
        ),
      'failed' || 'cancelled' || 'overdue' || 'disabled' || 'rejected' => (
          failedBg,
          failedText,
        ),
      'inactive' => (
          pendingBg,
          pendingText,
        ),
      _ => (
          primary.withAlpha(50),
          textSecondary,
        ),
    };
  }
}
