class PesanModel {
  final int id;
  final int laporanId;
  final int userId;
  final String pesan;
  final String pengirimRole;
  final bool isRead;
  final DateTime createdAt;
  final String? userName;
  final String? userRole;

  PesanModel({
    required this.id,
    required this.laporanId,
    required this.userId,
    required this.pesan,
    required this.pengirimRole,
    required this.isRead,
    required this.createdAt,
    this.userName,
    this.userRole,
  });

  factory PesanModel.fromJson(Map<String, dynamic> json) {
    return PesanModel(
      id: json['id'] ?? 0,
      laporanId: json['laporan_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      pesan: json['pesan'] ?? '',
      pengirimRole: json['pengirim_role'] ?? 'masyarakat',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      userName: json['user']?['name'],
      userRole: json['user']?['role'],
    );
  }
}
