import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/pesan_model.dart';
import '../../services/api_service.dart';

class ChatLaporanScreen extends StatefulWidget {
  final int laporanId;
  final String judulLaporan;

  const ChatLaporanScreen({
    super.key,
    required this.laporanId,
    required this.judulLaporan,
  });

  @override
  State<ChatLaporanScreen> createState() => _ChatLaporanScreenState();
}

class _ChatLaporanScreenState extends State<ChatLaporanScreen> {
  static const _primary = Color(0xFF1565C0);

  final TextEditingController _pesanCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<PesanModel> _pesan = [];
  bool _isLoading = false;
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPesan();
    // Auto refresh cepat agar chat terasa real-time.
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadPesan(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pesanCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPesan({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final data = await ApiService.getPesanLaporan(widget.laporanId);
      final messages = data.map((json) => PesanModel.fromJson(json)).toList();
      final previousCount = _pesan.length;
      final latest = messages.isNotEmpty ? messages.last : null;

      if (mounted) {
        setState(() {
          _pesan = messages;
          _isLoading = false;
        });

        if (silent &&
            messages.length > previousCount &&
            latest?.pengirimRole != 'masyarakat') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesan baru dari petugas'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _kirimPesan() async {
    final pesan = _pesanCtrl.text.trim();
    if (pesan.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final response = await ApiService.kirimPesan(widget.laporanId, pesan);
      if (!mounted) return;
      
      if (response.statusCode == 201) {
        _pesanCtrl.clear();
        await _loadPesan(silent: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.errorMessage(response))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _roleName(String role) {
    switch (role) {
      case 'sekretaris':
        return 'Sekretaris';
      case 'kepala_desa':
        return 'Kepala Desa';
      default:
        return 'Admin';
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Kemarin ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month]} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat Laporan', style: TextStyle(fontSize: 16)),
            Text(
              widget.judulLaporan,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pesan.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pesan',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kirim pesan pertama untuk memulai percakapan',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _pesan.length,
                        itemBuilder: (context, index) {
                          final msg = _pesan[index];
                          final isMyMessage =
                              msg.pengirimRole == 'masyarakat';
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isMyMessage
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMyMessage) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.blue[700],
                                    child: const Icon(Icons.support_agent,
                                        size: 18, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMyMessage
                                          ? _primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(14),
                                        topRight: const Radius.circular(14),
                                        bottomLeft: Radius.circular(
                                            isMyMessage ? 14 : 4),
                                        bottomRight: Radius.circular(
                                            isMyMessage ? 4 : 14),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!isMyMessage) ...[
                                          Text(
                                            msg.userName ?? _roleName(msg.pengirimRole),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[800],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        Text(
                                          msg.pesan,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isMyMessage
                                                ? Colors.white
                                                : Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(msg.createdAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMyMessage
                                                ? Colors.white70
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMyMessage) ...[
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(Icons.person,
                                        size: 18, color: Colors.grey[700]),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pesanCtrl,
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _primary,
                    radius: 24,
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            onPressed: _kirimPesan,
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
