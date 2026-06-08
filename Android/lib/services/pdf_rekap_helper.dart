import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/laporan_model.dart';

/// Helper untuk generate PDF rekap formal.
/// Dipakai oleh Admin dan Pemerintah.
class PdfRekapHelper {
  // Warna RGB eksplisit untuk menghindari masalah dengan color constants
  static final _grey200 = PdfColor.fromInt(0xFFEEEEEE);
  static final _grey300 = PdfColor.fromInt(0xFFE0E0E0);
  static final _grey400 = PdfColor.fromInt(0xFFBDBDBD);
  static final _grey600 = PdfColor.fromInt(0xFF757575);
  static final _grey800 = PdfColor.fromInt(0xFF424242);
  static final _blue100 = PdfColor.fromInt(0xFFBBDEFB);
  static final _blue800 = PdfColor.fromInt(0xFF1565C0);
  static final _green800 = PdfColor.fromInt(0xFF2E7D32);
  static final _orange800 = PdfColor.fromInt(0xFFE65100);
  static final _red800 = PdfColor.fromInt(0xFFC62828);
  static final _white = PdfColor.fromInt(0xFFFFFFFF);

  /// Generate PDF rekap formal untuk admin.
  static Future<Uint8List> generateAdminRekap({
    required List<LaporanModel> laporan,
    required int total,
    required int selesai,
    required int proses,
    required int belum,
    required String Function(DateTime) formatDate,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildHeader(
          title: 'LAPORAN REKAPITULASI PENGADUAN MASYARAKAT',
          subtitle: 'Desa Mandiangin Pasar, Kabupaten Sarolangun',
          role: 'ADMINISTRATOR',
          formatDate: formatDate,
        ),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) {
          return [
            _buildSummarySection(total, selesai, proses, belum),
            pw.SizedBox(height: 20),
            _buildDetailTables(laporan, formatDate),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// Generate PDF rekap formal untuk pemerintah.
  static Future<Uint8List> generatePemerintahRekap({
    required List<LaporanModel> laporan,
    required int total,
    required int selesai,
    required int proses,
    required int belum,
    required String Function(DateTime) formatDate,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildHeader(
          title: 'LAPORAN REKAPITULASI PENGADUAN MASYARAKAT',
          subtitle: 'Desa Mandiangin Pasar, Kabupaten Sarolangun',
          role: 'PEMERINTAH DESA',
          formatDate: formatDate,
        ),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) {
          return [
            _buildSummarySection(total, selesai, proses, belum),
            pw.SizedBox(height: 20),
            _buildDetailTables(laporan, formatDate),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// Header formal dengan logo placeholder dan judul resmi.
  static pw.Widget _buildHeader({
    required String title,
    required String subtitle,
    required String role,
    required String Function(DateTime) formatDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo placeholder
            pw.Container(
              width: 60,
              height: 60,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _grey600, width: 1.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Center(
                child: pw.Text(
                  'LOGO\nDESA',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey600,
                  ),
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            // Judul tengah
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'PEMERINTAH KABUPATEN SAROLANGUN',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'KANTOR DESA MANDIANGIN PASAR',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            // Info kanan
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: _grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Role: $role',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Tgl Export: ${formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 2,
          color: _grey800,
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 1,
          color: _grey400,
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  /// Footer dengan nomor halaman.
  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Container(
          height: 1,
          color: _grey400,
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Aplikasi Pelaporan Keluhan Masyarakat - Desa Mandiangin Pasar',
              style: pw.TextStyle(fontSize: 7, color: _grey600),
            ),
            pw.Text(
              'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7, color: _grey600),
            ),
          ],
        ),
      ],
    );
  }

  /// Section ringkasan statistik.
  static pw.Widget _buildSummarySection(
      int total, int selesai, int proses, int belum) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _grey200,
        border: pw.Border.all(color: _grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'I. RINGKASAN DATA PENGADUAN',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _summaryBox('Total Pengaduan', total.toString(), _blue800),
              pw.SizedBox(width: 10),
              _summaryBox('Selesai Ditangani', selesai.toString(), _green800),
              pw.SizedBox(width: 10),
              _summaryBox('Sedang Diproses', proses.toString(), _orange800),
              pw.SizedBox(width: 10),
              _summaryBox('Belum Ditangani', belum.toString(), _red800),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Dicetak pada: ${DateTime.now().toLocal().day}/${DateTime.now().toLocal().month}/${DateTime.now().toLocal().year} '
            'pukul ${DateTime.now().toLocal().hour.toString().padLeft(2, '0')}:'
            '${DateTime.now().toLocal().minute.toString().padLeft(2, '0')} WIB',
            style: pw.TextStyle(fontSize: 7, color: _grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: _white,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 8,
                color: _white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tabel detail per kategori.
  static pw.Widget _buildDetailTables(
      List<LaporanModel> laporan, String Function(DateTime) formatDate) {
    final grouped = <String, List<LaporanModel>>{};
    for (final l in laporan) {
      final kategori = l.kategori ?? 'Lainnya';
      grouped.putIfAbsent(kategori, () => []).add(l);
    }

    final kategoriKeys = grouped.keys.toList()..sort();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'II. DAFTAR PENGADUAN PER KATEGORI',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        for (final kategori in kategoriKeys) ...[
          _buildKategoriTable(kategori, grouped[kategori]!, formatDate),
          pw.SizedBox(height: 16),
        ],
      ],
    );
  }

  static pw.Widget _buildKategoriTable(
      String kategori, List<LaporanModel> items, String Function(DateTime) formatDate) {
    final sorted = [...items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _blue100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Kategori: $kategori',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Jumlah: ${items.length} pengaduan',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: _grey400, width: 0.5),
          headerDecoration: pw.BoxDecoration(color: _grey300),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 7,
          ),
          cellStyle: pw.TextStyle(fontSize: 7),
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.center,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          columnWidths: {
            0: const pw.FixedColumnWidth(20),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.0),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.1),
            5: const pw.FlexColumnWidth(1.0),
            6: const pw.FlexColumnWidth(1.2),
            7: const pw.FlexColumnWidth(2.0),
            8: const pw.FlexColumnWidth(1.5),
          },
          headers: [
            'No',
            'Judul Pengaduan',
            'Status',
            'Nama Pelapor',
            'NIK',
            'No. HP',
            'Tanggal',
            'Deskripsi',
            'Lokasi',
          ],
          data: List.generate(sorted.length, (index) {
            final l = sorted[index];
            final lokasi = l.latitude != null && l.longitude != null
                ? '${l.latitude!.toStringAsFixed(4)}, ${l.longitude!.toStringAsFixed(4)}'
                : '-';
            return [
              '${index + 1}',
              l.judul,
              l.status,
              l.namaUser ?? '-',
              l.nikUser ?? '-',
              l.noHpUser ?? '-',
              formatDate(l.createdAt),
              l.deskripsi,
              lokasi,
            ];
          }),
        ),
      ],
    );
  }
}
