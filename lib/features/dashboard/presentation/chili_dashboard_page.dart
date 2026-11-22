import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/layout/responsive_page.dart';
import '../../../models/scan_result.dart';
import '../../../services/results_service.dart';

class ChiliDashboardPage extends StatefulWidget {
  const ChiliDashboardPage({super.key});

  @override
  State<ChiliDashboardPage> createState() => _ChiliDashboardPageState();
}

class _ChiliDashboardPageState extends State<ChiliDashboardPage> {
  String _period = 'All Time';
  String _diseaseFilter = 'All Diseases';

  final List<String> _periods = ['All Time', '7 Days', '30 Days', '90 Days'];
  final ResultsService _resultsService = ResultsService();
  late Future<List<ScanResult>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _fetchAllResults();
  }

  Future<List<ScanResult>> _fetchAllResults() async {
    final records = <ScanResult>[];
    var page = 1;
    var hasMore = true;
    while (hasMore) {
      final response = await _resultsService.list(page: page, pageSize: 100);
      records.addAll(response.items);
      hasMore = response.hasMore;
      page++;
    }
    return records;
  }

  Future<void> _refreshResults() async {
    final next = _fetchAllResults();
    setState(() => _resultsFuture = next);
    await next;
  }

  String _formatDiseaseName(String disease) {
    return disease
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  bool _isWithinPeriod(DateTime date) {
    final now = DateTime.now();

    if (_period == 'All Time') {
      return true;
    }

    final days = _period == '7 Days'
        ? 7
        : _period == '30 Days'
            ? 30
            : 90;

    final startDate = now.subtract(Duration(days: days));

    return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
  }

  List<Map<String, dynamic>> _prepareData(List<ScanResult> documents) {
    final List<Map<String, dynamic>> results = [];

    for (final document in documents) {
      final disease = document.disease;
      final accuracy = document.confidence;
      final dateTime = document.createdAt;

      if (dateTime == null) {
        continue;
      }

      if (!_isWithinPeriod(dateTime)) {
        continue;
      }

      if (_diseaseFilter != 'All Diseases' && disease != _diseaseFilter) {
        continue;
      }

      results.add({
        'disease': disease,
        'accuracy': accuracy,
        'dateTime': dateTime,
      });
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌶️ Chilli Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Scan insights & prediction overview',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshResults,
          ),
        ],
      ),
      body: ResponsivePage(
        maxContentWidth: 1100,
        child: FutureBuilder<List<ScanResult>>(
          future: _resultsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorDashboard(snapshot.error.toString());
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final documents = snapshot.data ?? [];

            final allDiseases =
                documents.map((document) => document.disease).toSet().toList();

            allDiseases.sort();

            final results = _prepareData(documents);

            return RefreshIndicator(
              onRefresh: _refreshResults,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilterSection(allDiseases),
                  const SizedBox(height: 16),
                  if (results.isEmpty)
                    _buildEmptyDashboard()
                  else ...[
                    _buildPredictionSummary(results),
                    const SizedBox(height: 16),
                    _buildConfidenceTrend(results),
                    const SizedBox(height: 16),
                    _buildConfidenceDistribution(results),
                    const SizedBox(height: 16),
                    _buildDiseaseActivity(results),
                    const SizedBox(height: 16),
                    _buildHeatmap(results),
                    const SizedBox(height: 16),
                    _buildTopPrediction(results),
                    const SizedBox(height: 16),
                    _buildSmartInsight(results),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // FILTER SECTION
  // ============================================================

  Widget _buildFilterSection(List<String> diseases) {
    final screenWidth = MediaQuery.of(context).size.width;

    final periodDropdown = DropdownButtonFormField<String>(
      initialValue: _period,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Period',
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: _periods.map((period) {
        return DropdownMenuItem<String>(
          value: period,
          child: Text(period, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _period = value;
        });
      },
    );

    final diseaseDropdown = DropdownButtonFormField<String>(
      initialValue: _diseaseFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Disease',
        prefixIcon: const Icon(Icons.local_florist_outlined),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: 'All Diseases',
          child: Text('All Diseases', overflow: TextOverflow.ellipsis),
        ),
        ...diseases.map(
          (disease) => DropdownMenuItem<String>(
            value: disease,
            child: Text(
              _formatDiseaseName(disease),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _diseaseFilter = value;
        });
      },
    );

    return _analyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interactive Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Filter your chilli scan statistics',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (screenWidth < 500)
            Column(
              children: [
                periodDropdown,
                const SizedBox(height: 12),
                diseaseDropdown,
              ],
            )
          else
            Row(
              children: [
                Expanded(child: periodDropdown),
                const SizedBox(width: 12),
                Expanded(child: diseaseDropdown),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PREDICTION SUMMARY
  // ============================================================

  Widget _buildPredictionSummary(List<Map<String, dynamic>> results) {
    final totalScans = results.length;

    final averageConfidence = results.isEmpty
        ? 0.0
        : results
                .map((item) => item['accuracy'] as double)
                .reduce((a, b) => a + b) /
            results.length;

    final healthyCount = results.where((item) {
      return item['disease'] == 'Healthy_Leaf';
    }).length;

    final diseaseCount = totalScans - healthyCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Prediction Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // --------------------------------------------------------
        // FIXED GRID
        // --------------------------------------------------------
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,

          // Increased card height.
          // This fixes the "Bottom overflowed by 19 pixels".
          childAspectRatio: 1.05,

          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          children: [
            _statCard(
              icon: Icons.document_scanner_outlined,
              title: 'Total Scans',
              value: totalScans.toString(),
              subtitle: 'All predictions',
              iconColor: Colors.blue.shade600,
              backgroundColor: Colors.blue.shade50,
            ),
            _statCard(
              icon: Icons.verified_outlined,
              title: 'Avg. Confidence',
              value: '${averageConfidence.toStringAsFixed(1)}%',
              subtitle: 'Model confidence',
              iconColor: Colors.green.shade600,
              backgroundColor: Colors.green.shade50,
            ),
            _statCard(
              icon: Icons.eco_outlined,
              title: 'Healthy',
              value: healthyCount.toString(),
              subtitle: 'Healthy leaves',
              iconColor: Colors.teal.shade600,
              backgroundColor: Colors.teal.shade50,
            ),
            _statCard(
              icon: Icons.warning_amber_outlined,
              title: 'Diseases',
              value: diseaseCount.toString(),
              subtitle: 'Detected cases',
              iconColor: Colors.orange.shade700,
              backgroundColor: Colors.orange.shade50,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIDENCE TREND
  // ============================================================

  Widget _buildConfidenceTrend(List<Map<String, dynamic>> results) {
    final sortedResults = [...results];

    sortedResults.sort(
      (a, b) =>
          (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime),
    );

    final values =
        sortedResults.map((item) => item['accuracy'] as double).toList();

    final displayValues =
        values.length > 12 ? values.sublist(values.length - 12) : values;

    return _analyticsCard(
      title: 'Confidence Trend',
      subtitle: 'Prediction confidence over recent scans',
      child: SizedBox(
        height: 220,
        child: CustomPaint(
          painter: _ConfidenceTrendPainter(displayValues),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  // ============================================================
  // CONFIDENCE DISTRIBUTION
  // ============================================================

  Widget _buildConfidenceDistribution(List<Map<String, dynamic>> results) {
    final high =
        results.where((item) => (item['accuracy'] as double) >= 90).length;

    final medium = results
        .where(
          (item) =>
              (item['accuracy'] as double) >= 70 &&
              (item['accuracy'] as double) < 90,
        )
        .length;

    final low =
        results.where((item) => (item['accuracy'] as double) < 70).length;

    final total = results.length;

    return _analyticsCard(
      title: 'Confidence Distribution',
      subtitle: 'Prediction confidence levels',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 370;

          final donutSize = isNarrow ? 125.0 : 150.0;

          final legend = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendItem('High', high, Colors.green.shade600),
              const SizedBox(height: 12),
              _legendItem('Medium', medium, Colors.orange.shade600),
              const SizedBox(height: 12),
              _legendItem('Low', low, Colors.red.shade600),
            ],
          );

          if (isNarrow) {
            return Column(
              children: [
                SizedBox(
                  width: donutSize,
                  height: donutSize,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      high: high,
                      medium: medium,
                      low: low,
                    ),
                    child: Center(
                      child: Text(
                        '$total\nScans',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                legend,
              ],
            );
          }

          return Row(
            children: [
              SizedBox(
                width: donutSize,
                height: donutSize,
                child: CustomPaint(
                  painter: _DonutPainter(high: high, medium: medium, low: low),
                  child: Center(
                    child: Text(
                      '$total\nScans',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }

  Widget _legendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // ============================================================
  // DISEASE ACTIVITY
  // ============================================================

  Widget _buildDiseaseActivity(List<Map<String, dynamic>> results) {
    final Map<String, int> diseaseCounts = {};

    for (final result in results) {
      final disease = result['disease'] as String;

      diseaseCounts[disease] = (diseaseCounts[disease] ?? 0) + 1;
    }

    final sortedDiseases = diseaseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount = sortedDiseases.isEmpty ? 1 : sortedDiseases.first.value;

    final activityColors = [
      Colors.red.shade500,
      Colors.orange.shade600,
      Colors.blue.shade500,
      Colors.purple.shade500,
      Colors.teal.shade500,
      Colors.pink.shade500,
    ];

    return _analyticsCard(
      title: 'Disease Activity',
      subtitle: 'Number of predictions by disease type',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 380;

          return Column(
            children: [
              for (int index = 0; index < sortedDiseases.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == sortedDiseases.length - 1 ? 0 : 14,
                  ),
                  child: isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: activityColors[
                                        index % activityColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    _formatDiseaseName(
                                      sortedDiseases[index].key,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: activityColors[
                                            index % activityColors.length]
                                        .withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    sortedDiseases[index].value.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: activityColors[
                                          index % activityColors.length],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: sortedDiseases[index].value / maxCount,
                                minHeight: 12,
                                backgroundColor: Colors.grey.shade200,
                                color: activityColors[
                                    index % activityColors.length],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: activityColors[
                                          index % activityColors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      _formatDiseaseName(
                                        sortedDiseases[index].key,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: sortedDiseases[index].value / maxCount,
                                  minHeight: 12,
                                  backgroundColor: Colors.grey.shade200,
                                  color: activityColors[
                                      index % activityColors.length],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 30,
                              child: Text(
                                sortedDiseases[index].value.toString(),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // SCAN ACTIVITY HEATMAP
  // ============================================================

  Widget _buildHeatmap(List<Map<String, dynamic>> results) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final yesterday = today.subtract(const Duration(days: 1));

    final daysFromMonday = today.weekday - 1;

    final currentWeekMonday = today.subtract(Duration(days: daysFromMonday));

    final firstDay = currentWeekMonday.subtract(const Duration(days: 21));

    final Map<String, int> dailyCounts = {};

    for (final result in results) {
      final date = result['dateTime'] as DateTime;

      final dateOnly = DateTime(date.year, date.month, date.day);

      final key = _dateKey(dateOnly);

      dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
    }

    int maxCount = 0;

    for (final count in dailyCounts.values) {
      if (count > maxCount) {
        maxCount = count;
      }
    }

    if (maxCount == 0) {
      maxCount = 1;
    }

    final weekLabels = ['W1', 'W2', 'W3', 'W4'];

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _analyticsCard(
      title: '📅 Scan Activity Heatmap',
      subtitle: 'Daily scan records • Today & yesterday highlighted',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;

          final labelWidth = availableWidth < 350 ? 30.0 : 34.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(width: labelWidth),
                  for (final day in dayLabels)
                    Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: availableWidth < 350 ? 9 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (int week = 0; week < 4; week++)
                Padding(
                  padding: EdgeInsets.only(bottom: week == 3 ? 0 : 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          weekLabels[week],
                          style: TextStyle(
                            fontSize: availableWidth < 350 ? 9 : 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      for (int day = 0; day < 7; day++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.5,
                            ),
                            child: _buildHeatmapCell(
                              date: firstDay.add(
                                Duration(days: week * 7 + day),
                              ),
                              dailyCounts: dailyCounts,
                              maxCount: maxCount,
                              today: today,
                              yesterday: yesterday,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _heatmapLegendItem(
                    color: Colors.grey.shade200,
                    label: 'No scans',
                  ),
                  _heatmapLegendItem(
                    color: Colors.green.shade200,
                    label: 'Low',
                  ),
                  _heatmapLegendItem(
                    color: Colors.green.shade400,
                    label: 'Medium',
                  ),
                  _heatmapLegendItem(
                    color: Colors.green.shade700,
                    label: 'High',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // HEATMAP CELL
  // ============================================================

  Widget _buildHeatmapCell({
    required DateTime date,
    required Map<String, int> dailyCounts,
    required int maxCount,
    required DateTime today,
    required DateTime yesterday,
  }) {
    final key = _dateKey(date);

    final count = dailyCounts[key] ?? 0;

    final isToday = _sameDate(date, today);

    final isYesterday = _sameDate(date, yesterday);

    Color cellColor;

    if (count == 0) {
      cellColor = Colors.grey.shade200;
    } else if (maxCount <= 1) {
      cellColor = Colors.green.shade400;
    } else if (count <= maxCount * 0.25) {
      cellColor = Colors.green.shade200;
    } else if (count <= maxCount * 0.50) {
      cellColor = Colors.green.shade400;
    } else if (count <= maxCount * 0.75) {
      cellColor = Colors.green.shade600;
    } else {
      cellColor = Colors.green.shade800;
    }

    Color borderColor = Colors.transparent;

    double borderWidth = 0;

    if (isToday) {
      borderColor = Colors.green.shade900;
      borderWidth = 2.5;
    } else if (isYesterday) {
      borderColor = Colors.blue.shade700;
      borderWidth = 2;
    }

    return Tooltip(
      message: _heatmapTooltip(date, count, isToday, isYesterday),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: count == 0 ? Colors.grey.shade500 : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEATMAP TOOLTIP
  // ============================================================

  String _heatmapTooltip(
    DateTime date,
    int count,
    bool isToday,
    bool isYesterday,
  ) {
    final dateText = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    String status = '';

    if (isToday) {
      status = ' • Today';
    } else if (isYesterday) {
      status = ' • Yesterday';
    }

    return '$dateText$status • '
        '$count scan${count == 1 ? '' : 's'}';
  }

  // ============================================================
  // HEATMAP LEGEND
  // ============================================================

  Widget _heatmapLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ============================================================
  // DATE KEY
  // ============================================================

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // SAME DATE
  // ============================================================

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ============================================================
  // TOP PREDICTION
  // ============================================================

  Widget _buildTopPrediction(List<Map<String, dynamic>> results) {
    final Map<String, int> counts = {};

    for (final result in results) {
      final disease = result['disease'] as String;

      counts[disease] = (counts[disease] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    final topEntry = counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    final percentage = (topEntry.value / results.length) * 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.teal.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Prediction',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDiseaseName(topEntry.key),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${topEntry.value} scans • '
                  '${percentage.toStringAsFixed(1)}% of results',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMART INSIGHT
  // ============================================================

  Widget _buildSmartInsight(List<Map<String, dynamic>> results) {
    final healthyCount = results.where((item) {
      return item['disease'] == 'Healthy_Leaf';
    }).length;

    final diseaseCount = results.length - healthyCount;

    String message;
    IconData icon;
    Color color;

    if (results.isEmpty) {
      message = 'No scan data available.';
      icon = Icons.info_outline;
      color = Colors.blue;
    } else if (healthyCount > diseaseCount) {
      message = 'Most scanned chilli leaves appear healthy '
          'based on the current predictions.';
      icon = Icons.eco_outlined;
      color = Colors.green;
    } else if (diseaseCount > healthyCount) {
      message = 'Disease-related predictions are higher than '
          'healthy predictions in the selected data.';
      icon = Icons.warning_amber_outlined;
      color = Colors.orange;
    } else {
      message = 'Healthy and disease predictions are currently '
          'balanced.';
      icon = Icons.insights_outlined;
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Insight',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANALYTICS CARD
  // ============================================================

  Widget _analyticsCard({
    String? title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY DASHBOARD
  // ============================================================

  Widget _buildEmptyDashboard() {
    return Column(
      children: [
        const SizedBox(height: 50),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.analytics_outlined,
            size: 60,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No Analytics Data',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            'No scan results match the selected filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _period = 'All Time';
              _diseaseFilter = 'All Diseases';
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Reset Filters'),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR DASHBOARD
  // ============================================================

  Widget _buildErrorDashboard(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _refreshResults,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CONFIDENCE TREND PAINTER
// ================================================================

class _ConfidenceTrendPainter extends CustomPainter {
  final List<double> values;

  _ConfidenceTrendPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.green.shade600;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.shade200;

    for (int i = 0; i < 4; i++) {
      final y = (size.height / 3) * i;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) {
      return;
    }

    final path = Path();

    const minValue = 70.0;
    const maxValue = 100.0;

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i * size.width / (values.length - 1);

      final normalized = ((values[i] - minValue) / (maxValue - minValue)).clamp(
        0.0,
        1.0,
      );

      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = Colors.green.shade700;

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i * size.width / (values.length - 1);

      final normalized = ((values[i] - minValue) / (maxValue - minValue)).clamp(
        0.0,
        1.0,
      );

      final y = size.height - (normalized * size.height);

      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfidenceTrendPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

// ================================================================
// DONUT PAINTER
// ================================================================

class _DonutPainter extends CustomPainter {
  final int high;
  final int medium;
  final int low;

  _DonutPainter({required this.high, required this.medium, required this.low});

  @override
  void paint(Canvas canvas, Size size) {
    final total = high + medium + low;

    if (total == 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);

    final radius = min(size.width, size.height) / 2 - 8;

    const strokeWidth = 24.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final values = [high, medium, low];

    final colors = [
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.red.shade500,
    ];

    double startAngle = -pi / 2;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) {
        continue;
      }

      final sweepAngle = (values[i] / total) * 2 * pi;

      paint.color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.high != high ||
        oldDelegate.medium != medium ||
        oldDelegate.low != low;
  }
}
