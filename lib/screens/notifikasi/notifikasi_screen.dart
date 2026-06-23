import 'package:flutter/material.dart';
import '../../service/fcm_service.dart';
import '../../service/api_service.dart';
import '../../widgets/bottom_navbar.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _notifikasi = [];

  @override
  void initState() {
    super.initState();
    _loadNotifikasi();
    _listenFcm();
  }

  @override
  void dispose() {
    FcmService().onNotifikasiMasuk = null;
    super.dispose();
  }

  // ── Format waktu dari Firestore Timestamp atau ISO string ─────────────────
  String _formatWaktu(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      DateTime dt;
      if (createdAt is Map && createdAt['_seconds'] != null) {
        // Firestore Timestamp dari Node.js (format: {_seconds: ..., _nanoseconds: ...})
        dt = DateTime.fromMillisecondsSinceEpoch(
            (createdAt['_seconds'] as int) * 1000);
      } else {
        dt = DateTime.parse(createdAt.toString());
      }
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  // ── Load dari API ──────────────────────────────────────────────────────────
  Future<void> _loadNotifikasi() async {
    debugPrint('🔍 userId: ${ApiService().userId}');
    try {
      final result = await ApiService().getNotifikasi();
      debugPrint('🔍 result: $result');
      if (result['success'] == true && mounted) {
        final List data = result['data'] ?? [];
        setState(() {
          _notifikasi.clear();
          _notifikasi.addAll(data.map((n) => {
                'id': n['id'].toString(),
                'judul': n['judul'] ?? '',
                'pesan': n['pesan'] ?? '',
                'tipe': n['tipe'] ?? 'info',
                'waktu': _formatWaktu(n['created_at']), // ← fix: pakai created_at
                'dibaca': n['dibaca'] == 1 || n['dibaca'] == true,
              }));
        });
      }
    } catch (e) {
      debugPrint('Gagal load notifikasi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Listen FCM realtime ────────────────────────────────────────────────────
  void _listenFcm() {
    FcmService().onNotifikasiMasuk = (notifBaru) {
      if (mounted) {
        setState(() {
          _notifikasi.insert(0, {
            ...notifBaru,
            'waktu': 'Baru saja',
            'dibaca': false,
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 ${notifBaru['judul']}'),
            backgroundColor: const Color(0xFFD4865A),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
    };
  }

  // ── Tandai 1 notif dibaca ─────────────────────────────────────────────────
  Future<void> _tandaiDibaca(String id) async {
    setState(() {
      final idx = _notifikasi.indexWhere((n) => n['id'] == id);
      if (idx != -1) _notifikasi[idx]['dibaca'] = true;
    });
    try {
      await ApiService().bacaNotifikasi(id);
    } catch (_) {}
  }

  // ── Tandai semua dibaca ────────────────────────────────────────────────────
  Future<void> _tandaiSemuaDibaca() async {
    setState(() {
      for (var n in _notifikasi) {
        n['dibaca'] = true;
      }
    });
    try {
      await ApiService().bacaSemuaNotifikasi();
    } catch (_) {}
  }

  int get _belumDibaca => _notifikasi.where((n) => !n['dibaca']).length;

  // ── Helper icon & warna berdasarkan tipe ──────────────────────────────────
  IconData _getIcon(String tipe) {
    switch (tipe) {
      case 'resep':   return Icons.restaurant_menu;
      case 'promo':   return Icons.local_offer_outlined;
      case 'tips':    return Icons.lightbulb_outline;
      default:        return Icons.notifications_outlined;
    }
  }

  Color _getColor(String tipe) {
    switch (tipe) {
      case 'resep':   return const Color(0xFFD4865A);
      case 'promo':   return const Color(0xFF4CAF50);
      case 'tips':    return const Color(0xFFFFA500);
      default:        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const Spacer(),
                  // Badge jumlah belum dibaca
                  if (_belumDibaca > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4865A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_belumDibaca baru',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _tandaiSemuaDibaca,
                      child: const Text(
                        'Baca semua',
                        style: TextStyle(
                          color: Color(0xFFD4865A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── BODY ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFD4865A)),
                    )
                  : _notifikasi.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 72, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada notifikasi',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFD4865A),
                          onRefresh: _loadNotifikasi,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            itemCount: _notifikasi.length,
                            itemBuilder: (context, i) {
                              final notif = _notifikasi[i];
                              final bool belumDibaca = !notif['dibaca'];
                              return GestureDetector(
                                onTap: () => _tandaiDibaca(notif['id']),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: belumDibaca
                                        ? const Color(0xFFFFF3EC)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: belumDibaca
                                          ? const Color(0xFFD4865A)
                                              .withValues(alpha: 0.3)
                                          : Colors.grey.shade100,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Icon tipe
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _getColor(notif['tipe'])
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIcon(notif['tipe']),
                                          color: _getColor(notif['tipe']),
                                          size: 22,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Konten
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif['judul'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: belumDibaca
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                      color: const Color(
                                                          0xFF2D2D2D),
                                                    ),
                                                  ),
                                                ),
                                                if (belumDibaca)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color:
                                                          Color(0xFFD4865A),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notif['pesan'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            // Waktu — sekarang tampil dengan benar
                                            if (notif['waktu'].isNotEmpty)
                                              Text(
                                                notif['waktu'],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavbar(currentIndex: 2),
    );
  }
}