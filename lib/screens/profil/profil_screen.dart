import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../service/api_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../profil/edit_profil_screen.dart';
import '../profil/bantuan_screen.dart';
import '../profil/tentang_aplikasi_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String get _nama    => ApiService().userName  ?? 'User';
  String get _email   => ApiService().userEmail ?? '-';
  String get _inisial => _nama.isNotEmpty ? _nama[0].toUpperCase() : 'U';

  int     _jumlahFavorit   = 0;
  int     _jumlahResepSaya = 0;
  String  _username        = '';
  String  _bio             = '';
  String? _fotoUrl;
  bool    _loaded          = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) _loadData();
    _loaded = true;
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService().getUser(),
        ApiService().getResepSaya(),
      ]);
      if (mounted) {
        final userData = results[0]['data'];
        setState(() {
          _jumlahFavorit   = userData?['jumlah_favorit']   ?? 0;
          _jumlahResepSaya = (results[1]['data'] as List?)?.length ?? 0;
          _username        = userData?['username'] ?? '';
          _bio             = userData?['bio']      ?? '';
          _fotoUrl         = userData?['foto_url'] ?? userData?['photo_url'];
        });
      }
    } catch (_) {}
  }

  void _refreshProfil() {
    _loadData();
    setState(() {});
  }

  // ✅ Render avatar dari _fotoUrl. Bisa berupa data URI base64 (opsi B)
  // atau URL biasa (kalau ada data lama dari sebelum migrasi).
  Widget _buildAvatar() {
    if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      if (_fotoUrl!.startsWith('data:')) {
        try {
          final bytes = base64Decode(_fotoUrl!.split(',').last);
          return CircleAvatar(
            radius: 46,
            backgroundImage: MemoryImage(bytes),
            backgroundColor: const Color(0xFFF5E6D3),
          );
        } catch (_) {
          return _buildDefaultAvatar();
        }
      }
      return CircleAvatar(
        radius: 46,
        backgroundImage: NetworkImage(_fotoUrl!),
        onBackgroundImageError: (_, __) {},
        backgroundColor: const Color(0xFFF5E6D3),
        child: null,
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 46,
      backgroundColor: const Color(0xFFF5E6D3),
      child: Text(
        _inisial,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD4865A),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── HEADER PROFIL ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Avatar
                    _buildAvatar(),
                    const SizedBox(height: 14),

                    // Nama
                    Text(
                      _nama,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),

                    // ✅ Username (kalau ada)
                    if (_username.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '@$_username',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFD4865A),
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      _email,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),

                    // ✅ Bio (kalau ada)
                    if (_bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4865A).withOpacity(0.2)),
                        ),
                        child: Text(
                          _bio,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── STAT: Favorit + Resep Saya ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/favorit')
                              .then((_) => _loadData()),
                          child: _StatCard(
                            icon: Icons.favorite,
                            nilai: '$_jumlahFavorit',
                            label: 'Resep Favorit',
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/resep-saya')
                              .then((_) => _loadData()),
                          child: _StatCard(
                            icon: Icons.restaurant_menu,
                            nilai: '$_jumlahResepSaya',
                            label: 'Resep Saya',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── MENU LIST ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ✅ Hapus menu "Resep Saya" dari sini
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          icon: Icons.person_outline,
                          label: 'Edit Profil',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfilScreen()),
                            );
                            if (result == true && mounted) _refreshProfil();
                          },
                        ),
                        _MenuItem(
                          icon: Icons.menu_book_outlined,
                          label: 'Katalog',
                          onTap: () => Navigator.pushNamed(context, '/katalog'),
                        ),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifikasi',
                          onTap: () => Navigator.pushNamed(context, '/notifikasi'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _MenuGroup(
                      items: [
                        _MenuItem(
                          icon: Icons.workspace_premium_outlined,
                          label: 'Berlangganan Premium',
                          onTap: () => Navigator.pushNamed(context, '/berlangganan'),
                          trailingWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4865A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Pro',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _MenuGroup(
                      items: [
                        _MenuItem(
                          icon: Icons.help_outline,
                          label: 'Bantuan',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BantuanScreen()),
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.info_outline,
                          label: 'Tentang Aplikasi',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TentangAplikasiScreen()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── TOMBOL KELUAR ──
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Keluar'),
                            content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  ApiService().logout();
                                  Navigator.pop(ctx);
                                  Navigator.pushReplacementNamed(context, '/');
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                child: const Text('Keluar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Keluar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavbar(currentIndex: 3),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String nilai;
  final String label;

  const _StatCard({
    required this.icon,
    required this.nilai,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4865A).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD4865A), size: 18),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                nilai,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Color(0xFFD4865A), size: 16),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailingWidget;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF5E6D3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFD4865A), size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D2D2D),
        ),
      ),
      trailing: trailingWidget ??
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }
}