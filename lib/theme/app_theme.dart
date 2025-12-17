import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === PRIMARY COLORS (DGU Brand) ===
  static const dguGreen = Color(0xFF1B5E20);
  static const dguGreenLight = Color(0xFF388E3C);
  static const dguGreenLighter = Color(0xFF66BB6A);
  static const dguOlive = Color(0xFF9E9D24);
  
  // === ACCENT COLORS ===
  static const accentCyan = Color(0xFF00ACC1); // Turkis til CTAs
  static const accentLightGreen = Color(0xFF4CAF50); // Frisk grøn til CTAs
  
  // === FEATURE COLORS (Color-coded icons) ===
  static const featureCyan = Color(0xFF00BCD4); // Handicap/Data
  static const featureRed = Color(0xFFF44336); // Scores/Performance
  static const featureYellow = Color(0xFFFFC107); // Awards/Achievements
  static const featureGreen = Color(0xFF4CAF50); // Statistics/Trends
  static const featurePurple = Color(0xFF9C27B0); // Social/Friends
  
  // === BACKGROUNDS ===
  static const backgroundColor = Color(0xFFF5F5F5);
  static const cardColor = Color(0xFFFFFFFF);
  static const birdieBonusOrange = Color(0xFFE1A740);
  
  // === HERO BANNER COLORS (Golfbane illustration) ===
  static const heroSkyLight = Color(0xFFFFF9E6); // Cream (sol-glød)
  static const heroSkyBlue = Color(0xFFE3F2FD); // Lys blå himmel
  static const heroGreenDark = Color(0xFF2E7D32); // Mørk grøn (træer)
  static const heroGreenMedium = Color(0xFF66BB6A); // Medium grøn (bakker)
  static const heroGreenLight = Color(0xFF81C784); // Lys grøn (fairway)
  static const heroGreenForeground = Color(0xFF9CCC65); // Forreste green
  
  // === LOCKED STATE ===
  static const lockedGrey = Color(0xFFBDBDBD);
  static const lockedTextGrey = Color(0xFF757575);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: dguGreen,
        primary: dguGreen,
        secondary: dguOlive,
        surface: cardColor,
        background: backgroundColor,
        brightness: Brightness.light,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: backgroundColor,
      
      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: dguGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Button themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dguGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Pill shape!
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dguGreen,
          side: const BorderSide(color: dguGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Pill shape!
          ),
        ),
      ),
      
      // Input decoration (for DropdownMenus)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dguGreen, width: 2),
        ),
      ),
      
      // Menu theme for dropdown items
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: MaterialStateProperty.all(backgroundColor),
          padding: MaterialStateProperty.all(const EdgeInsets.all(8)),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      
      // Menu button theme for individual dropdown items
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return Colors.grey.shade100;
            }
            return Colors.white;
          }),
          foregroundColor: MaterialStateProperty.all(Colors.black87),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          // Add visual separation with border
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: backgroundColor, // Light gray divider
                width: 2,
              ),
            ),
          ),
          elevation: MaterialStateProperty.all(2),
          shadowColor: MaterialStateProperty.all(Colors.black38),
          // Attempt to add spacing via minimumSize and tapTargetSize
          minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
        ),
      ),
      
      // Text theme
      textTheme: GoogleFonts.robotoTextTheme(),
    );
  }

  // Dark theme for dark mode
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: dguGreen,
        primary: dguGreen,
        secondary: dguOlive,
        surface: const Color(0xFF1E1E1E), // Dark surface
        background: const Color(0xFF121212), // Darker background
        brightness: Brightness.dark,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      // Card theme
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Button themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dguGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Pill shape!
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dguGreen,
          side: const BorderSide(color: dguGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Pill shape!
          ),
        ),
      ),
      
      // Input decoration (for DropdownMenus)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C), // Slightly lighter than surface
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dguGreen, width: 2),
        ),
      ),
      
      // Menu theme for dropdown items
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: MaterialStateProperty.all(const Color(0xFF1E1E1E)),
          padding: MaterialStateProperty.all(const EdgeInsets.all(8)),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      
      // Menu button theme for individual dropdown items
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return Colors.grey.shade800;
            }
            return const Color(0xFF2C2C2C);
          }),
          foregroundColor: MaterialStateProperty.all(Colors.white),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(
                color: Color(0xFF121212),
                width: 2,
              ),
            ),
          ),
          elevation: MaterialStateProperty.all(2),
          shadowColor: MaterialStateProperty.all(Colors.black87),
          minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
        ),
      ),
      
      // Text theme
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
    );
  }
}

