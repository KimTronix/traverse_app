import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/icon_standards.dart';
import '../providers/statistics_provider.dart';
import '../services/reports_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String selectedPeriod = 'Last 30 Days';
  final List<String> periods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last Year',
    'All Time'
  ];
  final ReportsService _reportsService = ReportsService.instance;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StatisticsProvider>(context, listen: false);
      provider.loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(IconStandards.getUIIcon('download')),
            onPressed: () => _exportReport('JSON'),
          ),
        ],
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconStandards.getUIIcon('error_outline'), size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                     onPressed: () {
                       provider.loadStatistics();
                     },
                     child: const Text('Retry'),
                   ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.lgSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: AppConstants.lgSpacing),
                _buildSummaryCards(provider),
                const SizedBox(height: AppConstants.lgSpacing),
                _buildVisitsReport(provider),
                const SizedBox(height: AppConstants.lgSpacing),
                _buildPlacesReport(provider),
                const SizedBox(height: AppConstants.lgSpacing),
                _buildServiceProvidersReport(provider),
                const SizedBox(height: AppConstants.lgSpacing),
                _buildExportSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            IconStandards.getUIIcon('date_range'),
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: AppConstants.smSpacing),
          const Text(
            'Period:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: AppConstants.mdSpacing),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPeriod,
                items: periods.map((String period) {
                  return DropdownMenuItem<String>(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedPeriod = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(StatisticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.mdSpacing),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Visits',
                provider.totalVisits.toString(),
                '+12.5%',
                IconStandards.getUIIcon('visibility'),
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppConstants.mdSpacing),
            Expanded(
              child: _buildSummaryCard(
                'Active Users',
                provider.totalActiveUsers.toString(),
                '+8.3%',
                IconStandards.getUIIcon('person_add'),
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.mdSpacing),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Places',
                provider.totalRegisteredPlaces.toString(),
                '+15.2%',
                IconStandards.getUIIcon('place'),
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppConstants.mdSpacing),
            Expanded(
              child: _buildSummaryCard(
                'Providers',
                provider.totalServiceProviders.toString(),
                '+6.7%',
                IconStandards.getUIIcon('business'),
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.mdSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: color,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsReport(StatisticsProvider provider) {
    return _buildReportCard(
      'Top Visited Destinations',
  IconStandards.getUIIcon('location'),
      provider.topDestinations.map((destination) => _buildDataRow(
         destination['name'] ?? 'Unknown',
         '${destination['visit_count'] ?? 0} visits',
         '${(destination['rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
       )).toList(),
    );
  }

  Widget _buildPlacesReport(StatisticsProvider provider) {
    return _buildReportCard(
      'Top Rated Places',
  IconStandards.getUIIcon('star'),
      provider.allRegisteredPlaces.take(5).map((place) => _buildDataRow(
        place['name'] ?? 'Unknown Place',
        place['category'] ?? 'Unknown',
        '${(place['rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
      )).toList(),
    );
  }

  Widget _buildServiceProvidersReport(StatisticsProvider provider) {
    return _buildReportCard(
      'Top Service Providers',
  IconStandards.getUIIcon('business'),
      provider.serviceProviders.take(5).map((serviceProvider) => _buildDataRow(
        serviceProvider['name'] ?? 'Unknown Provider',
        serviceProvider['category'] ?? 'Unknown',
        '${(serviceProvider['rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
      )).toList(),
    );
  }

  Widget _buildReportCard(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.lgSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: AppConstants.smSpacing),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.mdSpacing),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String title, String subtitle, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smSpacing),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
               children: [
                 Icon(IconStandards.getUIIcon('file_download'), color: Colors.blue),
                 const SizedBox(width: 8),
                 Text(
                   'Export Report',
                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ],
             ),
            const SizedBox(height: AppConstants.mdSpacing),
            Text(
              'Export current report data in various formats',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.lgSpacing),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportReport('JSON'),
                    icon: Icon(IconStandards.getUIIcon('code')),
                    label: const Text('Export as JSON'),
                    style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.blue,
                     ),
                  ),
                ),
                const SizedBox(width: AppConstants.mdSpacing),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportReport('CSV'),
                    icon: Icon(IconStandards.getUIIcon('table_chart')),
                    label: const Text('Export as CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            if (_isExporting) ...[
              const SizedBox(height: AppConstants.mdSpacing),
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Generating report...'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport(String format) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final provider = Provider.of<StatisticsProvider>(context, listen: false);
      
      // Generate comprehensive report
      final periodDates = _reportsService.calculatePeriodDates(selectedPeriod);
         final report = await _reportsService.generateComprehensiveReport(
           period: selectedPeriod,
        startDate: periodDates['start_date'],
        endDate: periodDates['end_date'],
      );

      String filePath;
      String fileName;

      if (format == 'JSON') {
        filePath = await _reportsService.exportReportAsJson(report);
        fileName = 'traverse_report_${DateTime.now().millisecondsSinceEpoch}.json';
      } else {
        filePath = await _reportsService.exportReportAsCsv(report);
        fileName = 'traverse_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      }

      // Share the report
      await _reportsService.shareReport(filePath, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported successfully as $format'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}