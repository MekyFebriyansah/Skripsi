import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminManajemenPengguna extends StatefulWidget {
  const AdminManajemenPengguna({super.key});

  @override
  State<AdminManajemenPengguna> createState() =>
      _AdminManajemenPenggunaState();
}

class _AdminManajemenPenggunaState extends State<AdminManajemenPengguna> {
  static const _primary = Color(0xFF0D47A1);

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  String _filterRole = 'Semua';

  final _searchCtrl = TextEditingController();
  final _roles = ['Semua', 'masyarakat', 'sekretaris', 'kepala_desa', 'admin'];

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
      final data = await ApiService.getUsers();
      if (!mounted) return;
      setState(() {
        _users = data.cast<Map<String, dynamic>>();
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
      _filtered = _users.where((u) {
        final q = _search.toLowerCase();
        final matchSearch = q.isEmpty ||
            (u['name'] ?? '').toLowerCase().contains(q) ||
            (u['nik'] ?? '').contains(q) ||
            (u['no_hp'] ?? '').contains(q);
        final matchRole = _filterRole == 'Semua' ||
            u['role'] == _filterRole;
        return matchSearch && matchRole;
      }).toList();
    });
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final isActive = user['is_active'] == true || user['is_active'] == 1;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isActive ? 'Nonaktifkan Pengguna' : 'Aktifkan Pengguna'),
        content: Text(
          isActive
              ? 'Akun "${user['name']}" akan dinonaktifkan dan tidak bisa login.'
              : 'Akun "${user['name']}" akan diaktifkan kembali.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    isActive ? Colors.red : Colors.green),
            child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final resp = await ApiService.toggleUserStatus(user['id']);
      if (!mounted) return;
      final body = jsonDecode(resp.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body['message'] ?? 'Status diperbarui'),
          backgroundColor:
              resp.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
      if (resp.statusCode == 200) _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Detail Pengguna',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            _detailRow('Nama', user['name'] ?? '-'),
            _detailRow('NIK', user['nik'] ?? '-'),
            _detailRow('No. HP', user['no_hp'] ?? '-'),
            _detailRow('Email', user['email'] ?? '-'),
            _detailRow('Role', (user['role'] ?? '-').toString().toUpperCase()),
            _detailRow(
                'Status',
                user['is_active'] == true || user['is_active'] == 1
                    ? 'Aktif'
                    : 'Nonaktif'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 72,
              child: Text('$label:',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54))),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildSearch(),
          _buildRoleFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          _search = v;
          _applyFilter();
        },
        decoration: InputDecoration(
          hintText: 'Cari nama, NIK, atau No. HP...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search = '';
                    _applyFilter();
                  })
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _roles.map((r) {
            final selected = _filterRole == r;
            final count = r == 'Semua'
                ? _users.length
                : _users.where((u) => u['role'] == r).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected,
                label: Text('$r ($count)'),
                selectedColor: _primary.withOpacity(0.15),
                checkmarkColor: _primary,
                labelStyle: TextStyle(
                  color: selected ? _primary : Colors.black54,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (_) {
                  setState(() => _filterRole = r);
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Gagal memuat pengguna',
                  style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('Tidak ada pengguna ditemukan',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _buildCard(_filtered[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> user) {
    final isActive = user['is_active'] == true || user['is_active'] == 1;
    final role = (user['role'] ?? 'masyarakat').toString();

    Color roleColor;
    switch (role) {
      case 'admin':
        roleColor = const Color(0xFF0D47A1);
        break;
      case 'sekretaris':
        roleColor = const Color(0xFF6A1B9A);
        break;
      case 'kepala_desa':
        roleColor = const Color(0xFF4E342E);
        break;
      default:
        roleColor = const Color(0xFF00695C);
    }

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
        onTap: () => _showDetail(user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    isActive ? roleColor.withOpacity(0.15) : Colors.grey[200],
                child: Icon(
                  role == 'admin'
                      ? Icons.admin_panel_settings_rounded
                      : role == 'sekretaris'
                          ? Icons.manage_accounts_rounded
                          : role == 'kepala_desa'
                              ? Icons.account_balance_rounded
                              : Icons.person_rounded,
                  color: isActive ? roleColor : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['no_hp'] ?? user['email'] ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                color: roleColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                                fontSize: 10,
                                color: isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (role != 'admin')
                IconButton(
                  icon: Icon(
                    isActive ? Icons.block : Icons.check_circle_outline,
                    color: isActive ? Colors.red : Colors.green,
                    size: 22,
                  ),
                  tooltip:
                      isActive ? 'Nonaktifkan' : 'Aktifkan',
                  onPressed: () => _toggleStatus(user),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
