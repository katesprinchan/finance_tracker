import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/core/presentation/button/custom_chip.dart';
import 'package:finance_tracker/features/categories/presentation/page/categorie_vm.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_service.dart';
import 'package:finance_tracker/routing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OperationsPage extends StatelessWidget {
  final SettingsService settingsService;
  final CategoryViewModel vm;
  const OperationsPage({
    super.key,
    required this.vm,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (context.watch<CategoryViewModel>().periodType !=
                  PeriodType.allTime)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    vm.previousPeriod();
                  },
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      useRootNavigator: true,
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => _buildPeriodPicker(context),
                    );
                  },
                  child: Center(
                    child: Text(
                      context
                          .watch<CategoryViewModel>()
                          .getFormattedPeriodLabel(context),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
              if (context.watch<CategoryViewModel>().periodType !=
                  PeriodType.allTime)
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    vm.nextPeriod();
                  },
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          // 👇 теперь список занимает все оставшееся место
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Operations')
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Нет операций"));
                }

                final docs = snapshot.data!.docs;
                final categoryVM = context.watch<CategoryViewModel>();
                final range = categoryVM.getCurrentDateRange();

                // Фильтрация по диапазону
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['date'] as Timestamp?;
                  if (ts == null) return false;
                  final opDate = ts.toDate();
                  if (range != null &&
                      (opDate.isBefore(range.start) ||
                          opDate.isAfter(range.end))) {
                    return false;
                  }
                  return true;
                }).toList();
                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      S.of(context).noOperations,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final date = (data['date'] as Timestamp).toDate();
                    final formattedDate =
                        DateFormat('dd MMMM yyyy', 'ru').format(date);

                    final category = data['categoryName'] ?? "Без категории";
                    final account = data['paymentMethod'] ?? "Счёт";
                    final note = data['description'] ?? "";
                    final amount = data['amount'] ?? 0;

                    return InkWell(
                      onTap: () {
                        // 👇 обработчик клика
                        SelectedOperation.id = doc.id;
                        SelectedOperation.name = note;
                        SelectedOperation.amount = amount;
                        context.go(AppRouteList.editingOperationPage);
                      },
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.category, color: Colors.white),
                        ),
                        title: Text(category),
                        subtitle: Text("$account • $note\n$formattedDate"),
                        trailing: Text(
                          "$amount ₽",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: amount < 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => context.go(AppRouteList.editingOperationPage),
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  Widget _buildPeriodPicker(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            S.of(context).period,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              CustomChip(
                label: S.of(context).allTime,
                icon: Icons.all_inclusive,
                onPressed: () {
                  vm.selectPeriod(PeriodType.allTime);
                  Navigator.of(context).pop();
                },
              ),
              CustomChip(
                label: S.of(context).chooseDay,
                icon: Icons.calendar_today,
                onPressed: () {
                  _showDatePicker(context);
                  vm.selectPeriod(PeriodType.chooseDay);
                },
              ),
              CustomChip(
                label: S.of(context).weekRange(vm.getCurrentWeekRange()),
                icon: Icons.date_range,
                onPressed: () {
                  vm.selectPeriod(PeriodType.week);
                  Navigator.of(context).pop();
                },
              ),
              CustomChip(
                label: S
                    .of(context)
                    .today(DateFormat('dd.MM').format(DateTime.now())),
                icon: Icons.today,
                onPressed: () {
                  vm.selectPeriod(PeriodType.day);
                  Navigator.of(context).pop();
                },
              ),
              CustomChip(
                label: S.of(context).year(DateTime.now().year),
                icon: Icons.calendar_month,
                onPressed: () {
                  vm.selectPeriod(PeriodType.year);
                  Navigator.of(context).pop();
                },
              ),
              CustomChip(
                label: S.of(context).month(
                    DateFormat('LLLL yyyy', 'ru').format(DateTime.now())),
                icon: Icons.calendar_view_month,
                onPressed: () {
                  vm.selectPeriod(PeriodType.month);
                  Navigator.of(context).pop();
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    ).then((value) {
      if (value != null) {
        vm.setDate(value);
      }
    });
  }
}

class SelectedOperation {
  static String id = '';
  static String name = '';
  static double amount = 0.00;
}
