import 'package:flutter/material.dart';

/// Palette de couleurs du studio photo — thème dark luxueux
class AppColors {
  AppColors._();

  // ── Fonds ──
  static const Color background = Color(0xFF0D0D0D); // Noir profond
  static const Color surface = Color(0xFF1A1A1A); // Gris nuit (cards)
  static const Color surfaceLight = Color(0xFF2A2A2A); // Gris clair (inputs)

  // ── Accents principaux ──
  static const Color yellow = Color(0xFFF5C518); // Jaune studio (actions, CTA)
  static const Color gold = Color(0xFFC9A84C); // Doré luxe (titres, icônes)
  static const Color goldLight = Color(0xFFE8C97A); // Doré clair (highlights)

  // ── Textes ──
  static const Color textPrimary = Color(0xFFF8F4EE); // Blanc chaud
  static const Color textSecondary = Color(0xFFAAAAAA); // Gris clair
  static const Color textHint = Color(0xFF666666); // Gris hint

  // ── Statuts ──
  static const Color success = Color(0xFF4CAF50); // Vert disponible
  static const Color error = Color(0xFFE53935); // Rouge loué/retard
  static const Color warning = Color(0xFFF5C518); // Jaune maintenance
  static const Color info = Color(0xFF42A5F5); // Bleu info

  // ── Dégradés utilitaires ──
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient yellowGradient = LinearGradient(
    colors: [Color(0xFFF5C518), Color(0xFFE8B800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, Color(0xFF222222)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
