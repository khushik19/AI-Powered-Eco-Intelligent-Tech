import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Spruce • Tulip • Ocean Palette
///
///  SPRUCE  #1B3907  deep forest green   (surfaces, eco-indicators, nature accents)
///  TULIP   #BC475F  rich berry rose     (CTAs, primary actions, hot highlights, glow)
///  OCEAN   #015F7E  deep cyan-teal blue (secondary accents, metrics, status, cool highlights)
/// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // ── Core Brand Palette ───────────────────────────────────────────────────────
  static const Color spruce       = Color(0xFF1B3907); // deep forest green
  static const Color tulip        = Color(0xFFBC475F); // rich berry rose
  static const Color ocean        = Color(0xFF015F7E); // deep cyan-teal blue

  // ── Supporting Tints & Accents ──────────────────────────────────────────────
  static const Color tulipLight   = Color(0xFFD96B81); // brighter tulip rose
  static const Color tulipSoft    = Color(0xFFF0A8B7); // soft blush tulip
  static const Color oceanLight   = Color(0xFF1882A8); // luminous ocean blue
  static const Color oceanSoft    = Color(0xFF70BDD6); // soft ice cyan
  static const Color spruceLight  = Color(0xFF326114); // mid forest spruce

  // ── Surfaces & Backgrounds ──────────────────────────────────────────────────
  static const Color abyss              = Color(0xFF000000); // true black canvas
  static const Color surfaceDark        = Color(0xFF0B1406); // deep spruce dark
  static const Color midnightBlack      = Color(0xFF071217); // deep ocean midnight
  static const Color background         = abyss;
  static const Color backgroundSecondary = surfaceDark;

  // ── Glass / Overlay ─────────────────────────────────────────────────────────
  static const Color glassWhite       = Color(0x0DFFFFFF); // ~5% white
  static const Color glassBorder      = Color(0x24FFFFFF); // ~14% white
  static const Color glassWhiteStrong = Color(0x1AFFFFFF); // ~10% white

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF8F6F2); // crisp warm white
  static const Color textSecondary = Color(0xFFE8B6C0); // soft tulip tint
  static const Color textMuted     = Color(0xFF7EADC0); // soft ocean muted

  // ── Semantic ────────────────────────────────────────────────────────────────
  static const Color success = spruceLight;
  static const Color warning = Color(0xFFE5983B);
  static const Color error   = tulip;
  static const Color info    = ocean;

  // ── Legacy Aliases ──────────────────────────────────────────────────────────
  static const Color charleston    = spruce;
  static const Color citron        = spruceLight;
  static const Color cerise        = tulip;
  static const Color deepBlush     = tulipLight;
  static const Color lightPink     = tulipSoft;
  static const Color bioTeal       = ocean;
  static const Color kelp          = spruce;
  static const Color electricCyan  = oceanLight;
  static const Color neonMoss      = spruceLight;
  static const Color mutedOlive    = spruce;
  static const Color softGrey      = oceanSoft;
  static const Color reefCoral     = tulip;
  static const Color seaFoam       = oceanSoft;
  static const Color forestGreen   = spruce;
  static const Color oliveGreen    = spruceLight;
  static const Color cream         = tulipSoft;
  static const Color dustyRose     = tulipLight;
  static const Color tealBlue      = ocean;
  static const Color cosmicPurple  = tulip;
  static const Color nebulaBlue    = ocean;
  static const Color stardustGold  = oceanLight;
  static const Color cosmicGreen   = spruceLight;
  static const Color deepViolet    = spruce;

  // ── Star field colors ───────────────────────────────────────────────────────
  static const List<Color> starColors = [
    Colors.white,
    Color(0xFFFFF2D4),
    Color(0xFFFDE8E8),
    oceanSoft,
  ];

  // ── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tulip, tulipLight],
  );

  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ocean, oceanLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF5376), // Neon Rose
      Color(0xFF9D65FF), // Radiant Violet
      Color(0xFF00D2FF), // Ice Cyan
    ],
  );

  static const LinearGradient cosmicTitleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF5376), // Vibrant Neon Rose
      Color(0xFFD63AF9), // Vivid Magenta Violet
      Color(0xFF7C4DFF), // Radiant Deep Violet
      Color(0xFF00D2FF), // Electric Ice Cyan
    ],
  );

  static const LinearGradient spruceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [spruce, spruceLight],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF000000), Color(0xFF0B1406), Color(0xFF071217)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient liquidMetallicGradient = backgroundGradient;
}
