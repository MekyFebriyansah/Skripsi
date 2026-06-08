// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';
import 'user/user_main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _primary = Color(0xFF1565C0);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _noHpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/register', {
        'name': _nameController.text.trim(),
        'nik': _nikController.text.trim(),
        'no_hp': _noHpController.text.trim(),
        if (_emailController.text.trim().isNotEmpty)
          'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode == 201) {
        if (data['token'] != null) {
          await ApiService.saveToken(data['token']);
        }
        if (data['user'] != null) {
          await ApiService.saveUserData(data['user']);
        }

        if (!mounted) return;
        _showSnackBar("Registrasi berhasil!");
        // Sinkronkan FCM token ke server agar push notification langsung aktif
        PushNotificationService.syncTokenToServer();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserMain()),
          (_) => false,
        );
      } else {
        _showSnackBar(
          ApiService.errorMessage(response, fallback: 'Registrasi gagal'),
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar("Koneksi gagal: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Daftar Akun"),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    size: 52, color: _primary),
              ),
              const SizedBox(height: 20),
              const Text(
                "Buat Akun Masyarakat",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Gunakan data yang valid agar pengaduan dapat ditindaklanjuti.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 28),
              TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration:
                      _inputDecoration("Nama Lengkap", Icons.person_outline),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Wajib diisi" : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration("NIK", Icons.badge_outlined),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return "Wajib diisi";
                    if (value.length != 16) return "NIK harus 16 digit";
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return "NIK hanya boleh angka";
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _noHpController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration("No. HP", Icons.phone_outlined),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return "Wajib diisi";
                    if (value.length < 10) return "No. HP tidak valid";
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration("Email", Icons.email_outlined),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                      return "Format email tidak valid";
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    "Password",
                    Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Wajib diisi";
                    if (v.length < 6) return "Minimal 6 karakter";
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: _inputDecoration(
                    "Konfirmasi Password",
                    Icons.lock_reset_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Wajib diisi";
                    if (v != _passwordController.text) {
                      return "Password tidak cocok";
                    }
                    return null;
                  }),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("DAFTAR"),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Sudah punya akun? "),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Masuk"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
    );
  }
}
