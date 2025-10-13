import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/core/domain/intl/generated/l10n.dart';
import 'package:finance_tracker/core/presentation/button/custom_chip.dart';
import 'package:finance_tracker/features/settings/domain/service/settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../categories/presentation/page/categorie_vm.dart';

class AnalyticsPage extends StatefulWidget {
  final SettingsService settingsService;
  final CategoryViewModel vm;
  const AnalyticsPage(
      {super.key, required this.vm, required this.settingsService});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedType = 'expense';
  final List<Color> pieColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.yellow,
    Colors.pink,
    Colors.brown,
  ];
  @override
  Widget build(BuildContext context) {
    final categoryVM = context.watch<CategoryViewModel>();
    final range = categoryVM.getCurrentDateRange();

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
                    widget.vm.previousPeriod();
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
                    widget.vm.nextPeriod();
                  },
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Operations')
                  .where('type', isEqualTo: _selectedType)
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Нет данных для аналитики"));
                }

                final docs = snapshot.data!.docs;

                // 🔹 фильтрация по периоду
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
                  return const Center(
                      child: Text("Нет операций за выбранный период"));
                }

                // 🔹 группировка по категориям
                final Map<String, double> sumsByCategory = {};
                // 🔹 группировка по дням
                final Map<String, double> sumsByDate = {};

                for (var doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data['categoryName'] ?? "Без категории";
                  final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                  final date = (data['date'] as Timestamp).toDate();
                  final dateKey = DateFormat('dd.MM').format(date);

                  sumsByCategory[category] =
                      (sumsByCategory[category] ?? 0) + amount;
                  sumsByDate[dateKey] = (sumsByDate[dateKey] ?? 0) + amount;
                }
                int colorIndex = 0;
                // 🔹 PieChart для категорий
                final categories = sumsByCategory.entries.toList();
                final pieSections = sumsByCategory.entries.map((entry) {
                  final color = pieColors[colorIndex % pieColors.length];
                  colorIndex++;
                  return PieChartSectionData(
                    value: entry.value,
                    color: color,
                    //title: "${entry.key}\n${entry.value.toStringAsFixed(0)}₽",
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList();

                // 🔹 LineChart для суммы по дням
                final lineSpots = sumsByDate.entries.toList()
                  ..sort((a, b) => DateFormat('dd.MM')
                      .parse(a.key)
                      .compareTo(DateFormat('dd.MM').parse(b.key)));

                final spots = lineSpots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value.value;
                  return FlSpot(index.toDouble(), value);
                }).toList();
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _incomeExpense(context),

                      const SizedBox(height: 16),
                      Text(
                        "Расходы по категориям",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      // сам PieChart
                      SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sections: pieSections,
                            sectionsSpace: 5,
                            centerSpaceRadius: 15,
                          ),
                        ),
                      ),

                      // ===== ЛЕГЕНДА =====
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: List.generate(categories.length, (i) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: pieColors[i % pieColors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                categories[i].key, // 👈 имя категории
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          );
                        }),
                      ),

                      const SizedBox(height: 32),
                      Text(
                        "Динамика операций по дням",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

// Линейный график со скроллом
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width:
                              spots.length * 100, // ширина под количество точек
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: Colors.blue,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: false), // убрали верхнюю ось
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: false), // убрали правую ось
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      reservedSize: 50,
                                      showTitles:
                                          true), // оставили слева (суммы)
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= lineSpots.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        lineSpots[index]
                                            .key, // твоя дата в формате "dd.MM"
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
                  widget.vm.selectPeriod(PeriodType.allTime);
                  Navigator.of(context).pop();
                },
              ),
              CustomChip(
                label: S.of(context).chooseDay,
                icon: Icons.calendar_today,
                onPressed: () {
                  _showDatePicker(context);
                  widget.vm.selectPeriod(PeriodType.chooseDay);
                },
              ),
              CustomChip(
                label: S.of(context).weekRange(widget.vm.getCurrentWeekRange()),
                icon: Icons.date_range,
                onPressed: () {
                  widget.vm.selectPeriod(PeriodType.week);
                  Navigator.of(context).pop();
                },
              ),
              CustomChip(
                label: S
                    .of(context)
                    .today(DateFormat('dd.MM').format(DateTime.now())),
                icon: Icons.today,
                onPressed: () {
                  widget.vm.selectPeriod(PeriodType.day);
                  Navigator.of(context).pop();
                },
              ),
              CustomChip(
                label: S.of(context).year(DateTime.now().year),
                icon: Icons.calendar_month,
                onPressed: () {
                  widget.vm.selectPeriod(PeriodType.year);
                  Navigator.of(context).pop();
                },
              ),
              CustomChip(
                label: S.of(context).month(
                    DateFormat('LLLL yyyy', 'ru').format(DateTime.now())),
                icon: Icons.calendar_view_month,
                onPressed: () {
                  widget.vm.selectPeriod(PeriodType.month);
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
        widget.vm.setDate(value);
      }
    });
  }
}
