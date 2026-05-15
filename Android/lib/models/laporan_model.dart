/// Helper: bangun URL aman untuk file di storage publik Laravel.
/// Spasi dan karakter khusus di nama file di-encode supaya `Image.network`
/// tidak gagal load.
String buildStorageUrl(String baseApiUrl, String path) {
  final base = baseApiUrl.replaceAll('/api', '');
  // Encode tiap segmen path agar spasi & karakter unicode aman.
  final segments = path.split('/').map(Uri.encodeComponent).join('/');
  return '$base/storage/$segments';
}

class LaporanModel {
  final int id;
  final String judul;
  final String? kategori;
  final int? kategoriId;
  final String deskripsi;
  final String status;
  final String? tanggapan;
  final String? fotoPengaduan;
  final DateTime? fotoPengaduanAt;
  final String? fotoProses;
  final DateTime? fotoProsesAt;
  final String? fotoBukti;
  final DateTime? fotoBuktiAt;
  final String? namaUser;
  final String? emailUser;
  final String? nikUser;
  final String? noHpUser;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  LaporanModel({
    required this.id,
    required this.judul,
    this.kategori,
    this.kategoriId,
    required this.deskripsi,
    required this.status,
    this.tanggapan,
    this.fotoPengaduan,
    this.fotoPengaduanAt,
    this.fotoProses,
    this.fotoProsesAt,
    this.fotoBukti,
    this.fotoBuktiAt,
    this.namaUser,
    this.emailUser,
    this.nikUser,
    this.noHpUser,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  /// Normalisasi field path foto: anggap empty string sama dengan null
  /// agar UI tidak membuat URL "/storage/" tanpa path.
  static String? _toFotoPath(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory LaporanModel.fromJson(Map<String, dynamic> json) {
    // Kategori bisa berupa String langsung atau nested object dari relasi
    String? kategoriStr;
    int? kategoriId;
    if (json['kategori'] is Map) {
      kategoriStr = json['kategori']['nama_kategori'];
      kategoriId = _toInt(json['kategori']['id']);
    } else if (json['kategori'] is String) {
      kategoriStr = json['kategori'];
    }
    if (json['kategori_id'] != null) kategoriId = _toInt(json['kategori_id']);

    // User info dari relasi atau flat field
    final user = json['user'] as Map<String, dynamic>?;

    return LaporanModel(
      id: _toInt(json['id']) ?? 0,
      judul: json['judul'] ?? '',
      kategori: kategoriStr,
      kategoriId: kategoriId,
      deskripsi: json['deskripsi'] ?? '',
      status: json['status'] ?? 'Belum Ditangani',
      tanggapan: json['tanggapan'],
      fotoPengaduan: _toFotoPath(json['foto_pengaduan']),
      fotoPengaduanAt: _toDateTime(json['foto_pengaduan_at']),
      fotoProses: _toFotoPath(json['foto_proses']),
      fotoProsesAt: _toDateTime(json['foto_proses_at']),
      fotoBukti: _toFotoPath(json['foto_bukti']),
      fotoBuktiAt: _toDateTime(json['foto_bukti_at']),
      namaUser: user?['name'] ?? json['nama_user'],
      emailUser: user?['email'],
      nikUser: user?['nik'],
      noHpUser: user?['no_hp'],
      createdAt: _toDateTime(json['created_at']) ?? DateTime.now(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }
}
