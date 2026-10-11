import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/platform_store.dart';
import 'common.dart';

String _amount(dynamic v) => 'BDT ${(number(v) / 100).toStringAsFixed(2)}';
String localTime(dynamic v) {
  final value = '$v';
  final t = DateTime.tryParse(
    RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value) ? value : '${value}Z',
  );
  return t == null
      ? 'Unavailable'
      : '${t.add(const Duration(hours: 6)).toIso8601String().substring(0, 19).replaceAll('T', ' ')} (Dhaka)';
}

Future<void> shareReceipt(
  BuildContext context,
  Record trip,
) => perform(context, () async {
  final snapshot = record(trip['snapshot']);
  final doc = pw.Document();
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
  );
  final rows = <List<String>>[
    ['Trip reference', '${trip['id']}'],
    ['Status', stage(trip['status'])],
    ['Date', localTime(trip['created_at'])],
    ['Product', '${record(snapshot['product'])['name']}'],
    ['Driver', '${record(snapshot['driver'])['name'] ?? 'Unassigned'}'],
    ['Vehicle', '${record(snapshot['driver'])['vehicle'] ?? 'Unassigned'}'],
    ['Plate', '${record(snapshot['driver'])['plate'] ?? 'Unavailable'}'],
    ['Pickup', '${record(snapshot['pickup'])['name']}'],
    for (final stop in records(snapshot['stops'])) ['Stop', '${stop['name']}'],
    ['Destination', '${record(snapshot['destination'])['name']}'],
    [
      'Accepted road distance',
      '${(number(snapshot['distance_m']) / 1000).toStringAsFixed(3)} km',
    ],
    ['Rate', '${_amount(snapshot['rate_minor'])}/km'],
    for (final item in records(trip['fare_items']))
      ['${item['label']}', _amount(item['amount_minor'])],
    ['Accepted fare', _amount(snapshot['fare_minor'])],
    [
      'Charged fare',
      trip['payment_status'] == 'under_review'
          ? 'Pending independent fare review'
          : _amount(
              trip['status'] == 'completed' || trip['status'] == 'interrupted'
                  ? trip['fare_minor']
                  : 0,
            ),
    ],
    ['Cash payment', stage(trip['payment_status'])],
    if (trip['tip_minor'] != null)
      ['Cash tip (${stage(trip['tip_status'])})', _amount(trip['tip_minor'])],
    for (final entry in records(trip['adjustments']))
      [stage(entry['kind']), _amount(entry['amount_minor'])],
  ];
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: font,
        fontFallback: [
          pw.Font.ttf(
            await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf'),
          ),
        ],
      ),
      build: (_) => [
        pw.Text(
          'RideShare trip receipt',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          data: rows,
          headerCount: 0,
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'A collection report or refund approval is not confirmation of funds received. Cash payment status and executed adjustments are shown separately.',
        ),
      ],
    ),
  );
  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'rideshare-receipt-${trip['id']}.pdf',
  );
});

Future<void> shareEarnings(
  BuildContext context,
  Record data,
) => perform(context, () async {
  final doc = pw.Document();
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
  );
  final stats = record(data['stats']);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(
        base: font,
        fontFallback: [
          pw.Font.ttf(
            await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf'),
          ),
        ],
      ),
      build: (_) => [
        pw.Text(
          'RideShare earnings statement',
          style: pw.TextStyle(fontSize: 24),
        ),
        pw.Text(
          'As of ${DateTime.now().toUtc().toIso8601String()} UTC. Period: ${number(stats['period_days']) == 0 ? 'Lifetime' : 'Last ${stats['period_days']} days'}',
        ),
        pw.Text(
          'Completed trips: ${stats['completed']} | Recorded earnings: ${_amount(stats['earning_minor'])}',
        ),
        pw.Text(
          'Lifetime net payable after retained cash: ${_amount(data['net_payable_minor'])}',
        ),
        pw.Text(
          'Latest 100 ledger entries follow; this is not a tax certificate or proof of a transfer.',
        ),
        pw.TableHelper.fromTextArray(
          headers: ['Date UTC', 'Kind', 'Account', 'Amount BDT'],
          data: [
            for (final entry in records(data['ledger']))
              [
                '${entry['created_at']}',
                stage(entry['kind']),
                stage(entry['account_key']),
                _amount(entry['amount_minor']),
              ],
          ],
        ),
      ],
    ),
  );
  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'rideshare-earnings.pdf',
  );
});
