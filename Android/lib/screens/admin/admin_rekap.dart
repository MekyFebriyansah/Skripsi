import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../models/laporan_model.dart';
import 'admin_export.dart';

class AdminRekap extends StatefulWidget {
  const AdminRekap({super.key});

  @override
  State<AdminRekap> createState() => _AdminRekapState();
}

class _AdminRekapState extends State<AdminRekap> {
  static const _primary = Color(0xFF0D47A1);

  bool _isLoading = true;
  String? _error;
  int _total = 0, _selesai = 0, _proses = 0, _belum = 0;
  Map<String, int> _perKategori = {};
  Map<String, int> _perBulan = {};

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

      // Urutkan per bulan ascending dan ambil 6 bulan terakhir
      final sortedBulan = Map.fromEntries(
        perBulan.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
      final bulan6 = sortedBulan.entries.toList();
      final startIdx = bulan6.length > 6 ? bulan6.length - 6 : 0;
      final perBulan6 = Map.fromEntries(bulan6.sublist(startIdx));

      if (!mounted) return;
      setState(() {
        _total = list.length;
        _selesai = list.where((l) => l.status == 'Selesai').length;
        _proses = list.where((l) => l.status == 'Sedang Diproses').length;
        _belum = list.where((l) => l.status == 'Belum Ditangani').length;
        _perKategori = perKat;
        _perBulan = perBulan6;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Rekap & Statistik'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminExport()),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Gagal memuat',
                          style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      ElevatedButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatCards(),
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

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard('Total', _total, Icons.assignment_rounded,
            const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
        _statCard('Selesai', _selesai, Icons.check_circle_rounded,
            const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
        _statCard('Diproses', _proses, Icons.hourglass_bottom_rounded,
            const Color(0xFFE65100), const Color(0xFFFFF3E0)),
        _statCard('Belum Ditangani', _belum, Icons.warning_amber_rounded,
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
            padding: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
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
      Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  if (_selesai > 0)
                    PieChartSectionData(
                      value: _selesai.toDouble(),
                      color: const Color(0xFF43A047),
                      title:
                          '${(_selesai / _total * 100).toStringAsFixed(0)}%',
                      radius: 55,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (_proses > 0)
                    PieChartSectionData(
                      value: _proses.toDouble(),
                      color: const Color(0xFFFF8F00),
                      title:
                          '${(_proses / _total * 100).toStringAsFixed(0)}%',
                      radius: 55,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (_belum > 0)
                    PieChartSectionData(
                      value: _belum.toDouble(),
                      color: const Color(0xFFE53935),
                      title:
                          '${(_belum / _total * 100).toStringAsFixed(0)}%',
                      radius: 55,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              _legend(const Color(0xFF43A047), 'Selesai ($_selesai)'),
              _legend(const Color(0xFFFF8F00), 'Diproses ($_proses)'),
              _legend(
                  const Color(0xFFE53935), 'Belum ($_belum)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBarChart() {
    if (_perBulan.isEmpty) return const SizedBox.shrink();

    final keys = _perBulan.keys.toList();
    final vals = _perBulan.values.toList();
    final maxY = (vals.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return _card(
      'Tren Laporan 6 Bulan Terakhir',
      SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
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
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= keys.length) return const SizedBox();
                    final parts = keys[idx].split('-');
                    const shortMonths = [
                      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
                    ];
                    final monthIdx = int.tryParse(parts[1]) ?? 0;
                    return Text(
                      shortMonths[monthIdx],
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black45),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: List.generate(keys.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: vals[i].toDouble(),
                    color: _primary,
                    width: 22,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildKategoriList() {
    if (_perKategori.isEmpty) return const SizedBox.shrink();

    final sorted = _perKategori.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A),
      const Color(0xFF00695C),
      const Color(0xFFE65100),
      const Color(0xFFC62828),
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
                              fontWeight: FontWeight.w600)),
                    ),
                    Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                            fontSize: 12, color: color,
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
                  color: Color(0xFF0D47A1))),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}
