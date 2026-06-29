import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/stock_entry.dart';

class PdfReportHelper {
  static Future<void> generateAndPrintReport({
    required List<StockEntry> entries,
    String? sectionName,
    String? productName,
    DateTime? fromDate,
    DateTime? toDate,
    String typeFilter = 'all',
  }) async {
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final bengaliRegular = await PdfGoogleFonts.notoSansBengaliRegular();
    final bengaliBold = await PdfGoogleFonts.notoSansBengaliBold();

    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      fontFallback: [bengaliRegular, bengaliBold],
    );

    final pdf = pw.Document(theme: theme);

    final dateFormat = DateFormat('dd MMM yyyy');
    final dateRangeStr = (fromDate != null || toDate != null)
        ? '${fromDate != null ? dateFormat.format(fromDate) : "Beginning"} to ${toDate != null ? dateFormat.format(toDate) : "Present"}'
        : 'All Time';

    final totalIn = entries
        .where((e) => e.type == 'in')
        .fold(0.0, (sum, e) => sum + e.quantity);
    final totalOut = entries
        .where((e) => e.type == 'out')
        .fold(0.0, (sum, e) => sum + e.quantity);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.indigo, width: 1.5),
              ),
            ),
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'KATTALI TEXTILE LIMITED',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Stock Movement History Report',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Date: ${dateFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'KTL Store Management System',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Filter Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Report Parameters',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo800,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Section: ${sectionName ?? "All Sections"}',
                                style: const pw.TextStyle(fontSize: 9)),
                            pw.SizedBox(height: 3),
                            pw.Text('Product: ${productName ?? "All Products"}',
                                style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Date Range: $dateRangeStr',
                                style: const pw.TextStyle(fontSize: 9)),
                            pw.SizedBox(height: 3),
                            pw.Text(
                                'Filter Type: ${typeFilter == "all" ? "All Movements" : typeFilter == "in" ? "Stock In Only" : "Stock Issue Only"}',
                                style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Statistics Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('Total Records', '${entries.length}', PdfColors.blue900),
                _buildStatBox('Total Stock In', '${totalIn.toStringAsFixed(1)} units', PdfColors.green900),
                _buildStatBox('Total Issued', '${totalOut.toStringAsFixed(1)} units', PdfColors.red900),
              ],
            ),
            pw.SizedBox(height: 20),

            // Table of Transactions
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Type', 'Product', 'Section', 'Bill No', 'Qty', 'Notes'],
              data: entries.map((e) {
                final isIn = e.type == 'in';
                return [
                  dateFormat.format(e.date),
                  isIn ? 'STOCK IN' : 'ISSUE',
                  e.productName ?? 'Unknown',
                  e.sectionName ?? 'N/A',
                  e.billNo,
                  '${isIn ? "+" : "-"}${e.quantity.toStringAsFixed(1)} ${e.productUnit ?? ""}',
                  e.note ?? '',
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.indigo800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              rowDecoration: const pw.BoxDecoration(
                color: PdfColors.white,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey50,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerLeft,
              },
            ),
            pw.SizedBox(height: 40),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(
                      width: 120,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.8)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Prepared By', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 120,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.8)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'KTL_Stock_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor textColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }
}
