import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// Add this import
import 'statistics_service.dart';

class ReportsService {
  static final ReportsService _instance = ReportsService._internal();
  factory ReportsService() => _instance;
  ReportsService._internal();

  static ReportsService get instance => _instance;

  final StatisticsService _statisticsService = StatisticsService.instance;

  // Generate comprehensive report
  Future<Map<String, dynamic>> generateComprehensiveReport({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final report = {
        'metadata': {
          'generated_at': DateTime.now().toIso8601String(),
          'period': period,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
        'summary': {
          'total_visits': await _statisticsService.getTotalVisits(),
          'total_registered_places': await _statisticsService.getTotalRegisteredPlaces(),
          'total_active_users': await _statisticsService.getTotalActiveUsers(),
          'total_service_providers': await _statisticsService.getTotalServiceProviders(),
        },
        'charts_data': {
          'daily_visits': await _statisticsService.getDailyVisits(),
          'user_growth': await _statisticsService.getUserGrowth(),
          'places_by_category': await _statisticsService.getPlacesByCategory(),
        },
        'top_lists': {
          'top_destinations': await _statisticsService.getTopDestinations(),
          'all_registered_places': await _statisticsService.getAllRegisteredPlaces(),
          'service_providers': await _statisticsService.getServiceProvidersByCategory(),
        },
      };

      return report;
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  // Export report as JSON
  Future<String> exportReportAsJson(Map<String, dynamic> report) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'traverse_report_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(report);
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export report as JSON: $e');
    }
  }

  // Export report as CSV
  Future<String> exportReportAsCsv(Map<String, dynamic> report) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'traverse_report_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      
      final csvContent = _generateCsvContent(report);
      await file.writeAsString(csvContent);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export report as CSV: $e');
    }
  }

  // Generate CSV content from report data
  String _generateCsvContent(Map<String, dynamic> report) {
    final buffer = StringBuffer();
    
    // Add metadata
    buffer.writeln('Traverse App Analytics Report');
    buffer.writeln('Generated at,${report['metadata']['generated_at']}');
    buffer.writeln('Period,${report['metadata']['period']}');
    buffer.writeln('');
    
    // Add summary statistics
    buffer.writeln('Summary Statistics');
    buffer.writeln('Metric,Value');
    final summary = report['summary'] as Map<String, dynamic>;
    summary.forEach((key, value) {
      buffer.writeln('$key,$value');
    });
    buffer.writeln('');
    
    // Add top destinations
    buffer.writeln('Top Destinations');
    buffer.writeln('Name,Visit Count,Rating');
    final topDestinations = report['top_lists']['top_destinations'] as List;
    for (final destination in topDestinations) {
      buffer.writeln('${destination['name']},${destination['visit_count']},${destination['rating']}');
    }
    buffer.writeln('');
    
    // Add registered places
    buffer.writeln('Registered Places');
    buffer.writeln('Name,Category,Rating');
    final places = report['top_lists']['all_registered_places'] as List;
    for (final place in places) {
      buffer.writeln('${place['name']},${place['category']},${place['rating']}');
    }
    buffer.writeln('');
    
    // Add service providers
    buffer.writeln('Service Providers');
    buffer.writeln('Name,Category,Rating');
    final providers = report['top_lists']['service_providers'] as List;
    for (final provider in providers) {
      buffer.writeln('${provider['name']},${provider['category']},${provider['rating']}');
    }
    
    return buffer.toString();
  }

  // Share report file
  Future<void> shareReport(String filePath, String fileName) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Traverse App Analytics Report - $fileName',
        subject: 'Analytics Report',
      );
    } catch (e) {
      throw Exception('Failed to share report: $e');
    }
  }

  // Get available export formats
  List<String> getAvailableFormats() {
    return ['JSON', 'CSV'];
  }

  // Get available report periods
  List<String> getAvailablePeriods() {
    return [
      'Today',
      'This Week',
      'This Month',
      'Last Month',
      'This Year',
      'Custom Range'
    ];
  }

  // Calculate period dates
  Map<String, DateTime?> calculatePeriodDates(String period) {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        // Custom Range - will be handled separately
        break;
    }

    return {
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}