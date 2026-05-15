import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../services/api_service.dart';
import '../../services/file_download_helper.dart';
import '../../models/laporan_model.dart';

class PemerintahRekap extends StatefulWidget {
  const PemerintahRekap({super.key});

  @override
  State<PemerintahRekap> createState() => _PemerintahRekapState();
}

class _PemerintahRekapState extends State<PemerintahRekap> {
  static const _primary = Color(0xFF1B5E20);

  bool _isLoading = true;
  String? _error;
  int _total = 0, _selesai = 0, _proses = 0, _belum = 0;
  List<LaporanModel> _laporan = [];
  Map<String, int> _perKategori = {};
  Map<String, int> _perBulan = {};

  Future<void> _debugDownloadLog(
      String hypothesisId, String message, Map<String, dynamic> data) async {
    debugPrint('[REKAP_DOWNLOAD][$hypothesisId] $message $data');
    try {
      await http.post(
        Uri.parse(
            'http://127.0.0.1:7672/ingest/f890cf6b-c32d-4b6c-9970-a41366fb28d6'),
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': 'e487db',
        },
        body: jsonEncode({
          'sessionId': 'e487db',
          'runId': 'pre-fix',
          'hypothesisId': hypothesisId,
          'location':
              'Android/lib/screens/pemerintah/pemerintah_rekap.dart',
          'message': message,
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getAllLaporan();
      final list = data.map((e) => LaporanModel.fromJson(e)).toList();

      final perKat = <String, int>{};
      final perBulan = <String, int>{};
      for (final l in list) {
        final kat = l.kategori ?? 'Lainnya';
        perKat[kat] = (perKat[kat] ?? 0) + 1;
        final key =
            '${l.createdAt.year}-${l.createdAt.month.toString().padLeft(2, '0')}';
        perBulan[key] = (perBulan[key] ?? 0) + 1;
      }

      final sorted = Map.fromEntries(
          perBulan.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      final entries = sorted.entries.toList();
      final start = entries.length > 6 ? entries.length - 6 : 0;

      if (!mounted) return;
      setState(() {
        _laporan = list;
        _total = list.length;
        _selesai = list.where((l) => l.status == 'Selesai').length;
        _proses = list.where((l) => l.status == 'Sedang Diproses').length;
        _belum = list.where((l) => l.status == 'Belum Ditangani').length;
        _perKategori = perKat;
        _perBulan = Map.fromEntries(entries.sublist(start));
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _laporan = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadLaporanPerKategori() async {
    // #region agent log
    await _debugDownloadLog('H1,H4', 'download started', {
      'kIsWeb': kIsWeb,
      'targetPlatform': defaultTargetPlatform.name,
      'laporanCount': _laporan.length,
      'kategoriCount': _perKategori.length,
    });
    // #endregion

    if (_laporan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada laporan untuk didownload')),
      );
      return;
    }

    try {
      final pdfBytes = await _buildRekapPdf();
      final fileName =
          'rekap_pengaduan_per_kategori_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // #region agent log
      await _debugDownloadLog('H1,H2,H3,H5', 'before pdf download', {
        'kIsWeb': kIsWeb,
        'pdfBytes': pdfBytes.length,
        'fileName': fileName,
      });
      // #endregion

      final savedPath = await downloadFileBytes(
        fileName: fileName,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      // #region agent log
      await _debugDownloadLog('H2,H3,H5', 'pdf download completed', {
        'savedPath': savedPath,
        'kIsWeb': kIsWeb,
      });
      // #endregion

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF berhasil didownload: $savedPath')),
      );
    } catch (e) {
      // #region agent log
      await _debugDownloadLog('H1,H2,H3,H5', 'download failed', {
        'errorType': e.runtimeType.toString(),
        'error': e.toString(),
        'kIsWeb': kIsWeb,
      });
      // #endregion

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal download laporan: $e')),
      );
    }
  }

  Future<Uint8List> _buildRekapPdf() async {
    final grouped = <String, List<LaporanModel>>{};
    for (final laporan in _laporan) {
      final kategori = laporan.kategori ?? 'Lainnya';
      grouped.putIfAbsent(kategori, () => []).add(laporan);
    }

    final kategoriKeys = grouped.keys.toList()..sort();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text(
              'Rekap Pengaduan Masyarakat',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Tanggal Export: ${_formatDate(DateTime.now())}'),
            pw.Text('Total Laporan: ${_laporan.length}'),
            pw.SizedBox(height: 16),
            for (final kategori in kategoriKeys) ...[
              _buildKategoriPdfSection(kategori, grouped[kategori]!),
              pw.SizedBox(height: 18),
            ],
          ];
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildKategoriPdfSection(
      String kategori, List<LaporanModel> laporan) {
    final items = [...laporan]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: pw.BoxDecoration(
            color: PdfColors.green100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'Kategori: $kategori (${items.length} laporan)',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellAlignment: pw.Alignment.topLeft,
          headerAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FixedColumnWidth(22),
            1: const pw.FlexColumnWidth(1.6),
            2: const pw.FlexColumnWidth(1.1),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(1.2),
            7: const pw.FlexColumnWidth(2),
            8: const pw.FlexColumnWidth(1.6),
          },
          headers: [
            'No',
            'Judul',
            'Status',
            'Pelapor',
            'NIK',
            'No HP',
            'Tanggal',
            'Deskripsi',
            'Lokasi',
          ],
          data: List.generate(items.length, (index) {
            final l = items[index];
            final lokasi = l.latitude != null && l.longitude != null
                ? '${l.latitude}, ${l.longitude}'
                : '-';
            return [
              '${index + 1}',
              l.judul,
              l.status,
              l.namaUser ?? '-',
              l.nikUser ?? '-',
              l.noHpUser ?? '-',
              _formatDate(l.createdAt),
              l.deskripsi,
              lokasi,
            ];
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Rekap Laporan'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download laporan per kategori',
            onPressed: _isLoading ? null : _downloadLaporanPerKategori,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: _load,
                      child: const Text('Coba Lagi')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        _buildStatGrid(),
                        const SizedBox(height: 20),
                        _buildPieChart(),
          const SizedBox(height: 20),
                        _buildBarChart(),
          const SizedBox(height: 20),
                        _buildKategoriList(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _statCard('Total', _total, Icons.assignment_rounded,
            const Color(0xFF1B5E20), const Color(0xFFE8F5E9)),
        _statCard('Selesai', _selesai, Icons.check_circle_rounded,
            const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
        _statCard('Diproses', _proses, Icons.hourglass_bottom_rounded,
            const Color(0xFFE65100), const Color(0xFFFFF3E0)),
        _statCard('Belum', _belum, Icons.pending_rounded,
            const Color(0xFFC62828), const Color(0xFFFFEBEE)),
      ],
    );
  }

  Widget _statCard(
      String label, int value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$value',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (_total == 0) return const SizedBox.shrink();
    return _card(
      'Distribusi Status',
      Column(children: [
        SizedBox(
          height: 190,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 48,
            sections: [
              if (_selesai > 0)
                PieChartSectionData(
                    value: _selesai.toDouble(),
                    color: const Color(0xFF43A047),
                    title:
                        '${(_selesai / _total * 100).toStringAsFixed(0)}%',
                    radius: 52,
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              if (_proses > 0)
                PieChartSectionData(
                    value: _proses.toDouble(),
                    color: const Color(0xFFFF8F00),
                    title:
                        '${(_proses / _total * 100).toStringAsFixed(0)}%',
                    radius: 52,
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              if (_belum > 0)
                PieChartSectionData(
                    value: _belum.toDouble(),
                    color: const Color(0xFFE53935),
                    title:
                        '${(_belum / _total * 100).toStringAsFixed(0)}%',
                    radius: 52,
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
            ],
          )),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, children: [
          _legend(const Color(0xFF43A047), 'Selesai ($_selesai)'),
          _legend(const Color(0xFFFF8F00), 'Diproses ($_proses)'),
          _legend(const Color(0xFFE53935), 'Belum ($_belum)'),
        ]),
      ]),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }

  Widget _buildBarChart() {
    if (_perBulan.isEmpty) return const SizedBox.shrink();
    final keys = _perBulan.keys.toList();
    final vals = _perBulan.values.toList();
    final maxY =
        (vals.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return _card(
      'Tren Laporan 6 Bulan Terakhir',
      SizedBox(
        height: 210,
        child: BarChart(BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: (maxY / 4).ceilToDouble(),
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: const TextStyle(
                      fontSize: 10, color: Colors.black45)),
            )),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= keys.length)
                  return const SizedBox();
                final parts = keys[i].split('-');
                const m = [
                  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
                ];
                return Text(m[int.tryParse(parts[1]) ?? 0],
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black45));
              },
            )),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(keys.length, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: vals[i].toDouble(),
                color: _primary,
                width: 22,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
              ),
            ]);
          }),
        )),
      ),
    );
  }

  Widget _buildKategoriList() {
    if (_perKategori.isEmpty) return const SizedBox.shrink();
    final sorted = _perKategori.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      _primary,
      const Color(0xFF1565C0),
      const Color(0xFFE65100),
      const Color(0xFFE53935),
      const Color(0xFF6A1B9A),
      const Color(0xFF37474F),
    ];

    return _card(
      'Laporan per Kategori',
      Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = _total > 0 ? e.value / _total : 0.0;
          final color = colors[i % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(e.key,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600))),
                    Text(
                        '${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _primary)),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${local.day} ${months[local.month]} ${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
