import 'package:flutter/material.dart';

class AppColors {
  // ── Bio-Luminescent Night Palette ─────────────────────────────────────────
  static const Color midnightBlack  = Color(0xFF05070D);  // deep background
  static const Color neonMoss       = Color(0xFF7CFFB2);  // primary accent (was oliveGreen)
  static const Color electricCyan   = Color(0xFF00E5FF);  // secondary accent (was tealBlue)
  static const Color mutedOlive     = Color(0xFF5A7D6A);  // muted green (was forestGreen)
  static const Color softGrey       = Color(0xFFCFCFCF);  // text / neutral (was cream)

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background          = Color(0xFF05070D);
  static const Color backgroundSecondary = Color(0xFF080C14);

  // ── Legacy aliases (keep so existing screens compile unchanged) ──────────
  static const Color forestGreen  = mutedOlive;
  static const Color oliveGreen   = neonMoss;
  static const Color cream        = softGrey;
  static const Color dustyRose    = Color(0xFF5A7D6A);   // mapped to mutedOlive
  static const Color tealBlue     = electricCyan;

  static const Color cosmicPurple  = electricCyan;
  static const Color nebulaBlue    = neonMoss;
  static const Color stardustGold  = neonMoss;           // stardust now glows neon moss
  static const Color cosmicGreen   = neonMoss;
  static const Color deepViolet    = mutedOlive;

  // ── Glass ─────────────────────────────────────────────────────────────────
  static const Color glassWhite       = Color(0x0DFFFFFF);
  static const Color glassBorder      = Color(0x26FFFFFF);
  static const Color glassWhiteStrong = Color(0x1AFFFFFF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFCFCFCF);   // softGrey
  static const Color textSecondary = Color(0xFF9ECFB8);   // mid tone between neonMoss & softGrey
  static const Color textMuted     = Color(0xFF5A7D6A);   // mutedOlive

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success = neonMoss;
  static const Color warning = Color(0xFF00E5FF);
  static const Color error   = Color(0xFFEF476F);

  // ── Star/particle colors ──────────────────────────────────────────────────
  static const List<Color> starColors = [
    Color(0xFF7CFFB2),   // neonMoss
    Color(0xFF00E5FF),   // electricCyan
    Color(0xFFCFCFCF),   // softGrey
    Color(0xFF5A7D6A),   // mutedOlive
    Color(0xFF05070D),   // midnightBlack (dark star)
  ];
}
