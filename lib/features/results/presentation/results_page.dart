import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/scan_result.dart';
import '../../../services/prediction_service.dart';
import '../../../services/results_service.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _resultsService = ResultsService();
  Timer? _debounce;
  List<ScanResult> _results = [];
  List<String> _diseases = const [
    'Bacterial_spot',
    'Cercospora_Leaf_Spot',
    'Curl_Virus',
    'Healthy_Leaf',
    'Nutrition_Deficiency',
    'White_Spot'
  ];
  String _filterType = 'All';
  String? _selectedDisease;
  DateTime? _selectedDate;
  int? _selectedYear;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _total = 0;
  int _page = 1;
  String? _error;
  int _requestSequence = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchChanged);
    _scrollController.addListener(_scrollChanged);
    _loadResults();
    PredictionService().classes().then((classes) {
      if (mounted && classes.isNotEmpty) setState(() => _diseases = classes);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _searchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadResults);
    setState(() {});
  }

  void _scrollChanged() {
    if (_scrollController.position.extentAfter < 240 &&
        _hasMore &&
        !_loadingMore &&
        !_loading) {
      _loadResults(reset: false);
    }
  }

  Future<void> _loadResults({bool reset = true}) async {
    final request = ++_requestSequence;
    if (mounted) {
      setState(() {
        if (reset) _loading = true;
        _loadingMore = !reset;
        _error = null;
      });
    }
    final nextPage = reset ? 1 : _page + 1;
    try {
      final data = await _resultsService.list(
        page: nextPage,
        search: _searchController.text,
        disease: _filterType == 'Disease' ? _selectedDisease : null,
        date: _filterType == 'Date' ? _selectedDate : null,
        year: _filterType == 'Year' ? _selectedYear : null,
      );
      if (!mounted || request != _requestSequence) return;
      setState(() {
        _results = reset ? data.items : [..._results, ...data.items];
        _total = data.total;
        _page = data.page;
        _hasMore = data.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || request != _requestSequence) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = error.toString();
      });
    }
  }

  String _displayDisease(String disease) => disease.replaceAll('_', ' ');

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Time unavailable';
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _setFilter(String type, {String? disease, DateTime? date, int? year}) {
    setState(() {
      _filterType = type;
      _selectedDisease = disease;
      _selectedDate = date;
      _selectedYear = year;
    });
    _loadResults();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? now,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (selected != null) _setFilter('Date', date: selected);
  }

  Future<void> _selectYear() async {
    final currentYear = DateTime.now().year;
    final years =
        List.generate(currentYear - 2019, (index) => currentYear - index);
    final year = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Year'),
        content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
                children: years
                    .map((year) => ListTile(
                        title: Text('$year'),
                        onTap: () => Navigator.pop(context, year)))
                    .toList())),
      ),
    );
    if (year != null) _setFilter('Year', year: year);
  }

  Future<void> _selectDisease() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
                title: Text('Select Disease',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            ..._diseases.map((disease) => ListTile(
                leading: const Icon(Icons.eco, color: Colors.green),
                title: Text(_displayDisease(disease)),
                onTap: () => Navigator.pop(context, disease))),
          ],
        ),
      ),
    );
    if (selected != null) _setFilter('Disease', disease: selected);
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                  leading: const Icon(Icons.grid_view),
                  title: const Text('All results'),
                  onTap: () {
                    Navigator.pop(context);
                    _setFilter('All');
                  }),
              ListTile(
                  leading: const Icon(Icons.local_florist),
                  title: const Text('Disease type'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectDisease();
                  }),
              ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Specific date'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectDate();
                  }),
              ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Year'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectYear();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(ScanResult item) async {
    try {
      final result = await _resultsService.detail(item.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_displayDisease(result.disease)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confidence: ${result.confidence.toStringAsFixed(2)}%'),
              const SizedBox(height: 8),
              Text(
                  'Scanned: ${_formatDate(result.createdAt)} at ${_formatTime(result.createdAt)}'),
              const SizedBox(height: 8),
              Text(result.isHealthy
                  ? 'Classification: Healthy leaf'
                  : 'Classification: Possible disease'),
              const SizedBox(height: 8),
              Text('Validation: ${result.validationStatus}'),
              Text('Model: ${result.modelVersion}'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Widget _chip(String label, String type, VoidCallback onTap) {
    final active = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        onPressed: onTap,
        label: Text(label),
        backgroundColor: active ? Colors.green : Colors.grey.shade100,
        labelStyle: TextStyle(
            color: active ? Colors.white : Colors.grey.shade800,
            fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    );
  }

  Widget _resultCard(ScanResult item) {
    final isHealthy = item.isHealthy;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _openDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: Icon(isHealthy ? Icons.eco : Icons.local_florist,
                          color: Colors.green.shade700)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(_displayDisease(item.disease),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold))),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 14),
              _metadataRow(Icons.track_changes, 'Accuracy',
                  '${item.confidence.toStringAsFixed(2)}%',
                  valueColor: Colors.green.shade700),
              const SizedBox(height: 8),
              _metadataRow(Icons.calendar_today_outlined, 'Date',
                  _formatDate(item.createdAt)),
              const SizedBox(height: 8),
              _metadataRow(
                  Icons.access_time, 'Time', _formatTime(item.createdAt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metadataRow(IconData icon, String label, String value,
          {Color? valueColor}) =>
      Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 9),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Padding(
          padding: EdgeInsets.fromLTRB(constraints.maxWidth < 360 ? 14 : 20, 15,
              constraints.maxWidth < 360 ? 14 : 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📋 Scan Results',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text('Your recent leaf scans',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search disease or date',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _searchController.clear),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox.square(
                    dimension: 50,
                    child: IconButton.filled(
                        onPressed: _showFilters,
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        icon: const Icon(Icons.tune)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _chip('🗂 All', 'All', () => _setFilter('All')),
                  _chip('📅 Date', 'Date', _selectDate),
                  _chip('🌿 Type', 'Disease', _selectDisease),
                  _chip('📆 Year', 'Year', _selectYear),
                ]),
              ),
              if (_filterType != 'All') ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.filter_alt_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_filterType == 'Disease'
                            ? _displayDisease(_selectedDisease ?? '')
                            : _filterType == 'Date'
                                ? _formatDate(_selectedDate)
                                : '$_selectedYear')),
                    GestureDetector(
                        onTap: () => _setFilter('All'),
                        child: const Icon(Icons.close, size: 18))
                  ]),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(child: _buildResultsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _results.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _loadResults, child: const Text('Retry'))
      ]));
    }
    if (_results.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
            _searchController.text.isEmpty && _filterType == 'All'
                ? Icons.history
                : Icons.search_off,
            size: 60,
            color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
            _searchController.text.isEmpty && _filterType == 'All'
                ? 'No scan results yet'
                : 'No matching results',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Your scan results will appear here.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
      ]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_total Results',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _results.length + (_hasMore || _loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _results.length) {
                return const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()));
              }
              return _resultCard(_results[index]);
            },
          ),
        ),
      ],
    );
  }
}
