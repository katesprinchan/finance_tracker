import 'dart:async';

import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/core/presentation/app_text_field/app_text_editing_controller.dart';
import 'package:finance_tracker/core/presentation/password_text_editing_controller.dart';
import 'package:finance_tracker/features/auth/data/source/user_model.dart';
import 'package:finance_tracker/features/auth/domain/repository/user_repository.dart';
import 'package:finance_tracker/features/auth/presentation/snack_bar.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_service.dart';
import 'package:finance_tracker/features/settings/presentation/settings_modal_bs.dart';
import 'package:finance_tracker/routing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_variables/reactive_variables.dart';

class AuthViewModel {
  final SettingsService _settingsService;

  AuthViewModel({
    required SettingsService settingService,
  }) : _settingsService = settingService;

  late TabController tabController;

  final emailLoginTextCtrl = AppTextEditingController();
  final passwordLoginTextCtrl = PassTextEditingController();
  final nameRegisterTextCtrl = AppTextEditingController();
  final emailRegisterTextCtrl = AppTextEditingController();
  final passwordRegisterTextCtrl = PassTextEditingController();
  final repeatPasswordRegisterTextCtrl = PassTextEditingController();
  Timer? timer;

  bool isEmailVerified = false;

  final canResendEmail = false;

  final isUserAgreedWithPnPUsage = false.rv;

  final isButtonDisabled = false.rv;

  final isLoginPossible = false.rv;

  final isRegisterPossible = false.rv;

  void init({
    required final TabController tabController,
  }) {
    this.tabController = tabController;
    initListeners();
  }

  void dispose() {
    disposeListeners();
    timer?.cancel();
  }

  void _loginPossibilityListener() {
    if (emailLoginTextCtrl.text.isEmpty || passwordLoginTextCtrl.text.isEmpty) {
      isLoginPossible(false);
      return;
    }

    isLoginPossible(true);
  }

  void _registerPossibilityChanger() {
    // if (!isUserAgreedWithPnPUsage()) {
    //   isRegisterPossible(false);
    //   return;
    // }

    if (nameRegisterTextCtrl.text.isEmpty ||
        emailRegisterTextCtrl.text.isEmpty ||
        passwordRegisterTextCtrl.text.isEmpty ||
        repeatPasswordRegisterTextCtrl.text.isEmpty) {
      isRegisterPossible(false);
      return;
    }

    isRegisterPossible(true);
  }

  void _passwordVisibilityListener() {
    repeatPasswordRegisterTextCtrl
        .isTextHidden(passwordRegisterTextCtrl.isTextHidden());
  }

  void _repeatPasswordVisibilityListener() {
    passwordRegisterTextCtrl
        .isTextHidden(repeatPasswordRegisterTextCtrl.isTextHidden());
  }

  void initListeners() {
    isUserAgreedWithPnPUsage.addListener(_registerPossibilityChanger);
    emailLoginTextCtrl.addListener(_loginPossibilityListener);
    passwordLoginTextCtrl.addListener(_loginPossibilityListener);
    passwordRegisterTextCtrl.isTextHidden
        .addListener(_passwordVisibilityListener);
    repeatPasswordRegisterTextCtrl.isTextHidden
        .addListener(_repeatPasswordVisibilityListener);
    nameRegisterTextCtrl.addListener(_registerPossibilityChanger);
    emailRegisterTextCtrl.addListener(_registerPossibilityChanger);
    passwordRegisterTextCtrl.addListener(_registerPossibilityChanger);
    repeatPasswordRegisterTextCtrl.addListener(_registerPossibilityChanger);
  }

  void disposeListeners() {
    isUserAgreedWithPnPUsage.removeListener(_registerPossibilityChanger);
    emailLoginTextCtrl.removeListener(_loginPossibilityListener);
    passwordLoginTextCtrl.removeListener(_loginPossibilityListener);
    passwordRegisterTextCtrl.isTextHidden
        .removeListener(_passwordVisibilityListener);
    repeatPasswordRegisterTextCtrl.isTextHidden
        .removeListener(_repeatPasswordVisibilityListener);
    nameRegisterTextCtrl.removeListener(_registerPossibilityChanger);
    emailRegisterTextCtrl.removeListener(_registerPossibilityChanger);
    passwordRegisterTextCtrl.removeListener(_registerPossibilityChanger);
    repeatPasswordRegisterTextCtrl.removeListener(_registerPossibilityChanger);
  }

  void onCheckBoxChecked(bool? value) =>
      isUserAgreedWithPnPUsage(value ?? false);

