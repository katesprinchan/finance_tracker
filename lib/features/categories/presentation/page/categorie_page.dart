import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/core/presentation/button/custom_chip.dart';
import 'package:finance_tracker/features/categories/presentation/category_button.dart';
import 'package:finance_tracker/features/categories/presentation/page/categorie_vm.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
    final settingsService = context.read<SettingsService>();
    final selectedLanguage = settingsService.currentLocale.languageCode;

    void showAddOperationDialog(
        BuildContext context, String categoryName, String categoryId) {
      final TextEditingController amountController = TextEditingController();
      DateTime selectedDate = DateTime.now();
      String paymentMethod = 'cash'; // 'cash' или 'card'

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
                      // Дата операции
                      Row(
                        children: [
                          Text('${S.of(context).date}: '),
                          TextButton(
                            child: Text(
                              "${selectedDate.toLocal()}".split(' ')[0],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
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

                      // Сумма операции
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: S.of(context).amount,
                        ),
                      ),

                      const SizedBox(height: 10),

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
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text(S.of(context).save),
                onPressed: () async {
                  final amountText = amountController.text.trim();
                  if (amountText.isEmpty ||
                      double.tryParse(amountText) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context).enterValidAmount)),
                    );
                    return;
                  }
                  final amount = double.parse(amountText);

                  // Сохраняем операцию в Firestore
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
                    'paymentMethod': paymentMethod,
                    'userId': currentUser.uid,
                    'createdAt': Timestamp.now(),
                  };

                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUser.uid)
                      .collection('operations')
                      .add(operationData);

                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Categories')
          .where('type', isEqualTo: _selectedType)
          .snapshots(),
      builder: (context, defaultSnapshot) {
        if (!defaultSnapshot.hasData) return const SizedBox();

        if (user == null) {
          // Только дефолтные категории без возможности добавлять операции
          final defaultCategories = defaultSnapshot.data!.docs;

          List<Widget> allCategories = defaultCategories.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = selectedLanguage == 'en'
                ? data['name_en'] ?? ''
                : data['name'] ?? '';
            final iconName = data['icon'] ?? 'category';
            return CategoryButton(
              icon: _getIconData(iconName),
              label: name,
              backgroundColor: Colors.blue.shade100,
              iconColor: Colors.white,
              amount: '0',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).logIn)),
                );
              },
            );
          }).toList();

          // Кнопка добавления категорий (можно убрать или запретить для неавторизованных)
          allCategories.add(CategoryButton(
            icon: Icons.add,
            label: '',
            backgroundColor: Colors.grey.shade300,
            iconColor: Colors.black,
            amount: '',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).logIn)),
              );
            },
          ));

          return Wrap(
            spacing: 20,
            runSpacing: 20,
            direction: Axis.horizontal,
            children: allCategories,
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .collection('categories')
              .where('type', isEqualTo: _selectedType)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const SizedBox();

            final defaultCategories = defaultSnapshot.data!.docs;
            final userCategories = userSnapshot.data!.docs;

            List<Widget> allCategories = [];

            // Дефолтные категории (автонажатие открывает диалог добавления операции)
            allCategories.addAll(defaultCategories.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = selectedLanguage == 'en'
                  ? data['name_en'] ?? ''
                  : data['name'] ?? '';
              final iconName = data['icon'] ?? 'category';

              return FutureBuilder<double>(
                future: vm.getCategorySum(
                  categoryId: doc.id,
                  startDate: vm.selectedDate,
                  endDate: vm.selectedDate,
                  userId: user.uid,
                ),
                builder: (context, snapshot) {
                  String amountText = '0.00';

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    amountText = '...'; // или можно пустую строку ''
                  } else if (snapshot.hasError) {
                    amountText = 'Err';
                  } else {
                    final sum = snapshot.data ?? 0.0;
                    amountText = sum.toStringAsFixed(2);
                  }

                  return CategoryButton(
                    icon: _getIconData(iconName),
                    label: name,
                    backgroundColor: Colors.blue.shade100,
                    iconColor: Colors.white,
                    amount: amountText,
                    onTap: () {
                      showAddOperationDialog(context, name, doc.id);
                    },
                  );
                },
              );
            }));
            // Пользовательские категории
            allCategories.addAll(userCategories.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              return CategoryButton(
                icon: Icons.category,
                label: name,
                backgroundColor: Colors.green.shade100,
                iconColor: Colors.white,
                amount: '0',
                onTap: () {
                  showAddOperationDialog(context, name, doc.id);
                },
              );
            }));

            // Кнопка добавления категории
            allCategories.add(CategoryButton(
              icon: Icons.add,
              label: '',
              backgroundColor: Colors.grey.shade300,
              iconColor: Colors.black,
              amount: '',
              onTap: () {
                _showAddCategoryDialog(context);
              },
            ));

            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: allCategories,
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).logIn)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить категорию'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Название категории',
              hintText: 'Например, Хобби',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название категории')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(user.uid)
                      .collection('categories')
                      .add({
                    'name': name,
                    'name_en': name,
                    'type':
                        _selectedType, // текущий выбранный тип: income/expense
                    'icon': 'category', // можно заменить на выбранную позже
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.of(context).pop(); // закрыть диалог
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка при добавлении: $e')),
                  );
                }
              },
              child: const Text('Добавить'),
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
