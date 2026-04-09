import 'package:flutter/material.dart';

const ficsitAmber = Color(0xFFBA7517);

const wipBg = Color(0xFFE6F1FB);
const wipText = Color(0xFF185FA5);
const minimalBg = Color(0xFFFAEEDA);
const minimalText = Color(0xFF633806);
const optimizedBg = Color(0xFFEAF3DE);
const optimizedText = Color(0xFF27500A);

final appTheme = ThemeData(
  fontFamily: 'ShareTechMono',
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ficsitAmber,
    primary: ficsitAmber,
    surface: Colors.white,
    onSurface: const Color(0xFF1A1A1A),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1A1A1A),
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF5F5F4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ficsitAmber, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
);
