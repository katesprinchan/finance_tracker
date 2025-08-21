import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/core/domain/container/app_container.dart';
import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_service.dart';
import 'package:finance_tracker/routing.dart';
import 'package:finance_tracker/theme/theme_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

Future<User> signInAnonymouslyIfNeeded() async {
  final auth = FirebaseAuth.instance;
  var user = auth.currentUser;
  if (user == null) {
    final userCredential = await auth.signInAnonymously();
    user = userCredential.user;
  }
  return user!;
}

/*Future<void> createUserRecordIfNeeded(User user) async {
  final usersRef = FirebaseFirestore.instance.collection('Users');
  final doc = await usersRef.doc(user.uid).get();

  if (!doc.exists) {
    await usersRef.doc(user.uid).set({
      'uid': user.uid,
      'isAnonymous': user.isAnonymous,
    });
  }
}*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppContainer.init();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Анонимный вход и создание записи в users
  /*final user = await signInAnonymouslyIfNeeded();
  await createUserRecordIfNeeded(user);*/

  runApp(MyApp(
    appContainer: AppContainer(),
  ));
}

class MyApp extends StatelessWidget {
  final AppContainer appContainer;

  const MyApp({
    super.key,
    required this.appContainer,
  });

  SettingsService get settingsService =>
      appContainer.serviceScope.settingsService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => settingsService,
      child: BlocBuilder(
        bloc: settingsService,
        builder: (context, state) => MaterialApp.router(
          title: 'GrowCash',
          theme: settingsService.currentTheme ? darkTheme : lightTheme,
          routerConfig: AppRouterConfig.instance,
          localizationsDelegates: const [
            S.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          locale: settingsService.currentLocale,
          supportedLocales: settingsService.supportedLocaleList,
        ),
      ),
    );
  }
}
