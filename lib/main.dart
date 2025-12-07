import 'package:flutter/material.dart';
import 'package:quant/screens/quant_home_screen.dart';

void main() {
  runApp(const QuantApp());
}

class QuantApp extends StatelessWidget {
  const QuantApp({super.key});

  static const Color _backgroundColor = Color(0xfff7f4ef);
  static const Color _textColor = Color(0xff1f140f);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _textColor,
      brightness: Brightness.light,
      background: _backgroundColor,
      surface: _backgroundColor,
    );

    return MaterialApp(
      title: 'Quant',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _backgroundColor,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: _backgroundColor,
          foregroundColor: _textColor,
          elevation: 0,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: _textColor,
              displayColor: _textColor,
            ),
      ),
      home: const QuantHomeScreen(),
    );
  }
}
