import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';

class ReportProvider with ChangeNotifier {
  double _todayRevenue = 0;
  int _todayOrders = 0;
  double _weekRevenue = 0;
  double _monthRevenue = 0;
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _dailyRevenue = [];
  List<Map<String, dynamic>> _categoryBreakdown = [];
  List<Map<String, dynamic>> _peakHourData = [];
  bool _isLoading = false;

  double get todayRevenue => _todayRevenue;
  int get todayOrders => _todayOrders;
  double get weekRevenue => _weekRevenue;
  double get monthRevenue => _monthRevenue;
  List<Map<String, dynamic>> get topItems => _topItems;
  List<Map<String, dynamic>> get dailyRevenue => _dailyRevenue;
  List<Map<String, dynamic>> get categoryBreakdown => _categoryBreakdown;
  List<Map<String, dynamic>> get peakHourData => _peakHourData;
  bool get isLoading => _isLoading;

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final weekStart = todayStart.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);

      final db = FirebaseService.instance;

      final results = await Future.wait([
        db.getRevenueForDateRange(todayStart, todayEnd),
        db.getOrderCountForDateRange(todayStart, todayEnd),
        db.getRevenueForDateRange(weekStart, todayEnd),
        db.getRevenueForDateRange(monthStart, todayEnd),
        db.getTopSellingItems(),
        db.getDailyRevenue(7),
        db.getCategoryBreakdown(),
        db.getPeakHourData(),
      ]);

      _todayRevenue = results[0] as double;
      _todayOrders = results[1] as int;
      _weekRevenue = results[2] as double;
      _monthRevenue = results[3] as double;
      _topItems = results[4] as List<Map<String, dynamic>>;
      _dailyRevenue = results[5] as List<Map<String, dynamic>>;
      _categoryBreakdown = results[6] as List<Map<String, dynamic>>;
      _peakHourData = results[7] as List<Map<String, dynamic>>;
    } catch (e) {
      if (kDebugMode) print('Error loading reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
