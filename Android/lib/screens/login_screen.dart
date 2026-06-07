import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'user/user_main.dart';
import 'admin/admin_main.dart';
import 'pemerintah/pemerintah_dashboard.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _primary = Color(0xFF1565C0);

  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login({bool forceLogin = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/login', {
        'nik_or_hp': _identifierController.text.trim(),
        'password': _passwordController.text,
        if (forceLogin) 'force_login': true,
      });

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode == 200) {
        await ApiService.saveToken(data['token']);

        final user = data['user'];
        if (user != null) {
          await ApiService.saveUserData(user);
        }

        if (!mounted) return;
        _showSnackBar('Login berhasil!');

        final role = data['role'] as String?;
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminMain()),
          );
        } else if (role == 'sekretaris' || role == 'kepala_desa') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => PemerintahDashboard(role: role!)),
          );
        } else {
          // Default ke masyarakat
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserMain()),
          );
        }

      } else {
        if (response.statusCode == 403 && data['requires_force_login'] == true) {
          _showForceLoginDialog();
        } else {
          _showSnackBar(ApiService.errorMessage(response,
              fallback: 'Login gagal'), isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Koneksi gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForceLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Akun Sedang Digunakan'),
        content: const Text(
            'Akun ini sedang aktif di perangkat lain.\nApakah Anda ingin mengeluarkan perangkat tersebut secara paksa dan masuk di perangkat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _login(forceLogin: true);
            },
            child: const Text('Ya, Paksa Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.forum_rounded,
                        size: 52, color: _primary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Selamat Datang Kembali",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Masuk untuk melaporkan keluhan Anda",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // Input NIK / No HP / Email
                  TextFormField(
                    controller: _identifierController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: "NIK / No. HP / Email",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? "Field ini wajib diisi"
                            : null,
                  ),
                  const SizedBox(height: 20),

                  // Input Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? "Password wajib diisi"
                            : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: const Text('Lupa password?'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tombol Login
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("MASUK", style: TextStyle(fontSize: 18)),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum punya akun? "),
                      TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen())),
                        child: const Text("Daftar"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
