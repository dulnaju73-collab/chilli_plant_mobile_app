import '../core/network/api_client.dart';
import '../models/scan_result.dart';

class ResultsService {
  ResultsService({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  Future<ResultsPageData> list(
      {int page = 1,
      int pageSize = 20,
      String? search,
      String? disease,
      DateTime? date,
      int? year}) async {
    final query = <String, String>{'page': '$page', 'page_size': '$pageSize'};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (disease != null && disease.isNotEmpty) query['disease'] = disease;
    if (date != null) {
      query['date'] =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    if (year != null) query['year'] = '$year';
    query['timezone_offset_minutes'] =
        (date?.timeZoneOffset ?? DateTime.now().timeZoneOffset)
            .inMinutes
            .toString();
    return ResultsPageData.fromJson(
        await _client.get('/results', query: query));
  }

  Future<ScanResult> detail(String id) async => ScanResult.fromJson(
      await _client.get('/results/${Uri.encodeComponent(id)}'));

  Future<void> delete(String id) =>
      _client.delete('/results/${Uri.encodeComponent(id)}');
}
