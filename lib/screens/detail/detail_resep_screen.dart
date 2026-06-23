import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/resep_model.dart';
import '../../service/api_service.dart';

class DetailResepScreen extends StatefulWidget {
  const DetailResepScreen({super.key});

  @override
  State<DetailResepScreen> createState() => _DetailResepScreenState();
}

class _DetailResepScreenState extends State<DetailResepScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorit = false;

  bool _isCheckingPremium = true;
  bool _userPremium = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cekStatusPremium();
  }

  Future<void> _cekStatusPremium() async {
    final premium = await ApiService().refreshPremiumStatus();
    if (mounted) {
      setState(() {
        _userPremium = premium;
        _isCheckingPremium = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Toggle favorit + update jumlahFavorit realtime (bukan dummy lagi)
  // Pattern sama seperti di katalog_screen: update optimis dulu,
  // baru panggil API, lalu rollback kalau gagal.
  Future<void> _toggleFavorit(ResepModel resep) async {
    final previousFavorit = _isFavorit;
    final previousJumlah = resep.jumlahFavorit;

    setState(() {
      _isFavorit = !_isFavorit;
      resep.isFavorit = _isFavorit;
      resep.jumlahFavorit += _isFavorit ? 1 : -1;
    });

    try {
      final result = await ApiService().toggleFavorit(resep.id);
      if (result['success'] != true && mounted) {
        setState(() {
          _isFavorit = previousFavorit;
          resep.isFavorit = previousFavorit;
          resep.jumlahFavorit = previousJumlah;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFavorit = previousFavorit;
          resep.isFavorit = previousFavorit;
          resep.jumlahFavorit = previousJumlah;
        });
      }
    }
  }

  Widget _avatarPembuat(ResepModel resep, {required double size}) {
    final foto = resep.fotoUser;
    if (foto.isNotEmpty) {
      if (foto.startsWith('data:')) {
        try {
          final bytes = base64Decode(foto.split(',').last);
          return CircleAvatar(
            radius: size / 2,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      } else {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: NetworkImage(foto),
          onBackgroundImageError: (_, __) {},
        );
      }
    }
    final initial = resep.namaUser.isNotEmpty ? resep.namaUser[0].toUpperCase() : 'D';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFF5E6D3),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFD4865A),
        ),
      ),
    );
  }

  // ── Card info pembuat resep (UPDATED) ──
  Widget _buildPembuatInfo(ResepModel resep) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8F4), Color(0xFFFFF3EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5D9C8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4865A).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar dengan gradient ring
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFE8956A), Color(0xFFD4865A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: _avatarPembuat(resep, size: 42),
            ),
          ),
          const SizedBox(width: 12),

          // Nama & label Chef
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4865A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Chef',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4865A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  resep.namaUser.isNotEmpty ? resep.namaUser : 'Dapur Umami',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Divider vertikal
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFE8C5B0),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Favorit count vertikal
          Column(
            children: [
              const Icon(Icons.favorite_rounded, size: 18, color: Colors.red),
              const SizedBox(height: 2),
              Text(
                '${resep.jumlahFavorit}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              Text(
                'Favorit',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resep = ModalRoute.of(context)?.settings.arguments as ResepModel?;
    if (resep == null) {
      return const Scaffold(body: Center(child: Text('Resep tidak ditemukan')));
    }
    _isFavorit = resep.isFavorit;

    final bool isLocked = resep.isPremium && !_userPremium && !_isCheckingPremium;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: Stack(
        children: [
          Column(
            children: [
              // ── HERO GAMBAR ──
              Stack(
                children: [
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Image.network(
                          resep.gambar,
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 280,
                            color: const Color(0xFFF5E6D3),
                            child: const Center(
                              child: Icon(Icons.restaurant, size: 80, color: Color(0xFFD4865A)),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.55),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      resep.nama,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (resep.isPremium) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFA500)),
                                  const SizedBox(width: 4),
                                  Text(
                                    resep.rating.toString(),
                                    style: const TextStyle(fontSize: 13, color: Colors.white),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.access_time_rounded, size: 16, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${resep.waktuMenit} menit',
                                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4865A),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      resep.kategori,
                                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                      ),
                    ),
                  ),

                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 12,
                    child: Row(
                      children: [
                        _GlassButton(
                          icon: _isFavorit ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavorit ? Colors.red : Colors.white,
                          onTap: () => _toggleFavorit(resep),
                        ),
                        const SizedBox(width: 8),
                        _GlassButton(
                          icon: Icons.share_rounded,
                          color: Colors.white,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── INFO PEMBUAT RESEP ──
              _buildPembuatInfo(resep),

              // ── TAB BAR ──
              Container(
                color: const Color(0xFFFDF6F0),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8956A), Color(0xFFD4865A)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade500,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'Bahan'),
                      Tab(text: 'Langkah'),
                      Tab(text: 'Info Gizi'),
                    ],
                  ),
                ),
              ),

              // ── TAB CONTENT ──
              Expanded(
                child: isLocked
                    ? const SizedBox.shrink()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _BahanTab(bahan: resep.bahan),
                          _LangkahTab(langkah: resep.langkah),
                          _InfoGiziTab(infoGizi: resep.infoGizi),
                        ],
                      ),
              ),

              // ── TOMBOL BAWAH ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          foregroundColor: const Color(0xFFD4865A),
                          side: const BorderSide(color: Color(0xFFD4865A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Keluar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (isLocked) {
                            Navigator.pushNamed(context, '/berlangganan');
                          } else {
                            Navigator.pushNamed(context, '/mulai-memasak', arguments: resep);
                          }
                        },
                        icon: Icon(
                          isLocked ? Icons.workspace_premium_rounded : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        label: Text(
                          isLocked ? 'Berlangganan Premium' : 'Mulai Memasak',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          backgroundColor: isLocked ? const Color(0xFFFFA500) : const Color(0xFFD4865A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── OVERLAY LOCK PREMIUM ──
          if (isLocked)
            Positioned(
              top: 280 + 38 + 16,
              left: 0,
              right: 0,
              bottom: 90,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, size: 32, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Resep Premium',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bahan, langkah, dan info gizi resep ini hanya tersedia untuk member Premium. Berlangganan sekarang untuk membuka resep ini dan semua resep premium lainnya.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── LOADING cek status premium ──
          if (_isCheckingPremium)
            Positioned.fill(
              top: 280,
              child: Container(
                color: const Color(0xFFFDF6F0).withOpacity(0.6),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4865A)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Glass button ──
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ── Tab Bahan ──
class _BahanTab extends StatelessWidget {
  final List<String> bahan;
  const _BahanTab({required this.bahan});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: bahan.length,
      itemBuilder: (context, i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E6D3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4865A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  bahan[i],
                  style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab Langkah ──
class _LangkahTab extends StatelessWidget {
  final List<String> langkah;
  const _LangkahTab({required this.langkah});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: langkah.length,
      itemBuilder: (context, i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8956A), Color(0xFFD4865A)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Langkah ${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD4865A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      langkah[i],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D2D2D),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab Info Gizi ──
class _InfoGiziTab extends StatelessWidget {
  final Map<String, dynamic> infoGizi;
  const _InfoGiziTab({required this.infoGizi});

  static const _giziMeta = [
    {'key': 'kalori',      'label': 'Kalori',      'icon': '🔥', 'color': 0xFFFF6B6B},
    {'key': 'protein',     'label': 'Protein',     'icon': '💪', 'color': 0xFF4ECDC4},
    {'key': 'lemak',       'label': 'Lemak',       'icon': '🥑', 'color': 0xFFFFE66D},
    {'key': 'karbohidrat', 'label': 'Karbohidrat', 'icon': '🌾', 'color': 0xFFA8E6CF},
    {'key': 'serat',       'label': 'Serat',       'icon': '🥦', 'color': 0xFF88D8B0},
    {'key': 'natrium',     'label': 'Natrium',     'icon': '🧂', 'color': 0xFFB8B8FF},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: _giziMeta.length,
      itemBuilder: (context, i) {
        final meta = _giziMeta[i];
        final color = Color(meta['color'] as int);
        final nilai = infoGizi[meta['key']]?.toString() ?? '-';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(meta['icon'] as String, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nilai,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    Text(
                      meta['label'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}