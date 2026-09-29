import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  /// Exports tabular data to an Excel (.xlsx) file
  static Future<File> exportToExcel({
    required String filePath,
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final excel = xls.Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    // Append headers
    sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

    // Append rows
    for (final row in rows) {
      final cellValues = row.map<xls.CellValue>((val) {
        if (val == null) return xls.TextCellValue('');
        if (val is num) return xls.DoubleCellValue(val.toDouble());
        return xls.TextCellValue(val.toString());
      }).toList();
      sheet.appendRow(cellValues);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('فشل في إنشاء ملف الإكسيل');
    final file = File(filePath);
    return await file.writeAsBytes(bytes);
  }

  /// Exports tabular data to a CSV file with UTF-8 BOM for proper Arabic display
  static Future<File> exportToCsv({
    required String filePath,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final List<List<dynamic>> allRows = [headers, ...rows];
    final csvString = csv.encode(allRows);
    
    // Add UTF-8 BOM so Excel opens Arabic correctly
    final encoded = utf8.encode(csvString);
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...encoded];
    final file = File(filePath);
    return await file.writeAsBytes(bytes);
  }

  /// Generates a PDF document for preview or printing
  static Future<Uint8List> generatePdfReport({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    Map<String, String>? summary,
  }) async {
    final doc = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'شركة سيجما للمقاولات والتشييد',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    title,
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                  pw.Divider(thickness: 1, color: PdfColors.grey400),
                ],
              ),
            ),

            // Summary cards if present
            if (summary != null && summary.isNotEmpty) ...[
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: summary.entries.map((e) {
                    return pw.Column(
                      children: [
                        pw.Text(e.key, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text(e.value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],

            // Data Table
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellAlignment: pw.Alignment.centerRight,
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerAlignment: pw.Alignment.centerRight,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// Opens the native print dialog for the generated PDF
  static Future<void> printReport({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    Map<String, String>? summary,
  }) async {
    final pdfBytes = await generatePdfReport(
      title: title,
      subtitle: subtitle,
      headers: headers,
      rows: rows,
      summary: summary,
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }
}