  Future<void> signIn(BuildContext context) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailLoginTextCtrl.text.trim(),
        password: passwordLoginTextCtrl.text.trim(),
      );

      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        SnackBarService.showSnackBar(
          context,
          S.of(context).confirmEmail,
          true,
        );
        return;
      }

      context.go(AppRouteList.operationListPage);
      final idToken = await user!.getIdToken();
      print('ID Token: $idToken');
    } on FirebaseAuthException catch (e) {
      print(e.code);
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        SnackBarService.showSnackBar(
          context,
          S.of(context).incorrectEmailPassword,
          true,
        );
      } else if (e.code == 'invalid-credential') {
        SnackBarService.showSnackBar(
          context,
          S.of(context).incorrectEmailPassword,
          true,
        );
      } else {
        SnackBarService.showSnackBar(
          context,
          S.of(context).unknownError,
          true,
        );
      }
    }
  }

  Future<void> signUp(BuildContext context) async {
    final UserRepository userRepository = UserRepository(context);

    if (passwordRegisterTextCtrl.text != repeatPasswordRegisterTextCtrl.text) {
      SnackBarService.showSnackBar(
        context,
        S.of(context).passwordsNotMatching,
        true,
      );
      return;
    }

    String? passwordValidationResult =
        validatePassword(passwordRegisterTextCtrl.text.trim(), context);
    if (passwordValidationResult != null) {
      SnackBarService.showSnackBar(
        context,
        passwordValidationResult,
        true,
      );
      return;
    }

    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        // Привязка email-пароля к анонимному аккаунту
        final credential = EmailAuthProvider.credential(
          email: emailRegisterTextCtrl.text.trim(),
          password: passwordRegisterTextCtrl.text.trim(),
        );

        final userCredential = await currentUser.linkWithCredential(credential);

        final uid = userCredential.user!.uid;
        UserModel userdb = UserModel(
          fullName: nameRegisterTextCtrl.text.trim(),
          email: emailRegisterTextCtrl.text.trim(),
          profileImageURL: '',
          isAnonymous: false,
        );
        await userRepository.createUser(uid, userdb);

        if (!userCredential.user!.emailVerified) {
          await userCredential.user!.sendEmailVerification();
          context.go(AppRouteList.emailAddressVerificationPage);
        } else {
          context.go(AppRouteList.operationListPage);
        }
      } else {
        // Обычная регистрация для новых пользователей
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: emailRegisterTextCtrl.text.trim(),
          password: passwordRegisterTextCtrl.text.trim(),
        );

        final uid = userCredential.user!.uid;
        UserModel userdb = UserModel(
          fullName: nameRegisterTextCtrl.text.trim(),
          email: emailRegisterTextCtrl.text.trim(),
          profileImageURL: '',
          isAnonymous: false,
        );
        await userRepository.createUser(uid, userdb);

        if (!userCredential.user!.emailVerified) {
          await userCredential.user!.sendEmailVerification();
          context.go(AppRouteList.emailAddressVerificationPage);
        } else {
          context.go(AppRouteList.operationListPage);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        SnackBarService.showSnackBar(
          context,
          S.of(context).emailAlreadyInUse,
          true,
        );
      } else if (e.code == 'invalid-email') {
        SnackBarService.showSnackBar(
          context,
          S.of(context).emailIsIncorrect,
          true,
        );
      } else if (e.code == 'weak-password') {
        SnackBarService.showSnackBar(
          context,
          S.of(context).passwordIsTooEasy,
          true,
        );
      } else if (e.code == 'credential-already-in-use') {
        SnackBarService.showSnackBar(
          context,
          'Этот email уже привязан к другому аккаунту',
          true,
        );
      } else {
        SnackBarService.showSnackBar(
          context,
          S.of(context).unknownError,
          true,
        );
      }
    }
  }

  void onSettingsTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          SettingsModalBottomSheet(settingsService: _settingsService),
      showDragHandle: true,
    );
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
      print(isEmailVerified);
      if (isEmailVerified) timer?.cancel();
    } catch (e) {
      print(e);
    }
  }

  String? validatePassword(String password, context) {
    if (password.length < 8) {
      return S.of(context).passwordIsTooShort;
    }
    if (!RegExp(r'^(?=.*[a-z])').hasMatch(password)) {
      return S.of(context).passwordMustContainAtLeastOneLowercaseLetter;
    }
    if (!RegExp(r'^(?=.*[A-Z])').hasMatch(password)) {
      return S.of(context).passwordMustContainAtLeastOneUppercaseLetter;
    }
    if (!RegExp(r'^(?=.*\d)').hasMatch(password)) {
      return S.of(context).passwordMustContainAtLeastOneDigit;
    }
    if (password == '123456' ||
        password == 'password' ||
        password == 'qwerty') {
      return S.of(context).passwordIsTooCommon;
    }
    return null;
  }
}
