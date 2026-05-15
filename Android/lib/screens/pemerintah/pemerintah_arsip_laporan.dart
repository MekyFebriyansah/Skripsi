import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/laporan_model.dart';
import '../admin/laporan_detail_screen.dart';

class PemerintahArsipLaporan extends StatefulWidget {
  const PemerintahArsipLaporan({super.key});

  @override
  State<PemerintahArsipLaporan> createState() =>
      _PemerintahArsipLaporanState();
}

class _PemerintahArsipLaporanState extends State<PemerintahArsipLaporan> {
  static const _primary = Color(0xFF1B5E20);

  List<LaporanModel> _arsip = [];
  List<LaporanModel> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  final _searchCtrl = TextEditingController();

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
      if (!mounted) return;
      final list = data.map((e) => LaporanModel.fromJson(e)).toList();
      final selesai = list.where((l) => l.status == 'Selesai').toList();
      setState(() {
        _arsip = selesai;
        _filtered = selesai;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySearch(String q) {
    _search = q;
    setState(() {
      _filtered = _arsip.where((l) {
        final lq = q.toLowerCase();
        return lq.isEmpty ||
            l.judul.toLowerCase().contains(lq) ||
            (l.namaUser ?? '').toLowerCase().contains(lq) ||
            (l.kategori ?? '').toLowerCase().contains(lq);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Arsip Laporan (${_arsip.length})'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        onChanged: _applySearch,
        decoration: InputDecoration(
          hintText: 'Cari arsip laporan...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchCtrl.clear();
                    _applySearch('');
                  })
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
      ]));
    }
    if (_filtered.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(_search.isNotEmpty ? Icons.search_off : Icons.archive_outlined,
            size: 64, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          _search.isNotEmpty
              ? 'Tidak ada hasil untuk "$_search"'
              : 'Belum ada laporan yang diselesaikan',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filtered.length,
        itemBuilder: (ctx, i) => _buildCard(ctx, _filtered[i]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, LaporanModel l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LaporanDetailScreen(laporan: l)),
        ).then((_) => _load()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF43A047), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.category_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(l.kategori ?? 'Umum',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(l.namaUser ?? '-',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ),
                      Text(_fmtDate(l.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black38)),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${m[dt.month]} ${dt.year}';
  }
}
