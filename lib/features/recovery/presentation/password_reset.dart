import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/core/presentation/app_bar.dart';
import 'package:finance_tracker/core/presentation/button/app_bar_action_button.dart';
import 'package:finance_tracker/features/recovery/presentation/recovery_vm.dart';
import 'package:finance_tracker/theme/colors_collection.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PasswordResetPage extends StatefulWidget {
  final RecoveryViewModel vm;
  const PasswordResetPage({
    super.key,
    required this.vm,
  });

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage>
    with SingleTickerProviderStateMixin {
  RecoveryViewModel get vm => widget.vm;
  @override
  void initState() {
    vm.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        context: context,
        actions: [
          AppBarActionButton(
            onTap: () => vm.onSettingsTap(context),
            child: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset('assets/image/send_email.json')),
              const SizedBox(height: 16),
              Text(
                textAlign: TextAlign.center,
                S.of(context).passwordReset,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ColorsCollection.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
