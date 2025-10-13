import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/core/presentation/button/custom_chip.dart';
import 'package:finance_tracker/features/categories/presentation/category_button.dart';
import 'package:finance_tracker/features/categories/presentation/page/categorie_vm.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_service.dart';
import 'package:finance_tracker/routing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class CategoriePage extends StatefulWidget {
  final SettingsService settingsService;
  final CategoryViewModel vm;
  const CategoriePage(
      {super.key, required this.vm, required this.settingsService});

  @override
  State<CategoriePage> createState() => _CategoriePageState();
}

class _CategoriePageState extends State<CategoriePage> {
  SettingsService get settingsService => widget.settingsService;
  CategoryViewModel get vm => widget.vm;
  final DateTime _dateTime = DateTime.now();
  String _selectedType = 'expense';
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
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
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  context.go(AppRouteList.editingCategoriePage);
                },
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
          _incomeExpense(context),
          const SizedBox(height: 8),
          _categoryRow(context),
        ],
      ),
    );
  }

  Widget _categoryRow(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return const SizedBox(); // вообще не должно случаться

    final settingsService = context.read<SettingsService>();
    final selectedLanguage = settingsService.currentLocale.languageCode;

    void showAddCategoryDialog() {
      final controller = TextEditingController();

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(S.of(dialogContext).addCategory),
          content: TextField(
            controller: controller,
            decoration:
                InputDecoration(labelText: S.of(dialogContext).categoryName),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.dispose();
              },
              child: Text(S.of(dialogContext).cancel),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                final categoryData = {
                  'name': name,
                  'name_en': name,
                  'type': _selectedType,
                  'icon': 'category',
                  'userId': uid,
                  'createdAt': Timestamp.now(), // можно и serverTimestamp()
                };

                try {
                  await FirebaseFirestore.instance
                      .collection('CategoriesUser')
                      .add(categoryData);

                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop(); // закрываем диалог
                } finally {
                  controller.dispose();
                }
              },
              child: Text(S.of(dialogContext).add),
            ),
          ],
        ),
      );
    }

    final defaultCats = FirebaseFirestore.instance
        .collection('Categories')
        .where('type', isEqualTo: _selectedType)
        .snapshots();

    final userCats = FirebaseFirestore.instance
        .collection('CategoriesUser')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: _selectedType)
        .snapshots();

    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: Rx.combineLatest2<QuerySnapshot, QuerySnapshot,
          List<QueryDocumentSnapshot>>(defaultCats, userCats, (def, usr) {
        final userDocs = usr.docs;
        final overridden = userDocs
            .map((d) => (d.data() as Map)['originalCategoryId'] as String?)
            .whereType<String>()
            .toSet();

        return [
          ...def.docs.where((d) => !overridden.contains(d.id)),
          ...userDocs
        ];
      }),
      builder: (context, catSnap) {
        if (!catSnap.hasData) return const SizedBox();
        final categories = catSnap.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Operations')
              .where('userId', isEqualTo: uid)
              .where('type', isEqualTo: _selectedType)
              .snapshots(),
          builder: (context, opSnap) {
            if (!opSnap.hasData) return const SizedBox();
            final ops = opSnap.data!.docs;
            final categoryVM = context.watch<CategoryViewModel>();
            final range = categoryVM.getCurrentDateRange();
            // Суммы по категориям
            final totals = <String, double>{};
            for (var op in ops) {
              final data = op.data() as Map<String, dynamic>;
              final ts = data['date'] as Timestamp?;
              if (ts == null) continue;
              final opDate = ts.toDate();

              // фильтрация по диапазону
              if (range != null &&
                  (opDate.isBefore(range.start) || opDate.isAfter(range.end))) {
                continue;
              }
              // фильтрация по userId
              final uid = data['userId'] as String?;
              if (uid != user?.uid) {
                continue;
              }

              final cid = data['categoryId'] as String?;
              final amt = (data['amount'] as num?)?.toDouble() ?? 0;
              if (cid != null) {
                totals[cid] = (totals[cid] ?? 0) + amt;
              }
            }

            final widgets = categories.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = selectedLanguage == 'en'
                  ? data['name_en'] ?? data['name'] ?? ''
                  : data['name'] ?? data['name_en'] ?? '';
              final iconName = data['icon'] ?? 'category';
              final total = totals[doc.id] ?? 0;

              return CategoryButton(
                icon: _getIconData(iconName),
                label: name,
                backgroundColor: Colors.green.shade100,
                iconColor: Colors.white,
                amount: total,
                onTap: () => showAddOperationDialog(
                  context,
                  name,
                  doc.id,
                ),
              );
            }).toList();

            widgets.add(CategoryButton(
              icon: Icons.add,
              label: '',
              backgroundColor: Colors.grey.shade300,
              iconColor: Colors.black,
              amount: null,
              onTap: showAddCategoryDialog,
            ));

            return Wrap(spacing: 20, runSpacing: 20, children: widgets);
          },
        );
      },
    );
  }

  void showAddOperationDialog(
    BuildContext context,
    String categoryName,
    String categoryId,
  ) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${S.of(context).addOperation} - $categoryName'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Дата
                    Row(
                      children: [
                        Text('${S.of(context).date}: '),
                        TextButton(
                          child: Text(
                            DateFormat('dd.MM.yyyy').format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null && picked != selectedDate) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    // Сумма
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: S.of(context).amount,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: S.of(context).description,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Способ оплаты
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.of(context).paymentMethod),
                        RadioListTile<String>(
                          title: Text(S.of(context).cash),
                          value: 'cash',
                          groupValue: paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              paymentMethod = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: Text(S.of(context).card),
                          value: 'card',
                          groupValue: paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              paymentMethod = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(S.of(context).save),
              onPressed: () async {
                final amountText = amountController.text.trim();
                final descriptionText = descriptionController.text.trim();
                if (amountText.isEmpty || double.tryParse(amountText) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).enterValidAmount)),
                  );
                  return;
                }

                final amount = double.parse(amountText);
                final currentUser = FirebaseAuth.instance.currentUser;

                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).logIn)),
                  );
                  return;
                }

                final operationData = {
                  'categoryId': categoryId,
                  'type': _selectedType,
                  'categoryName': categoryName,
                  'date': Timestamp.fromDate(selectedDate),
                  'amount': amount,
                  'description': descriptionText,
                  'paymentMethod': paymentMethod,
                  'userId': currentUser.uid,
                  'createdAt': Timestamp.now(),
                };

                await FirebaseFirestore.instance
                    .collection('Operations')
                    .add(operationData);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _incomeExpense(BuildContext context) {
    return Center(
      child: DropdownButton<String>(
        value: _selectedType,
        onChanged: (String? newValue) {
          setState(() {
            _selectedType = newValue!;
          });
        },
        items: [
          DropdownMenuItem(
            value: 'expense',
            child: Text(
              S.of(context).expense,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          DropdownMenuItem(
            value: 'income',
            child: Text(
              S.of(context).income,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'movie':
        return Icons.movie;
      case 'bus_alert':
        return Icons.bus_alert;
      case 'money':
        return Icons.attach_money;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'monetization_on':
        return Icons.monetization_on;
      // Добавь ещё нужные иконки
      default:
        return Icons.category;
    }
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
                  }),
              CustomChip(
                  label: S.of(context).chooseDay,
                  icon: Icons.calendar_today,
                  onPressed: (() {
                    _showDatePicker();
                    vm.selectPeriod(PeriodType.chooseDay);
                  })),
              CustomChip(
                  label: S.of(context).weekRange(vm.getCurrentWeekRange()),
                  icon: Icons.date_range,
                  onPressed: () {
                    vm.selectPeriod(PeriodType.week);
                    Navigator.of(context).pop();
                  }),
              CustomChip(
                  label: S
                      .of(context)
                      .today(DateFormat('dd.MM').format(DateTime.now())),
                  icon: Icons.today,
                  onPressed: () {
                    vm.selectPeriod(PeriodType.day);
                    Navigator.of(context).pop();
                  }),
              CustomChip(
                  label: S.of(context).year(DateTime.now().year),
                  icon: Icons.calendar_month,
                  onPressed: () {
                    vm.selectPeriod(PeriodType.year);
                    Navigator.of(context).pop();
                  }),
              CustomChip(
                  label: S.of(context).month(
                      DateFormat('LLLL yyyy', 'ru').format(DateTime.now())),
                  icon: Icons.calendar_view_month,
                  onPressed: () {
                    vm.selectPeriod(PeriodType.month);
                    Navigator.of(context).pop();
                  }),
            ],
          )
        ],
      ),
    );
  }

  void _showDatePicker() {
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
