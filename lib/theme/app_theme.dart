import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161B22),
      foregroundColor: Color(0xFF58A6FF),
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF21262D),
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF238636),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF58A6FF),
      textColor: Color(0xFFE6EDF3),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Color(0xFFE6EDF3),
        fontFamily: 'Courier',
      ),
      bodyMedium: TextStyle(
        color: Color(0xFFE6EDF3),
        fontFamily: 'Courier',
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF58A6FF),
    ),
  );
}
