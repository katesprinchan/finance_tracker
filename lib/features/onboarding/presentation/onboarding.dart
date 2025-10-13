import 'package:finance_tracker/routing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Фиксируй свои финансы 💸",
      "text":
          "Записывай все доходы и расходы в пару кликов, чтобы всегда знать, куда уходят деньги."
    },
    {
      "title": "Распределяй по категориям 🗂️",
      "text":
          "Создавай категории и удобно сортируй траты — еда, транспорт, развлечения и многое другое."
    },
    {
      "title": "Анализируй и управляй 📊",
      "text":
          "Смотри на наглядные графики и находи, где можно сэкономить, чтобы достичь своих финансовых целей."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () async {
                    // переход на главный экран приложения

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_seen', true);
                    context.go(AppRouteList.categoriePage);
                  },
                  child: const Text("Пропустить"),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingData.length,
                  onPageChanged: (index) {
                    setState(
                        () => isLastPage = index == onboardingData.length - 1);
                  },
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          onboardingData[index]['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onboardingData[index]['text']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SmoothPageIndicator(
                controller: _controller,
                count: onboardingData.length,
                effect: const WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (isLastPage) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_seen', true);

                      context.go(AppRouteList.categoriePage);
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(isLastPage ? "Начать" : "Далее"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
