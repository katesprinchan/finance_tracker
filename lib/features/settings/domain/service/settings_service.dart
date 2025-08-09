import 'dart:async';

import 'package:finance_tracker/features/settings/domain/entity/app_locale.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_event.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends Bloc<SettingsEvent, SettingsState> {
  SettingsService(super.initialState) {
    _loadSettings();
    on<ChangeLocaleEvent>(_onChangeLocaleEvent);
    on<ChangeThemeEvent>(_onChangeThemeEvent);
  }

  final List<AppLocale> supportedLocaleList = [
    const AppLocale(
      name: 'Русский',
      languageCode: 'ru',
    ),
    const AppLocale(
      name: 'English',
      languageCode: 'en',
    )
  ];

  AppLocale get currentLocale => supportedLocaleList[state.localeIndex];
  bool get currentTheme => state.isDarkMode;

  Future<void> _onChangeLocaleEvent(
    ChangeLocaleEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsState(
      localeIndex: event.newLocaleIndex,
      isDarkMode: state.isDarkMode,
    ));
    _saveSettings();
  }

  Future<void> _onChangeThemeEvent(
    ChangeThemeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsState(
      localeIndex: state.localeIndex,
      isDarkMode: event.isDarkMode,
    ));
    _saveSettings();
  }

  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('localeIndex', state.localeIndex);
    await prefs.setBool('isDarkMode', state.isDarkMode);
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? savedLocaleIndex = prefs.getInt('localeIndex');
    bool? savedDarkMode = prefs.getBool('isDarkMode');

    if (savedLocaleIndex != null && savedDarkMode != null) {
      emit(SettingsState(
          localeIndex: savedLocaleIndex, isDarkMode: savedDarkMode));
    }
  }
}
