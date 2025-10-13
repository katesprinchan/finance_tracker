import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/features/categories/presentation/page/categorie_vm.dart';
import 'package:finance_tracker/features/operations/presentation/page/operations_page.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_service.dart';
import 'package:finance_tracker/routing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OperationsEditPageDetail extends StatefulWidget {
  final SettingsService settingsService;
  final CategoryViewModel vm;

  const OperationsEditPageDetail({
    super.key,
    required this.vm,
    required this.settingsService,
  });

  @override
  State<OperationsEditPageDetail> createState() =>
      _OperationsEditPageDetailState();
}

class _OperationsEditPageDetailState extends State<OperationsEditPageDetail> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final String categoryId = SelectedOperation.id;
  final String categoryName = SelectedOperation.name;
  final double amount = SelectedOperation.amount;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = categoryName;
    _amountController.text = amount.toString();
    _isLoading = false;
  }

  /// Универсальная функция: ищет документ в CategoriesUser, затем в Categories
  Future<DocumentReference?> _findDocRef(String id) async {
    final userRef = FirebaseFirestore.instance.collection('Operations').doc(id);
    final userSnap = await userRef.get();
    if (userSnap.exists) return userRef;

    return null; // нигде не найден
  }

  Future<void> _updateCategory() async {
    setState(() => _isLoading = true);

    try {
      final docRef = await _findDocRef(categoryId);
      if (docRef == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).error,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        );
        return;
      }

      await docRef.update({
        'description': _nameController.text.trim(),
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).categoryUpdated,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).error,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            S.of(context).deleteCategory,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            S.of(context).sureDeleteCategory,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                S.of(context).close,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                S.of(context).delete,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        );
      },
    );
    debugPrint('confirm = $confirm'); // теперь должно быть true или false

    if (confirm != true) return; // сюда попадем только если нажали "Удалить"

    setState(() => _isLoading = true);

    try {
      final docRef = await _findDocRef(categoryId);
      if (docRef == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).error,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        );
        return;
      }

      await docRef.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).deleteCategory,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        );
        context.go(
            AppRouteList.operationListPage); // <-- уводим на список категорий
      }
    } catch (e) {
      debugPrint('Ошибка при удалении: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).error,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go(AppRouteList.operationListPage),
        ),
        title: Text(
          S.of(context).operations,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateCategory,
                    child: Text(
                      S.of(context).save,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: TextButton.icon(
                      onPressed: _deleteCategory,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: Text(
                        S.of(context).delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
