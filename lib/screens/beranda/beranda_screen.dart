import 'package:flutter/material.dart';
import '../../models/resep_model.dart';
import '../../service/api_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/card_resep.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen>
    with SingleTickerProviderStateMixin {
  String _selectedKategori = 'Semua';

  final List<Map<String, String>> _kategoriList = [
    {'label': 'Semua',        'value': 'Semua'},
    {'label': 'Makanan Utama','value': 'Makanan'},
    {'label': 'Minuman',      'value': 'Minuman'},
    {'label': 'Kue',          'value': 'Kue'},
  ];

  List<ResepModel> _resepList       = [];
  List<ResepModel> _populerOfficial = [];
  List<ResepModel> _populerMember   = [];

  bool _isLoading        = true;
  bool _isLoadingPopuler = true;
  String? _errorMsg;

  int _jumlahNotifBelumDibaca = 0;

  late TabController _tabController;
  int _selectedTab = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String get _namaUser => ApiService().userName ?? 'Tamu';

  static const List<Map<String, String>> _tipsList = [
    {'emoji': '🧂', 'tips': 'Tambahkan sedikit garam saat merebus untuk rasa yang lebih gurih.'},
    {'emoji': '🔥', 'tips': 'Panaskan wajan sebelum menuang minyak agar masakan tidak lengket.'},
    {'emoji': '🧄', 'tips': 'Tumis bawang putih di api sedang agar tidak gosong dan pahit.'},
    {'emoji': '🥩', 'tips': 'Marinasi daging minimal 30 menit agar bumbu lebih meresap.'},
    {'emoji': '💧', 'tips': 'Gunakan air es saat menguleni adonan agar tekstur lebih kenyal.'},
    {'emoji': '🫒', 'tips': 'Tambahkan minyak zaitun di akhir masakan untuk aroma lebih harum.'},
    {'emoji': '🌿', 'tips': 'Masukkan daun segar seperti kemangi di akhir agar tidak layu.'},
    {'emoji': '🍋', 'tips': 'Perasan jeruk lemon di akhir masakan bisa menyegarkan cita rasa.'},
    {'emoji': '🥚', 'tips': 'Telur lebih mudah dikocok jika sudah ada di suhu ruang.'},
    {'emoji': '🌶️', 'tips': 'Buang biji cabai untuk mengurangi pedas tanpa mengurangi aroma.'},
    {'emoji': '🍚', 'tips': 'Nasi goreng lebih enak menggunakan nasi dingin dari kulkas.'},
    {'emoji': '🧊', 'tips': 'Blanching sayuran lalu celupkan ke es agar warna tetap cerah.'},
    {'emoji': '🫕', 'tips': 'Aduk santan searah dan jangan biarkan mendidih terlalu keras agar tidak pecah.'},
    {'emoji': '🔪', 'tips': 'Pisau tajam lebih aman karena membutuhkan tenaga lebih sedikit.'},
  ];

  Map<String, String> get _tipsHariIni {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _tipsList[dayOfYear % _tipsList.length];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
    _loadResep();
    _loadResepPopuler();
    _loadJumlahNotif();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        kategori: selectedValue != 'Semua' ? selectedValue : null,
      );
      if (result['success'] == true && mounted) {
        final List data = result['data'] ?? [];
        setState(() {
          _resepList = data.map((e) => ResepModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _errorMsg = result['message'] ?? 'Gagal memuat resep'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMsg = 'Tidak dapat terhubung ke server'; _isLoading = false; });
    }
  }

  Future<void> _loadResepPopuler() async {
    setState(() => _isLoadingPopuler = true);
    try {
      final resOfficial = await ApiService().getResepPopuler(tipe: 'official');
      final resMember   = await ApiService().getResepPopuler(tipe: 'member');
      if (mounted) {
        setState(() {
          if (resOfficial['success'] == true) {
            final List d = resOfficial['data'] ?? [];
            _populerOfficial = d.map((e) => ResepModel.fromJson(e)).toList();
          }
          if (resMember['success'] == true) {
            final List d = resMember['data'] ?? [];
            _populerMember = d.map((e) => ResepModel.fromJson(e)).toList();
          }
          _isLoadingPopuler = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPopuler = false);
    }
  }

  Future<void> _loadJumlahNotif() async {
    try {
      final result = await ApiService().getNotifikasi();
      if (result['success'] == true && mounted) {
        final List data = result['data'] ?? [];
        final belumDibaca = data.where((n) => n['dibaca'] == false).length;
        setState(() => _jumlahNotifBelumDibaca = belumDibaca);
      }
    } catch (_) {}
  }

  // ✅ Toggle favorit untuk resep terbaru (list horizontal)
  Future<void> _toggleFavorit(int index) async {
    final resep = _resepList[index];
    setState(() => _resepList[index].isFavorit = !_resepList[index].isFavorit);
    try {
      final result = await ApiService().toggleFavorit(resep.id);
      if (result['success'] == true && mounted) {
        setState(() {
          _resepList[index].isFavorit = result['is_favorit'] ?? _resepList[index].isFavorit;
          if (_resepList[index].isFavorit) {
            _resepList[index].jumlahFavorit++;
          } else {
            if (_resepList[index].jumlahFavorit > 0) _resepList[index].jumlahFavorit--;
          }
        });
      } else if (mounted) {
        setState(() => _resepList[index].isFavorit = !_resepList[index].isFavorit);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal update favorit'), duration: Duration(seconds: 2)),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _resepList[index].isFavorit = !_resepList[index].isFavorit);
    }
  }

  // ✅ Toggle favorit untuk resep populer
  Future<void> _toggleFavoritPopuler(ResepModel resep) async {
    try {
      final result = await ApiService().toggleFavorit(resep.id);
      if (result['success'] == true && mounted) {
        setState(() {
          resep.isFavorit = result['is_favorit'] ?? !resep.isFavorit;
          if (resep.isFavorit) {
            resep.jumlahFavorit++;
          } else {
            if (resep.jumlahFavorit > 0) resep.jumlahFavorit--;
          }
        });
      }
    } catch (_) {}
  }

  void _navigateToDetail(ResepModel resep) {
    Navigator.pushNamed(context, '/detail-resep', arguments: resep);
  }

  List<ResepModel> get _filteredResep {
    final selectedValue = _kategoriList
        .firstWhere((k) => k['label'] == _selectedKategori,
            orElse: () => {'value': 'Semua'})['value']!;
    return _resepList.where((r) {
      final matchQuery = _searchQuery.isEmpty ||
          r.nama.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchKategori = selectedValue == 'Semua' || r.kategori == selectedValue;
      return matchQuery && matchKategori;
    }).toList();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final filtered   = _filteredResep;
    final terbaru    = filtered;
    final tips       = _tipsHariIni;
    final populerNow = _selectedTab == 0 ? _populerOfficial : _populerMember;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFD4865A),
          onRefresh: () async {
            await _loadResep();
            await _loadResepPopuler();
            await _loadJumlahNotif();
          },
          child: CustomScrollView(
            slivers: [

              // ── HEADER ──
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4865A), Color(0xFFE8A87C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4865A).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greeting,
                                style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w400)),
                            const SizedBox(height: 4),
                            Text(_namaUser,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            const Text('Mau masak apa hari ini? 🍳',
                                style: TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/notifikasi')
                                .then((_) => _loadJumlahNotif()),
                            child: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                            ),
                          ),
                          if (_jumlahNotifBelumDibaca > 0)
                            Positioned(
                              right: 6, top: 6,
                              child: Container(
                                width: 14, height: 14,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Center(
                                  child: Text(
                                    _jumlahNotifBelumDibaca > 9 ? '9+' : '$_jumlahNotifBelumDibaca',
                                    style: const TextStyle(color: Color(0xFFD4865A), fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── SEARCH BAR ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
                      decoration: InputDecoration(
                        hintText: 'Cari resep, bahan, atau kategori...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // ── KATEGORI CHIPS ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 0, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _kategoriList.map((k) {
                        final isSelected = _selectedKategori == k['label'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedKategori = k['label']!);
                            _loadResep();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFD4865A) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
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
              ),

              // ── TIPS HARI INI ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4865A).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4865A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(tips['emoji']!, style: const TextStyle(fontSize: 22))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tips Hari Ini',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
                              const SizedBox(height: 2),
                              Text(tips['tips']!, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── RESEP POPULER ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Resep Populer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/katalog'),
                        child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFFD4865A), fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

              // ── TAB Official / Dari Member ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        _buildTab(0, 'Official Resep Kita'),
                        _buildTab(1, 'Dari Member'),
                      ],
                    ),
                  ),
                ),
              ),

              // ── LIST RESEP POPULER ──
              SliverToBoxAdapter(
                child: _isLoadingPopuler
                    ? const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator(color: Color(0xFFD4865A))),
                      )
                    : populerNow.isEmpty
                        ? const SizedBox(
                            height: 100,
                            child: Center(
                              child: Text('Belum ada resep', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ),
                          )
                        : SizedBox(
                            height: 230,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: populerNow.length,
                              itemBuilder: (context, i) {
                                final resep = populerNow[i];
                                return Padding(
                                  padding: EdgeInsets.only(right: i < populerNow.length - 1 ? 14 : 0),
                                  child: CardResep(
                                    resep: resep,
                                    onTap: () => _navigateToDetail(resep),
                                    // ✅ Toggle favorit populer — update jumlah realtime
                                    onFavoritTap: () => _toggleFavoritPopuler(resep),
                                  ),
                                );
                              },
                            ),
                          ),
              ),

              // ── LOADING / ERROR ──
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFD4865A))),
                )
              else if (_errorMsg != null)
                SliverFillRemaining(
                  child: Center(
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
                  ),
                )
              else ...[

                // ── RESEP TERBARU ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Resep Terbaru',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/katalog'),
                          child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFFD4865A), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i >= terbaru.length) return null;
                        final resep = terbaru[i];
                        final originalIndex = _resepList.indexOf(resep);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CardResep(
                            resep: resep,
                            isHorizontal: true,
                            onTap: () => _navigateToDetail(resep),
                            // ✅ Toggle favorit terbaru — update jumlah realtime
                            onFavoritTap: () => _toggleFavorit(originalIndex),
                          ),
                        );
                      },
                      childCount: terbaru.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavbar(currentIndex: 0),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4865A) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}