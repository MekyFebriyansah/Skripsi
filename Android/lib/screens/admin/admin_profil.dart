import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

class AdminProfil extends StatefulWidget {
  const AdminProfil({super.key});

  @override
  State<AdminProfil> createState() => _AdminProfilState();
}

class _AdminProfilState extends State<AdminProfil> {
  static const _primary = Color(0xFF0D47A1);

  Map<String, String?> _user = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    // Ambil dari SharedPreferences terlebih dahulu (cepat)
    final local = await ApiService.getUserData();
    if (mounted) setState(() => _user = local);

    // Refresh dari API
    try {
      final remote = await ApiService.getProfile();
      if (remote != null && mounted) {
        await ApiService.saveUserData(remote.map((k, v) => MapEntry(k, v?.toString() ?? '')));
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

  void _showUbahPasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    bool obsOld = true, obsNew = true, obsConf = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Ubah Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pwField(
                  ctrl: oldCtrl,
                  label: 'Password Lama',
                  obscure: obsOld,
                  toggle: () => setDlg(() => obsOld = !obsOld),
                ),
                const SizedBox(height: 12),
                _pwField(
                  ctrl: newCtrl,
                  label: 'Password Baru',
                  obscure: obsNew,
                  toggle: () => setDlg(() => obsNew = !obsNew),
                ),
                const SizedBox(height: 12),
                _pwField(
                  ctrl: confirmCtrl,
                  label: 'Konfirmasi Password Baru',
                  obscure: obsConf,
                  toggle: () => setDlg(() => obsConf = !obsConf),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Konfirmasi password tidak cocok')),
                        );
                        return;
                      }
                      setDlg(() => loading = true);
                      try {
                        final resp = await ApiService.changePassword(
                          oldCtrl.text,
                          newCtrl.text,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        final body = jsonDecode(resp.body);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(body['message'] ??
                                (resp.statusCode == 200
                                    ? 'Password berhasil diubah'
                                    : 'Gagal mengubah password')),
                            backgroundColor: resp.statusCode == 200
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      } catch (e) {
                        setDlg(() => loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: _primary),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField({
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profil Admin'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadProfile),
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
                  _buildMenuCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
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
            radius: 48,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.admin_panel_settings_rounded,
                size: 56, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            _user['name'] ?? 'Admin',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Administrator',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
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
            _infoRow(
                Icons.shield_outlined, 'Role', 'Administrator'),
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

  Widget _buildMenuCard() {
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
            _menuItem(
              icon: Icons.lock_outline,
              label: 'Ubah Password',
              color: _primary,
              onTap: _showUbahPasswordDialog,
            ),
            const Divider(height: 1, indent: 56),
            _menuItem(
              icon: Icons.info_outline,
              label: 'Tentang Aplikasi',
              color: Colors.blueGrey,
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Pelaporan Keluhan',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    '© 2026 Desa Mandiangin Pasar, Kab. Sarolangun',
              ),
            ),
            const Divider(height: 1, indent: 56),
            _menuItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: Colors.red,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
              fontWeight: FontWeight.w500,
              color: color == Colors.red ? Colors.red : Colors.black87)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
