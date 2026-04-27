import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/report_provider.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ReportProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    if (report.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => report.loadReports(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with Export Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reports Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => ExportService.exportReportsToExcel(report),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Revenue Summary Cards
          Row(
            children: [
              _SummaryCard(
                title: 'Today',
                value: currencyFormat.format(report.todayRevenue),
                orders: '${report.todayOrders} orders',
                color: const Color(0xFFD4A574),
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                title: 'This Week',
                value: currencyFormat.format(report.weekRevenue),
                orders: '7-day total',
                color: const Color(0xFF8B6F47),
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                title: 'Month',
                value: currencyFormat.format(report.monthRevenue),
                orders: 'MTD total',
                color: const Color(0xFF5C4033),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Revenue Chart
          Text(
            'Revenue (Last 7 Days)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              borderRadius: BorderRadius.circular(20),
            ),
            child: report.dailyRevenue.isEmpty
                ? Center(
                    child: Text(
                      'No sales data yet',
                      style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMax(report.dailyRevenue, 'revenue') * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                            currencyFormat.format(rod.toY),
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox();
                              return Text(
                                '₹${(value / 1000).toStringAsFixed(1)}k',
                                style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withAlpha(150)),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < report.dailyRevenue.length) {
                                final day = report.dailyRevenue[idx]['day'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    day.substring(5),
                                    style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withAlpha(150)),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: colorScheme.onSurface.withAlpha(30), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(report.dailyRevenue.length, (i) {
                        final rev = (report.dailyRevenue[i]['revenue'] as num).toDouble();
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: rev,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD4A574), Color(0xFF8B6F47)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 28),

          // Peak Hours Chart (Sprint 4)
          Text(
            'Peak Hours (Last 30 Days)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders by hour of day',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(120)),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              borderRadius: BorderRadius.circular(20),
            ),
            child: report.peakHourData.isEmpty ||
                    report.peakHourData.every((h) => (h['count'] as int) == 0)
                ? Center(
                    child: Text(
                      'No data yet — orders will appear here',
                      style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (_getMaxPeak(report.peakHourData) * 1.3).toDouble(),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final hour = report.peakHourData[groupIndex]['hour'] as int;
                            final label = hour == 0
                                ? '12am'
                                : hour < 12
                                    ? '${hour}am'
                                    : hour == 12
                                        ? '12pm'
                                        : '${hour - 12}pm';
                            return BarTooltipItem(
                              '$label\n${rod.toY.toInt()} orders',
                              const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final h = value.toInt();
                              if (h % 4 != 0) return const SizedBox();
                              final label = h == 0
                                  ? '12a'
                                  : h < 12
                                      ? '${h}a'
                                      : h == 12
                                          ? '12p'
                                          : '${h - 12}p';
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  label,
                                  style: TextStyle(fontSize: 9, color: colorScheme.onSurface.withAlpha(150)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(report.peakHourData.length, (i) {
                        final count = (report.peakHourData[i]['count'] as int).toDouble();
                        final maxCount = _getMaxPeak(report.peakHourData).toDouble();
                        final ratio = maxCount > 0 ? count / maxCount : 0.0;
                        final barColor = Color.lerp(
                          const Color(0xFF5C4033),
                          const Color(0xFFD4A574),
                          ratio,
                        )!;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: count,
                              width: 8,
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 28),

          // Top Selling Items
          Text(
            'Top Selling Items',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (report.topItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Place some orders to see top items',
                  style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
                ),
              ),
            )
          else
            ...report.topItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final totalQty = (item['totalQty'] as num).toInt();
              final totalRev = (item['totalRevenue'] as num).toDouble();
              final medals = ['🥇', '🥈', '🥉', '4.', '5.'];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(medals[i], style: const TextStyle(fontSize: 24)),
                  title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$totalQty sold'),
                  trailing: Text(
                    currencyFormat.format(totalRev),
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                ),
              );
            }),
          const SizedBox(height: 28),

          // Category Breakdown
          if (report.categoryBreakdown.isNotEmpty) ...[
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: _buildPieSections(report.categoryBreakdown),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: report.categoryBreakdown.asMap().entries.map((entry) {
                      final color = _pieColors[entry.key % _pieColors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(entry.value['category'] as String,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  double _getMax(List<Map<String, dynamic>> data, String key) {
    if (data.isEmpty) return 1000;
    return data.map((d) => (d[key] as num).toDouble()).reduce((a, b) => a > b ? a : b);
  }

  int _getMaxPeak(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 1;
    return data.map((d) => (d['count'] as int)).reduce((a, b) => a > b ? a : b);
  }

  static const _pieColors = [
    Color(0xFFD4A574),
    Color(0xFF8B6F47),
    Color(0xFF5C4033),
    Color(0xFF3E2723),
    Color(0xFFB8860B),
  ];

  List<PieChartSectionData> _buildPieSections(List<Map<String, dynamic>> data) {
    final total = data.fold<double>(0, (sum, d) => sum + (d['totalRevenue'] as num).toDouble());
    return data.asMap().entries.map((entry) {
      final rev = (entry.value['totalRevenue'] as num).toDouble();
      final pct = total > 0 ? (rev / total * 100) : 0.0;
      return PieChartSectionData(
        value: rev,
        title: '${pct.toStringAsFixed(0)}%',
        color: _pieColors[entry.key % _pieColors.length],
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String orders;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.orders, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 11, color: color)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ),
            const SizedBox(height: 2),
            Text(orders, style: TextStyle(fontSize: 10, color: color.withAlpha(180))),
          ],
        ),
      ),
    );
  }
}
