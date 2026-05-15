import 'package:flutter/material.dart';
import '../../models/laporan_model.dart';
import '../../services/api_service.dart';
import 'laporan_detail_screen.dart';

class LaporanListScreen extends StatefulWidget {
  const LaporanListScreen({super.key});

  @override
  State<LaporanListScreen> createState() => _LaporanListScreenState();
}

class _LaporanListScreenState extends State<LaporanListScreen> {
  static const _primary = Color(0xFF0D47A1);

  List<LaporanModel> _all = [];
  List<LaporanModel> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  String _filterStatus = 'Semua';

  final _searchCtrl = TextEditingController();
  final _statusOptions = [
    'Semua',
    'Belum Ditangani',
    'Sedang Diproses',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getAllLaporan();
      final list = data.map((e) => LaporanModel.fromJson(e)).toList();
      if (!mounted) return;
      setState(() {
        _all = list;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _all.where((l) {
        final matchStatus =
            _filterStatus == 'Semua' || l.status == _filterStatus;
        final q = _search.toLowerCase();
        final matchSearch = q.isEmpty ||
            l.judul.toLowerCase().contains(q) ||
            (l.namaUser ?? '').toLowerCase().contains(q) ||
            (l.kategori ?? '').toLowerCase().contains(q);
        return matchStatus && matchSearch;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Selesai':
        return const Color(0xFF43A047);
      case 'Sedang Diproses':
        return const Color(0xFFFF8F00);
      default:
        return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Daftar Pengaduan'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          _search = v;
          _applyFilter();
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari judul, pelapor, kategori...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search = '';
                    _applyFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((s) {
            final selected = _filterStatus == s;
            Color chipColor = Colors.grey;
            if (s == 'Belum Ditangani') chipColor = const Color(0xFFE53935);
            if (s == 'Sedang Diproses') chipColor = const Color(0xFFFF8F00);
            if (s == 'Selesai') chipColor = const Color(0xFF43A047);
            if (s == 'Semua') chipColor = _primary;

            final count = s == 'Semua'
                ? _all.length
                : _all.where((l) => l.status == s).length;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected,
                label: Text('$s ($count)'),
                selectedColor: chipColor.withOpacity(0.2),
                checkmarkColor: chipColor,
                labelStyle: TextStyle(
                  color: selected ? chipColor : Colors.black54,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (_) {
                  setState(() => _filterStatus = s);
                  _applyFilter();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Gagal memuat data', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _search.isNotEmpty
                  ? 'Tidak ada hasil untuk "$_search"'
                  : 'Tidak ada laporan $_filterStatus',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filtered.length,
        itemBuilder: (context, i) => _buildCard(context, _filtered[i]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, LaporanModel l) {
    final color = _statusColor(l.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LaporanDetailScreen(laporan: l)),
        ).then((_) => _load()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.status,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(l.kategori ?? 'Umum',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  const SizedBox(width: 16),
                  const Icon(Icons.person_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l.namaUser ?? '—',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(l.createdAt),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
