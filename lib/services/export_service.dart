import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../providers/report_provider.dart';

class ExportService {
  static Future<void> exportReportsToExcel(ReportProvider report) async {
    try {
      var excel = Excel.createExcel();
      
      // Revenue Summary
      Sheet sheetObject = excel['Summary'];
      excel.setDefaultSheet('Summary');
      
      sheetObject.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
      sheetObject.appendRow([TextCellValue('Today Revenue'), DoubleCellValue(report.todayRevenue)]);
      sheetObject.appendRow([TextCellValue('Today Orders'), IntCellValue(report.todayOrders)]);
      sheetObject.appendRow([TextCellValue('This Week Revenue'), DoubleCellValue(report.weekRevenue)]);
      sheetObject.appendRow([TextCellValue('This Month Revenue'), DoubleCellValue(report.monthRevenue)]);

      // Top Items
      Sheet topItemsSheet = excel['Top Items'];
      topItemsSheet.appendRow([TextCellValue('Item Name'), TextCellValue('Quantity Sold'), TextCellValue('Total Revenue')]);
      for (var item in report.topItems) {
        topItemsSheet.appendRow([
          TextCellValue(item['name'].toString()),
          IntCellValue((item['totalQty'] as num).toInt()),
          DoubleCellValue((item['totalRevenue'] as num).toDouble()),
        ]);
      }

      // Daily Revenue
      Sheet dailyRevSheet = excel['Daily Revenue'];
      dailyRevSheet.appendRow([TextCellValue('Day'), TextCellValue('Revenue')]);
      for (var day in report.dailyRevenue) {
        dailyRevSheet.appendRow([
          TextCellValue(day['day'].toString()),
          DoubleCellValue((day['revenue'] as num).toDouble()),
        ]);
      }

      // Category Breakdown
      Sheet catSheet = excel['Category Breakdown'];
      catSheet.appendRow([TextCellValue('Category'), TextCellValue('Total Revenue')]);
      for (var cat in report.categoryBreakdown) {
        catSheet.appendRow([
          TextCellValue(cat['category'].toString()),
          DoubleCellValue((cat['totalRevenue'] as num).toDouble()),
        ]);
      }

      var fileBytes = excel.save();
      if (fileBytes != null && kIsWeb) {
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'reports_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      if (kDebugMode) print('Error exporting to excel: $e');
    }
  }
}
