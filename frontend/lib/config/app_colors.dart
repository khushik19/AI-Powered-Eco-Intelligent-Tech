import 'package:flutter/material.dart';

class AppColors {
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
  // Core palette
  static const Color abyss = Color(0xFF060B12);
  static const Color bioTeal = Color(0xFF00FFD1);
  static const Color reefCoral = Color(0xFFFF6B6B);
  static const Color kelp = Color(0xFF2E8B57);
  static const Color seaFoam = Color(0xFFD4EDE8);

  // Aliases
  static const Color forestGreen = kelp;
  static const Color oliveGreen = kelp;
  static const Color tealBlue = bioTeal;
  static const Color electricCyan = bioTeal;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = seaFoam;
  static const Color textMuted = Color(0xFF5A626C);
  static const Color glassBorder = Color(0x3300FFD1);
  static const Color glassWhite = Colors.white10;
  static const Color error = reefCoral;
  static const Color cream = seaFoam;
  static const Color dustyRose = reefCoral;

  // Cosmic palette
  static const Color cosmicPurple = Color(0xFF7B61FF);
  static const Color nebulaBlue = bioTeal;
  static const Color stardustGold = Color(0xFFFFD700);

  // Missing colors referenced across the app
  static const Color neonMoss = Color(0xFF39FF14);
  static const Color softGrey = Color(0xFF8A9BA8);
  static const Color background = abyss;
  static const Color backgroundSecondary = Color(0xFF0D1B2A);
  static const Color midnightBlack = Color(0xFF020408);
  static const Color cosmicGreen = Color(0xFF00C896);
  static const Color glassWhiteStrong = Color(0x66FFFFFF);

  // Star colors list for cosmic background
  static const List<Color> starColors = [
    Colors.white,
    bioTeal,
    seaFoam,
    Color(0xFFB0E0FF),
    stardustGold,
  ];
}
<<<<<<< HEAD
=======
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
>>>>>>> 9a1a991c4a0ff6488c71bc926a7e96f24c21bd19
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
