import 'package:flutter/material.dart';
import '../../models/laporan_model.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'edit_profil.dart';
import 'ubah_password.dart';
import 'user_notifikasi.dart';
import 'pengaturan_notifikasi.dart';

class UserProfil extends StatefulWidget {
  const UserProfil({super.key});

  @override
  State<UserProfil> createState() => _UserProfilState();
}

class _UserProfilState extends State<UserProfil> {
  static const _primary = Color(0xFF1565C0);
  Map<String, String?> _user = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final local = await ApiService.getUserData();
    if (mounted) setState(() => _user = local);
    try {
      final remote = await ApiService.getProfile();
      if (remote != null && mounted) {
        await ApiService.saveUserData(
            remote.map((k, v) => MapEntry(k, v?.toString() ?? '')));
        final updated = await ApiService.getUserData();
        if (mounted) setState(() => _user = updated);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await ApiService.post('/logout', {});
      } catch (_) {}
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const SizedBox(height: 12),
                  _buildMenuCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final photo = _user['profile_photo'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: ClipOval(
              child: photo != null && photo.isNotEmpty
                  ? Image.network(
                      buildStorageUrl(ApiService.baseUrl, photo),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_rounded,
                      size: 52, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _user['name'] ?? 'Masyarakat',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Masyarakat',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informasi Akun',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _primary)),
            const Divider(height: 16),
            _infoRow(Icons.person_outline, 'Nama',
                _user['name'] ?? '-'),
            _infoRow(Icons.badge_outlined, 'NIK',
                _user['nik'] ?? '-'),
            _infoRow(Icons.phone_outlined, 'No. HP',
                _user['no_hp'] ?? '-'),
            _infoRow(Icons.email_outlined, 'Email',
                _user['email'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text('$label:',
                style:
                    const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
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
        child: Column(
          children: [
            _menuItem(Icons.edit_outlined, 'Edit Profil', Colors.blue,
                () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfil()),
                    ).then((_) => _load())),
            const Divider(height: 1, indent: 56),
            _menuItem(Icons.lock_outline, 'Ubah Password',
                const Color(0xFFE65100),
                () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UbahPassword()),
                    )),
            const Divider(height: 1, indent: 56),
            _menuItem(
                Icons.notifications_outlined, 'Notifikasi', Colors.teal,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UserNotifikasi()))),
            const Divider(height: 1, indent: 56),
            _menuItem(Icons.settings_outlined, 'Pengaturan Notifikasi',
                Colors.blueGrey,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PengaturanNotifikasi()))),
            const Divider(height: 1, indent: 56),
            _menuItem(
                Icons.info_outline, 'Tentang Aplikasi', Colors.blueGrey,
                () => showAboutDialog(
                      context: context,
                      applicationName: 'Pelaporan Keluhan',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          '© 2026 Desa Mandiangin Pasar\nKab. Sarolangun',
                    )),
            const Divider(height: 1, indent: 56),
            _menuItem(Icons.logout_rounded, 'Logout', Colors.red,
                _logout),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color == Colors.red ? Colors.red : Colors.black87)),
      trailing:
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
