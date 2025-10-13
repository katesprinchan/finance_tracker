import 'package:finance_tracker/routing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitViewModel {
  const InitViewModel();

  Future<void> goToAuth(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool seen = prefs.getBool('onboarding_seen') ?? false;

    // Небольшая задержка, как у тебя было
    await Future.delayed(const Duration(seconds: 2));

    if (seen) {
      // Если онбординг уже пройден – идём на основную страницу
      context.go(AppRouteList.categoriePage);
    } else {
      // Если нет – показываем онбординг
      context.go(AppRouteList.onboardingPage);
    }
  }
}
