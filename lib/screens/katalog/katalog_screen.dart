import 'package:flutter/material.dart';
import '../../models/resep_model.dart';
import '../../service/api_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/card_resep.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  final _searchController = TextEditingController();
  String _selectedKategori = 'Semua';

  // ✅ label vs value Firestore dipisah
  final List<Map<String, String>> _kategoriList = [
    {'label': 'Semua',         'value': 'Semua'},
    {'label': 'Makanan Utama', 'value': 'Makanan'},
    {'label': 'Minuman',       'value': 'Minuman'},
    {'label': 'Kue',           'value': 'Kue'},
  ];

  List<ResepModel> _allResep = [];
  List<ResepModel> _filteredResep = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadResep();
    _searchController.addListener(() => _filterLokal(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResep() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final selectedValue = _kategoriList
          .firstWhere((k) => k['label'] == _selectedKategori,
              orElse: () => {'value': 'Semua'})['value'];

      final result = await ApiService().getResep(
        kategori: selectedValue != 'Semua' ? selectedValue : null,
      );

      if (result['success'] == true && mounted) {
        final List data = result['data'] ?? [];
        final list = data.map((e) => ResepModel.fromJson(e)).toList();
        setState(() {
          _allResep = list;
          _filteredResep = list;
          _isLoading = false;
        });
      } else {
        setState(() { _errorMsg = 'Gagal memuat resep'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMsg = 'Tidak dapat terhubung ke server'; _isLoading = false; });
    }
  }

  // ✅ Search sekarang juga mencakup nama pembuat/profil resep (namaUser)
  void _filterLokal(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filteredResep = _allResep.where((r) {
        return q.isEmpty ||
            r.nama.toLowerCase().contains(q) ||
            r.bahan.any((b) => b.toLowerCase().contains(q)) ||
            r.namaUser.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _toggleFavorit(int index) async {
    final resep = _filteredResep[index];
    final allIndex = _allResep.indexOf(resep);

    setState(() {
      _filteredResep[index].isFavorit = !_filteredResep[index].isFavorit;
      if (allIndex != -1) _allResep[allIndex].isFavorit = _filteredResep[index].isFavorit;
    });

    try {
      final result = await ApiService().toggleFavorit(resep.id);
      if (result['success'] != true && mounted) {
        setState(() {
          _filteredResep[index].isFavorit = !_filteredResep[index].isFavorit;
          if (allIndex != -1) _allResep[allIndex].isFavorit = _filteredResep[index].isFavorit;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _filteredResep[index].isFavorit = !_filteredResep[index].isFavorit;
          if (allIndex != -1) _allResep[allIndex].isFavorit = _filteredResep[index].isFavorit;
        });
      }
    }
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
                  const Text('Katalog',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
                ],
              ),
            ),

            // ── SEARCH BAR ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari resep, bahan, atau pembuat...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _filterLokal('');
                          })
                      : null,
                ),
              ),
            ),

            // ── KATEGORI CHIPS ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 0, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _kategoriList.map((k) {
                    final isSelected = _selectedKategori == k['label'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedKategori = k['label']!);
                        _loadResep(); // ← fetch ulang per kategori
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD4865A) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFD4865A) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          k['label']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── LIST RESEP ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4865A)))
                  : _errorMsg != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(_errorMsg!, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadResep,
                                style: ElevatedButton.styleFrom(minimumSize: Size.zero),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : _filteredResep.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('Resep tidak ditemukan',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: const Color(0xFFD4865A),
                              onRefresh: _loadResep,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: _filteredResep.length,
                                itemBuilder: (context, i) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: CardResep(
                                      resep: _filteredResep[i],
                                      isHorizontal: true,
                                      onTap: () => Navigator.pushNamed(
                                        context, '/detail-resep',
                                        arguments: _filteredResep[i],
                                      ),
                                      onFavoritTap: () => _toggleFavorit(i),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavbar(currentIndex: 1),
    );
  }
}