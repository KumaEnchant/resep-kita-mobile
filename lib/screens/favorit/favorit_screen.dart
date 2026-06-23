import 'package:flutter/material.dart';
import '../../models/resep_model.dart';
import '../../service/api_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/card_resep.dart';

class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  List<ResepModel> _favoritList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorit();
  }

  Future<void> _loadFavorit() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService().getFavorit();
      if (result['success'] == true && mounted) {
        final List data = result['data'] ?? [];
        setState(() {
          _favoritList = data.map((e) => ResepModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorit(ResepModel resep) async {
    await ApiService().toggleFavorit(resep.id);
    _loadFavorit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Resep Favorit',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E6D3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_favoritList.length} resep',
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
                      child: CircularProgressIndicator(
                          color: Color(0xFFD4865A)),
                    )
                  : _favoritList.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: const Color(0xFFD4865A),
                          onRefresh: _loadFavorit,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _favoritList.length,
                            itemBuilder: (context, i) {
                              final resep = _favoritList[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CardResep(
                                  resep: resep,
                                  isHorizontal: true,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/detail-resep',
                                    arguments: resep,
                                  ),
                                  onFavoritTap: () => _toggleFavorit(resep),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      // ✅ Fix 1: currentIndex 3 = tab Profil
      bottomNavigationBar: const BottomNavbar(currentIndex: 3),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada resep favorit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap ikon ❤️ di resep yang kamu suka!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Kembali'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(180, 46),
            ),
          ),
        ],
      ),
    );
  }
}