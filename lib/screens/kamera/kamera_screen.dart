import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/resep_model.dart';
import '../../service/api_service.dart';

class KameraScreen extends StatefulWidget {
  const KameraScreen({super.key});

  @override
  State<KameraScreen> createState() => _KameraScreenState();
}

class _KameraScreenState extends State<KameraScreen>
    with SingleTickerProviderStateMixin {
  File? _gambar;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _hasilScan;
  List<ResepModel> _resepMatches = [];
  bool _isSearchingResep = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const _apiKey =
      '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';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.85, end: 1.0).animate(_pulseController);

    // Langsung buka kamera saat screen dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ambilGambar(ImageSource.camera);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _ambilGambar(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) {
      // User cancel kamera, kalau belum ada gambar langsung pop
      if (_gambar == null && mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      _gambar = File(picked.path);
      _hasilScan = null;
      _resepMatches = [];
    });
    await _analisisMakanan();
  }

  Future<void> _analisisMakanan() async {
    if (_gambar == null) return;
    setState(() => _isAnalyzing = true);

    try {
      final bytes = await _gambar!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://resepkita.app',
          'X-Title': 'Resep Kita',
        },
        body: jsonEncode({
          'model': 'openai/gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Kamu adalah asisten kuliner Indonesia. Analisis gambar ini dan identifikasi makanan atau bahan yang terlihat. Jawab HANYA dalam format JSON berikut tanpa markdown dan tanpa penjelasan tambahan: {"nama": "nama makanan atau bahan utama dalam bahasa Indonesia", "kalori": "estimasi kalori per porsi contoh 250 kkal", "protein": "estimasi protein contoh 15 gram", "lemak": "estimasi lemak contoh 10 gram", "karbohidrat": "estimasi karbohidrat contoh 30 gram", "bahan": ["bahan 1", "bahan 2", "bahan 3", "bahan 4", "bahan 5"], "cara_masak": ["langkah 1", "langkah 2", "langkah 3", "langkah 4"], "resep_rekomendasi": ["nama resep Indonesia 1", "nama resep Indonesia 2", "nama resep Indonesia 3"]}'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  }
                }
              ]
            }
          ],
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String;
        final cleaned =
            text.replaceAll('```json', '').replaceAll('```', '').trim();
        final result = jsonDecode(cleaned);
        setState(() {
          _hasilScan = result;
          _isAnalyzing = false;
        });
        // Langsung search resep di database
        await _cariResepDiDatabase(result);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menganalisis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cari resep di database: exact match dulu, kalau ga ada cari yang mirip
  Future<void> _cariResepDiDatabase(Map<String, dynamic> hasil) async {
    setState(() => _isSearchingResep = true);

    try {
      final nama = hasil['nama'] as String? ?? '';
      final rekomendasi = (hasil['resep_rekomendasi'] as List?) ?? [];
      final List<ResepModel> found = [];

      // 1. Exact match nama makanan
      final exactResult = await ApiService().getResep(search: nama);
      if (exactResult['success'] == true) {
        final list = (exactResult['data'] as List)
            .map((e) => ResepModel.fromJson(e))
            .toList();
        for (final r in list) {
          if (!found.any((f) => f.id == r.id)) found.add(r);
        }
      }

      // 2. Search tiap rekomendasi dari AI
      for (final rec in rekomendasi) {
        final recResult = await ApiService().getResep(search: rec.toString());
        if (recResult['success'] == true) {
          final list = (recResult['data'] as List)
              .map((e) => ResepModel.fromJson(e))
              .toList();
          for (final r in list) {
            if (!found.any((f) => f.id == r.id)) found.add(r);
          }
        }
      }

      setState(() {
        _resepMatches = found.take(5).toList(); // max 5 resep
        _isSearchingResep = false;
      });
    } catch (e) {
      setState(() => _isSearchingResep = false);
    }
  }

  void _reset() {
    setState(() {
      _gambar = null;
      _hasilScan = null;
      _resepMatches = [];
      _isAnalyzing = false;
    });
    _ambilGambar(ImageSource.camera);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasilScan != null && _gambar != null) {
      return _HasilScanView(
        gambar: _gambar!,
        hasil: _hasilScan!,
        resepMatches: _resepMatches,
        isSearchingResep: _isSearchingResep,
        onReset: _reset,
        onAmbilGaleri: () => _ambilGambar(ImageSource.gallery),
      );
    }

    // Loading screen saat analisis
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Stack(
          children: [
            // Preview gambar kalau udah ada
            if (_gambar != null)
              Positioned.fill(
                child: Image.file(_gambar!, fit: BoxFit.cover),
              ),

            // Placeholder scan frame kalau belum ada gambar
            if (_gambar == null)
              Center(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4865A).withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_outlined,
                        color: const Color(0xFFD4865A).withValues(alpha: 0.4),
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),

            // Overlay analyzing
            if (_isAnalyzing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4865A).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD4865A),
                            width: 2,
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4865A),
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'AI sedang menganalisis...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mengidentifikasi makanan & mencari resep',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Header
            Positioned(
              top: 16, left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hasil Scan View ─────────────────────────────────────────────────────
class _HasilScanView extends StatelessWidget {
  final File gambar;
  final Map<String, dynamic> hasil;
  final List<ResepModel> resepMatches;
  final bool isSearchingResep;
  final VoidCallback onReset;
  final VoidCallback onAmbilGaleri;

  const _HasilScanView({
    required this.gambar,
    required this.hasil,
    required this.resepMatches,
    required this.isSearchingResep,
    required this.onReset,
    required this.onAmbilGaleri,
  });

  @override
  Widget build(BuildContext context) {
    final bahan = (hasil['bahan'] as List?) ?? [];
    final caraMasak = (hasil['cara_masak'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Gambar header ──────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28)),
                  child: Image.file(
                    gambar,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12, left: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4865A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('AI Scan',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                // Nama & kalori di bawah foto
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          hasil['nama'] ?? 'Makanan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black54)
                            ],
                          ),
                        ),
                      ),
                      if (hasil['kalori'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasil['kalori'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFD4865A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Konten scroll ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Info Gizi Ringkas ──
                    Row(
                      children: [
                        _GiziChip(label: 'Kalori', value: hasil['kalori'] ?? '-', icon: '🔥'),
                        const SizedBox(width: 8),
                        _GiziChip(label: 'Protein', value: hasil['protein'] ?? '-', icon: '💪'),
                        const SizedBox(width: 8),
                        _GiziChip(label: 'Karbo', value: hasil['karbohidrat'] ?? '-', icon: '🌾'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Resep dari Database ──
                    const _SectionTitle(title: '🍽️ Resep yang Cocok'),
                    const SizedBox(height: 10),

                    if (isSearchingResep)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                              color: Color(0xFFD4865A)),
                        ),
                      )
                    else if (resepMatches.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_off,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Resep belum tersedia di database',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      ...resepMatches.map((resep) => GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/detail-resep',
                              arguments: resep,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Thumbnail resep
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      resep.gambar,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        color: const Color(0xFFF5E6D3),
                                        child: const Icon(Icons.restaurant,
                                            color: Color(0xFFD4865A)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resep.nama,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2D2D2D),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                size: 13,
                                                color: Color(0xFFFFA500)),
                                            const SizedBox(width: 3),
                                            Text(
                                              resep.rating.toString(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                            const SizedBox(width: 10),
                                            const Icon(
                                                Icons.access_time_rounded,
                                                size: 13,
                                                color: Colors.grey),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${resep.waktuMenit} mnt',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          )),

                    const SizedBox(height: 20),

                    // ── Bahan ──
                    if (bahan.isNotEmpty) ...[
                      const _SectionTitle(title: '🛒 Bahan-bahan'),
                      const SizedBox(height: 10),
                      ...bahan.map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD4865A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(b.toString(),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF2D2D2D))),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],

                    // ── Cara Masak ──
                    if (caraMasak.isNotEmpty) ...[
                      const _SectionTitle(title: '👨‍🍳 Cara Memasak'),
                      const SizedBox(height: 10),
                      ...caraMasak.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD4865A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${e.key + 1}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(e.value.toString(),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF2D2D2D),
                                          height: 1.5)),
                                ),
                              ],
                            ),
                          )),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Tombol bawah ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAmbilGaleri,
                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                      label: const Text('Galeri'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD4865A),
                        side: const BorderSide(color: Color(0xFFD4865A)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReset,
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: const Text('Scan Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4865A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gizi chip kecil ─────────────────────────────────────────────────────
class _GiziChip extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _GiziChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D2D2D),
      ),
    );
  }
}