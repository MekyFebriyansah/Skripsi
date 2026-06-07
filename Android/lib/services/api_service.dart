import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _timeout = Duration(seconds: 20);

  // ──────────────── KONFIGURASI BASE URL ────────────────
  // Ganti _lanHost jika IP laptop (server Laragon) berubah.
  // Cek IP dengan: `ipconfig` di Windows -> ambil IPv4 dari Wi-Fi.
  // Pastikan HP & laptop terhubung Wi-Fi yang SAMA, dan Laragon di-set
  // listen di 0.0.0.0:8000 (bukan hanya 127.0.0.1).
  static const _lanHost = '192.168.1.22';
  static const _port = 8000;

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured.endsWith('/')
          ? configured.substring(0, configured.length - 1)
          : configured;
    }
    if (kIsWeb) return "http://localhost:$_port/api";

    // Android: jika emulator pakai 10.0.2.2, jika HP fisik pakai IP LAN laptop.
    if (Platform.isAndroid) {
      // Heuristik sederhana: kalau ENV ANDROID_EMU=true -> emulator.
      // Default-nya kita pakai IP LAN supaya jalan di HP fisik (kasus utama).
      const isEmu = bool.fromEnvironment('ANDROID_EMU', defaultValue: false);
      if (isEmu) return "http://10.0.2.2:$_port/api";
      return "http://$_lanHost:$_port/api";
    }

    if (Platform.isIOS) return "http://$_lanHost:$_port/api";
    return "http://$_lanHost:$_port/api";
  }

  // ──────────────── TOKEN & USER DATA ────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) return prefs.getString(_tokenKey);

    try {
      return await _secureStorage.read(key: _tokenKey) ??
          prefs.getString(_tokenKey);
    } catch (_) {
      return prefs.getString(_tokenKey);
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: _tokenKey, value: token);
      } catch (_) {
        // SharedPreferences fallback tetap dipakai jika secure storage gagal.
      }
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user['name'] ?? '');
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setString('user_nik', user['nik'] ?? '');
    await prefs.setString('user_no_hp', user['no_hp'] ?? '');
    await prefs.setString('user_role', user['role'] ?? '');
    await prefs.setString('user_profile_photo', user['profile_photo'] ?? '');
    await prefs.setString('user_id', (user['id'] ?? '').toString());
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('user_id'),
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
      'nik': prefs.getString('user_nik'),
      'no_hp': prefs.getString('user_no_hp'),
      'role': prefs.getString('user_role'),
      'profile_photo': prefs.getString('user_profile_photo'),
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: _tokenKey);
      } catch (_) {}
    }
  }

  // ──────────────── HEADERS ────────────────
  static Future<Map<String, String>> getHeaders(
      {bool multipart = false}) async {
    final token = await getToken();
    return {
      'Accept': 'application/json',
      if (!multipart) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ──────────────── HTTP METHODS ────────────────
  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final response =
        await http.get(url, headers: await getHeaders()).timeout(_timeout);
    _log("GET", endpoint, response);
    return response;
  }

  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final response = await http
        .post(
          url,
          headers: await getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    _log("POST", endpoint, response);
    return response;
  }

  static Future<http.Response> put(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final response = await http
        .put(
          url,
          headers: await getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    _log("PUT", endpoint, response);
    return response;
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final response =
        await http.delete(url, headers: await getHeaders()).timeout(_timeout);
    _log("DELETE", endpoint, response);
    return response;
  }

  // ──────────────── LAPORAN ────────────────
  static Future<List<dynamic>> getAllLaporan() async {
    final response = await get('/laporan');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Gagal memuat laporan: ${response.body}');
  }

  static Future<List<dynamic>> getLaporanSaya() async {
    final response = await get('/laporan/saya');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Gagal memuat laporan: ${response.body}');
  }

  static Future<http.Response> updateLaporan(
    int id,
    String status,
    String? tanggapan,
    dynamic fotoProses, // Support File (mobile) or XFile (cross-platform)
    dynamic fotoBukti, // Support File (mobile) or XFile (cross-platform)
  ) async {
    final url = Uri.parse("$baseUrl/laporan/$id");
    // Laravel/PHP lebih stabil menerima upload file via POST + _method=PUT.
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(await getHeaders(multipart: true));

    request.fields['_method'] = 'PUT';
    request.fields['status'] = status;
    if (tanggapan != null && tanggapan.isNotEmpty) {
      request.fields['tanggapan'] = tanggapan;
    }

    if (fotoProses != null) {
      if (fotoProses is XFile) {
        final bytes = await fotoProses.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_proses',
            bytes,
            filename: fotoProses.name,
          ),
        );
      } else if (fotoProses is File) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_proses', fotoProses.path),
        );
      }
    }

    if (fotoBukti != null) {
      if (fotoBukti is XFile) {
        final bytes = await fotoBukti.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_bukti',
            bytes,
            filename: fotoBukti.name,
          ),
        );
      } else if (fotoBukti is File) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_bukti', fotoBukti.path),
        );
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _log("PUT (multipart)", "/laporan/$id", response);
    return response;
  }

  static Future<http.Response> createLaporan({
    required String judul,
    required int kategoriId,
    required String deskripsi,
    double? latitude,
    double? longitude,
    dynamic fotoPengaduan, // Support File (mobile) or XFile (cross-platform)
  }) async {
    final url = Uri.parse("$baseUrl/laporan");

    if (fotoPengaduan == null) {
      return await post('/laporan', {
        'judul': judul,
        'kategori_id': kategoriId,
        'deskripsi': deskripsi,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
    }

    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(await getHeaders(multipart: true));
    request.fields['judul'] = judul;
    request.fields['kategori_id'] = kategoriId.toString();
    request.fields['deskripsi'] = deskripsi;
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();

    if (fotoPengaduan is XFile) {
      final bytes = await fotoPengaduan.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto_pengaduan',
          bytes,
          filename: fotoPengaduan.name,
        ),
      );
    } else if (fotoPengaduan is File) {
      request.files.add(await http.MultipartFile.fromPath(
        'foto_pengaduan',
        fotoPengaduan.path,
      ));
    }

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    _log("POST (multipart)", "/laporan", response);
    return response;
  }

  // ──────────────── KATEGORI ────────────────
  static Future<List<dynamic>> getKategori() async {
    final response = await get('/kategori');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Gagal memuat kategori: ${response.body}');
  }

  static Future<http.Response> addKategori(
      String namaKategori, String? deskripsi) async {
    return await post('/kategori', {
      'nama_kategori': namaKategori,
      if (deskripsi != null && deskripsi.isNotEmpty) 'deskripsi': deskripsi,
    });
  }

  static Future<http.Response> deleteKategori(int id) async {
    return await delete('/kategori/$id');
  }

  // ──────────────── USERS (admin) ────────────────
  static Future<List<dynamic>> getUsers() async {
    final response = await get('/users');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Gagal memuat pengguna: ${response.body}');
  }

  static Future<http.Response> toggleUserStatus(int id) async {
    return await put('/users/$id/toggle-status', {});
  }

  // ──────────────── CHAT / PESAN ────────────────
  static Future<List<dynamic>> getPesanLaporan(int laporanId) async {
    final response = await get('/laporan/$laporanId/pesan');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Gagal memuat pesan: ${response.body}');
  }

  static Future<http.Response> kirimPesan(int laporanId, String pesan) async {
    return await post('/laporan/$laporanId/pesan', {'pesan': pesan});
  }

  static Future<int> getUnreadCount() async {
    final response = await get('/pesan/unread-count');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['unread_count'] ?? 0;
    }
    return 0;
  }

  static Future<List<dynamic>> getPesanNotifikasi() async {
    final response = await get('/pesan/notifikasi');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Gagal memuat notifikasi pesan: ${response.body}');
  }

  static Future<http.Response> updateFcmToken(String fcmToken) async {
    return await post('/me/fcm-token', {'fcm_token': fcmToken});
  }

  // ──────────────── PROFIL ────────────────
  static Future<Map<String, dynamic>?> getProfile() async {
    final response = await get('/me');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<http.Response> updateProfile(Map<String, dynamic> data) async {
    return await put('/me/profile', data);
  }

  static Future<http.Response> updateProfilePhoto(dynamic profilePhoto) async {
    final url = Uri.parse("$baseUrl/me/profile-photo");
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(await getHeaders(multipart: true));

    if (profilePhoto is XFile) {
      final bytes = await profilePhoto.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'profile_photo',
        bytes,
        filename: profilePhoto.name,
      ));
    } else if (profilePhoto is File) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_photo', profilePhoto.path),
      );
    }

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    _log("POST (multipart)", "/me/profile-photo", response);
    return response;
  }

  static Future<http.Response> forgotPassword({
    required String identifier,
    required String noHp,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await post('/forgot-password', {
      'identifier': identifier,
      'no_hp': noHp,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  static Future<http.Response> changePassword(
      String currentPassword, String newPassword) async {
    return await put('/me/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    });
  }

  static Map<String, dynamic> decodeBody(http.Response response) {
    if (response.body.isEmpty) return {};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
  }

  static String errorMessage(http.Response response,
      {String fallback = 'Terjadi kesalahan'}) {
    try {
      final body = decodeBody(response);
      if (body['message'] != null) return body['message'].toString();
      if (body['errors'] is Map) {
        final errors = body['errors'] as Map;
        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .map((e) => e.toString())
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }
    } catch (_) {}
    return fallback;
  }

  // ──────────────── LOGGER ────────────────
  static void _log(String method, String endpoint, http.Response response) {
    if (kDebugMode) {
      debugPrint("[$method] $endpoint → ${response.statusCode}");
      if (response.statusCode >= 400) {
        debugPrint("Body: ${response.body}");
      }
    }
  }
}
