import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/laporan_model.dart';

class AdminExport extends StatefulWidget {
  const AdminExport({super.key});

  @override
  State<AdminExport> createState() => _AdminExportState();
}

class _AdminExportState extends State<AdminExport> {
  static const _primary = Color(0xFF0D47A1);

  int _totalLaporan = 0;
  String _periode = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await ApiService.getAllLaporan();
      final list = data.map((e) => LaporanModel.fromJson(e)).toList();
      if (!mounted) return;
      String periode = '-';
      if (list.isNotEmpty) {
        final first = list.last.createdAt;
        final last = list.first.createdAt;
        const months = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        if (first.month == last.month && first.year == last.year) {
          periode = '${months[first.month]} ${first.year}';
        } else {
          periode =
              '${months[first.month]} ${first.year} – ${months[last.month]} ${last.year}';
        }
      }
      setState(() {
        _totalLaporan = list.length;
        _periode = periode;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showExportDialog(String format) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              format.contains('Excel')
                  ? Icons.table_chart
                  : format.contains('PDF')
                      ? Icons.picture_as_pdf
                      : Icons.download,
              color: format.contains('Excel')
                  ? Colors.green
                  : format.contains('PDF')
                      ? Colors.red
                      : _primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('Export $format')),
          ],
        ),
        content: Text(
          'Ekspor $_totalLaporan laporan (Periode: $_periode) ke format $format?\n\n'
          'File akan tersedia di folder Download perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Export $format berhasil! (simulasi)'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Export Laporan'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info kartu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                      children: [
                        Text(
                          '$_totalLaporan',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text('Total Laporan',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          'Periode: $_periode',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            const Text('Format Export',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _exportCard(
              title: 'Export ke Excel (.xlsx)',
              desc: 'Format Excel untuk analisis data dan pelaporan',
              icon: Icons.table_chart,
              color: Colors.green,
              onTap: () => _showExportDialog('Excel (.xlsx)'),
            ),
            const SizedBox(height: 12),
            _exportCard(
              title: 'Export ke PDF',
              desc: 'Dokumen PDF siap cetak untuk laporan resmi',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              onTap: () => _showExportDialog('PDF'),
            ),
            const SizedBox(height: 12),
            _exportCard(
              title: 'Export Semua (ZIP)',
              desc:
                  'Paket lengkap: Excel + PDF + foto bukti dalam satu file',
              icon: Icons.folder_zip_outlined,
              color: _primary,
              onTap: () => _showExportDialog('ZIP (Semua Data)'),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fitur export memerlukan integrasi backend. Tombol di atas menjalankan simulasi.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
