import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_service.dart';
import 'package:finance_tracker/features/settings/presentation/settings_modal_bs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PeriodType { allTime, day, week, month, year, chooseDay }

class CategoryViewModel extends ChangeNotifier {
  final SettingsService _settingsService;

  CategoryViewModel({
    required SettingsService settingService,
  }) : _settingsService = settingService;
  PeriodType _periodType = PeriodType.day;
  DateTime _selectedDate = DateTime.now();
  PeriodType get periodType => _periodType;
  DateTime get selectedDate => _selectedDate;
  void selectPeriod(PeriodType type, [DateTime? date]) {
    _periodType = type;
    _selectedDate = date ?? DateTime.now();
    notifyListeners();
  }

  String getCurrentLanguageCode() {
    return _settingsService.currentLocale.languageCode;
  }

  void nextPeriod() {
    switch (_periodType) {
      case PeriodType.chooseDay:
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        break;
      case PeriodType.day:
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        break;
      case PeriodType.week:
        _selectedDate = _selectedDate.add(const Duration(days: 7));
        break;
      case PeriodType.month:
        _selectedDate =
            DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        break;
      case PeriodType.year:
        _selectedDate = DateTime(_selectedDate.year + 1, 1, 1);
        break;
      default:
        return;
    }
    notifyListeners();
  }

  DateTimeRange? getCurrentDateRange() {
    switch (_periodType) {
      case PeriodType.allTime:
        return null; // без ограничений
      case PeriodType.day:
      case PeriodType.chooseDay:
        final start = DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day);
        final end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case PeriodType.week:
        final startOfWeek =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek
            .add(const Duration(days: 7))
            .subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case PeriodType.month:
        final start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final end = DateTime(_selectedDate.year, _selectedDate.month + 1, 1)
            .subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
      case PeriodType.year:
        final start = DateTime(_selectedDate.year, 1, 1);
        final end = DateTime(_selectedDate.year + 1, 1, 1)
            .subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: start, end: end);
    }
  }

  void previousPeriod() {
    switch (_periodType) {
      case PeriodType.chooseDay:
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        break;
      case PeriodType.day:
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        break;
      case PeriodType.week:
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        break;
      case PeriodType.month:
        _selectedDate =
            DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
        break;
      case PeriodType.year:
        _selectedDate = DateTime(_selectedDate.year - 1, 1, 1);
        break;
      default:
        return;
    }
    notifyListeners();
  }

  String getFormattedPeriodLabel(BuildContext context) {
    switch (_periodType) {
      case PeriodType.chooseDay:
        return DateFormat('dd.MM.yyyy').format(_selectedDate);
      case PeriodType.allTime:
        return S.of(context).allTime;
      case PeriodType.day:
        return DateFormat('dd.MM.yyyy').format(_selectedDate);
      case PeriodType.week:
        return getCurrentWeekRange();
      case PeriodType.month:
        return DateFormat('LLLL yyyy', 'ru').format(_selectedDate);
      case PeriodType.year:
        return _selectedDate.year.toString();
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

  String getCurrentWeekRange() {
    final date = _selectedDate;
    final weekday = date.weekday;

    final startOfWeek = date.subtract(Duration(days: weekday - 1));
    final endOfWeek = date.add(Duration(days: 7 - weekday));

    final formatter = DateFormat('dd.MM');
    return '${formatter.format(startOfWeek)} - ${formatter.format(endOfWeek)}';
  }

  void setDate(DateTime newDate) {
    _selectedDate = newDate;
    notifyListeners();
  }

  Future<double> getCategorySum({
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    Query query = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('operations')
        .where('categoryId', isEqualTo: categoryId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    final querySnapshot = await query.get();

    double sum = 0.0;
    for (final doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue; // На всякий случай
      final amount = data['amount'];
      if (amount is num) {
        sum += amount.toDouble();
      }
    }

    return sum;
  }
}
