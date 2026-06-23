import 'package:flutter/material.dart';
import '../../../models/resep_model.dart';
import '../../../service/api_service.dart';
import '../../../widgets/bottom_navbar.dart';
import 'tambah_resep_screen.dart';

class ResepSayaScreen extends StatefulWidget {
  const ResepSayaScreen({super.key});

  @override
  State<ResepSayaScreen> createState() => _ResepSayaScreenState();
}

class _ResepSayaScreenState extends State<ResepSayaScreen> {
  List<ResepModel> _resepList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResepSaya();
  }

  Future<void> _loadResepSaya() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService().getResepSaya();
      if (result['success'] == true && mounted) {
        final List data = result['data'] ?? [];
        setState(() {
          _resepList = data.map((e) => ResepModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _hapusResep(ResepModel resep) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Resep'),
        content: Text('Hapus "${resep.nama}" dari resep kamu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final result = await ApiService().hapusResep(resep.id);
      if (result['success'] == true && mounted) {
        setState(() => _resepList.removeWhere((r) => r.id == resep.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resep berhasil dihapus'),
            backgroundColor: Color(0xFFD4865A),
          ),
        );
      }
    } catch (_) {}
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
                  const SizedBox(width: 16),
                  const Text(
                    'Resep Saya',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E6D3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_resepList.length} resep',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4865A),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── CONTENT ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4865A)))
                  : _resepList.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: const Color(0xFFD4865A),
                          onRefresh: _loadResepSaya,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: _resepList.length,
                            itemBuilder: (context, i) {
                              final resep = _resepList[i];
                              // ✅ Card custom dengan edit/hapus di kanan tengah
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCardResepSaya(resep),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahResepScreen()),
          );
          if (added == true) _loadResepSaya();
        },
        backgroundColor: const Color(0xFFD4865A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Resep',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const BottomNavbar(currentIndex: 3),
    );
  }

  // ✅ Card khusus Resep Saya — tanpa favorit, edit/hapus di kanan tengah
  Widget _buildCardResepSaya(ResepModel resep) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail-resep', arguments: resep),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gambar
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                resep.gambar,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: const Color(0xFFF5E6D3),
                  child: const Icon(Icons.restaurant, color: Color(0xFFD4865A), size: 36),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resep.nama,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: Color(0xFFFFA500)),
                        const SizedBox(width: 3),
                        Text(resep.rating.toString(),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                        const SizedBox(width: 10),
                        const Icon(Icons.access_time, size: 13, color: Color(0xFF888888)),
                        const SizedBox(width: 3),
                        Text('${resep.waktuMenit} menit',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Tombol edit & hapus di kanan, vertikal, rata tengah
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AksiButton(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFFD4865A),
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TambahResepScreen(resepEdit: resep),
                        ),
                      );
                      if (updated == true) _loadResepSaya();
                    },
                  ),
                  const SizedBox(height: 8),
                  _AksiButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onTap: () => _hapusResep(resep),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada resep',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bagikan resep favoritmu ke semua orang!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TambahResepScreen()),
              );
              if (added == true) _loadResepSaya();
            },
            icon: const Icon(Icons.add),
            label: const Text('Buat Resep Pertama'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 46)),
          ),
        ],
      ),
    );
  }
}

class _AksiButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AksiButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5E6D3),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}