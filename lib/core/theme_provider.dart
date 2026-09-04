import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _darkMode = false;

  bool get darkMode => _darkMode;

  ThemeMode get currentTheme =>
      _darkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    carregarTema();
  }

  Future<void> carregarTema() async {
    final prefs = await SharedPreferences.getInstance();

    _darkMode = prefs.getBool("temaEscuro") ?? false;

    notifyListeners();
  }

  Future<void> alterarTema(bool value) async {
    if (_darkMode == value) return;

    _darkMode = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("temaEscuro", value);
    } catch (_) {}
  }
}