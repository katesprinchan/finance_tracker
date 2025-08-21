import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/features/categories/presentation/category_button.dart';
import 'package:finance_tracker/features/categories/presentation/page/categorie_vm.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_service.dart';
import 'package:finance_tracker/routing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

class CategoriesEditPage extends StatefulWidget {
  final SettingsService settingsService;
  final CategoryViewModel vm;
  const CategoriesEditPage(
      {super.key, required this.vm, required this.settingsService});

  @override
  State<CategoriesEditPage> createState() => _CategoriesEditPageState();
}

class _CategoriesEditPageState extends State<CategoriesEditPage> {
  SettingsService get settingsService => widget.settingsService;
  CategoryViewModel get vm => widget.vm;
  final DateTime _dateTime = DateTime.now();
  String _selectedType = 'expense';
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go(AppRouteList.categoriePage),
        ),
        title: Text(
          S.of(context).categories,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _incomeExpense(context),
            const SizedBox(height: 8),
            _categoryRow(context),
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return const SizedBox(); // вообще не должно случаться

    final settingsService = context.read<SettingsService>();
    final selectedLanguage = settingsService.currentLocale.languageCode;

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

              return GestureDetector(
                onTap: () {
                  SelectedCategory.id = doc.id;
                  SelectedCategory.name = name;
                  context.go(AppRouteList.categoriesDetailPage);
                },
                child: CategoryButton(
                  icon: _getIconData(iconName),
                  label: name,
                  backgroundColor: Colors.green.shade100,
                  iconColor: Colors.white,
                  amount: total,
                ),
              );
            }).toList();

            return Wrap(spacing: 20, runSpacing: 20, children: widgets);
          },
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

class SelectedCategory {
  static String id = '';
  static String name = '';
}
