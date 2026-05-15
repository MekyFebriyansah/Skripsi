import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UbahPassword extends StatefulWidget {
  const UbahPassword({super.key});

  @override
  State<UbahPassword> createState() => _UbahPasswordState();
}

class _UbahPasswordState extends State<UbahPassword> {
  static const _primary = Color(0xFF1565C0);

  final _formKey = GlobalKey<FormState>();
  final _lamaCtrl = TextEditingController();
  final _baruCtrl = TextEditingController();
  final _konfCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obsLama = true, _obsBaru = true, _obsKonf = true;

  @override
  void dispose() {
    _lamaCtrl.dispose();
    _baruCtrl.dispose();
    _konfCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final resp = await ApiService.changePassword(
          _lamaCtrl.text, _baruCtrl.text);
      if (!mounted) return;
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Gagal mengubah password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Ubah Password'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: _primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Gunakan password yang kuat dan belum pernah digunakan sebelumnya.',
                        style: TextStyle(fontSize: 13, color: _primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
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
                    const Text('Ganti Password',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _primary)),
                    const Divider(height: 16),
                    _pwField(
                        ctrl: _lamaCtrl,
                        label: 'Password Lama *',
                        obscure: _obsLama,
                        toggle: () =>
                            setState(() => _obsLama = !_obsLama),
                        validator: (v) => v!.isEmpty
                            ? 'Password lama wajib diisi'
                            : null),
                    const SizedBox(height: 16),
                    _pwField(
                        ctrl: _baruCtrl,
                        label: 'Password Baru *',
                        obscure: _obsBaru,
                        toggle: () =>
                            setState(() => _obsBaru = !_obsBaru),
                        validator: (v) {
                          if (v!.isEmpty) return 'Password baru wajib diisi';
                          if (v.length < 6)
                            return 'Minimal 6 karakter';
                          return null;
                        }),
                    const SizedBox(height: 16),
                    _pwField(
                        ctrl: _konfCtrl,
                        label: 'Konfirmasi Password Baru *',
                        obscure: _obsKonf,
                        toggle: () =>
                            setState(() => _obsKonf = !_obsKonf),
                        validator: (v) {
                          if (v!.isEmpty) return 'Konfirmasi wajib diisi';
                          if (v != _baruCtrl.text)
                            return 'Password tidak cocok';
                          return null;
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _simpan,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_reset_rounded),
                  label: const Text('UBAH PASSWORD',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pwField({
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
      ),
      validator: validator,
    );
  }
}
