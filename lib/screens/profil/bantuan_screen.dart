import 'package:flutter/material.dart';

class BantuanScreen extends StatefulWidget {
  const BantuanScreen({super.key});

  @override
  State<BantuanScreen> createState() => _BantuanScreenState();
}

class _BantuanScreenState extends State<BantuanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pesanController = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;

  final List<Map<String, String>> _faqList = [
    {
      'pertanyaan': 'Bagaimana cara menyimpan resep favorit?',
      'jawaban':
          'Buka halaman detail resep, lalu tekan ikon bookmark (🔖) di pojok kanan atas. Resep akan tersimpan di menu "Resep Disimpan" pada halaman Profil kamu.',
    },
    {
      'pertanyaan': 'Apa perbedaan akun biasa dengan akun Premium?',
      'jawaban':
          'Akun Premium memberikan akses tak terbatas ke seluruh katalog resep eksklusif, fitur Kamera Scan Makanan, rekomendasi menu harian, dan konten tanpa iklan. Akun biasa hanya dapat mengakses resep umum.',
    },
    {
      'pertanyaan': 'Bagaimana cara menggunakan fitur Kamera Scan Makanan?',
      'jawaban':
          'Fitur ini tersedia untuk pengguna Premium. Buka menu "Kamera Scan Makanan" di halaman Profil, arahkan kamera ke makanan, lalu aplikasi akan otomatis mendeteksi jenis makanan dan menyarankan resep terkait.',
    },
    {
      'pertanyaan': 'Bagaimana cara mengubah data profil saya?',
      'jawaban':
          'Masuk ke halaman Profil → pilih "Edit Profil". Kamu bisa mengubah nama, email, foto profil, dan kata sandi di halaman tersebut.',
    },
    {
      'pertanyaan': 'Apakah data saya aman di aplikasi ini?',
      'jawaban':
          'Ya, kami menggunakan enkripsi data dan tidak pernah membagikan informasi pribadi kamu kepada pihak ketiga. Keamanan data pengguna adalah prioritas utama kami.',
    },
    {
      'pertanyaan': 'Bagaimana cara membatalkan langganan Premium?',
      'jawaban':
          'Kamu dapat membatalkan langganan kapan saja melalui menu "Metode Pembayaran" di halaman Profil. Akses Premium akan tetap aktif hingga akhir periode yang sudah dibayar.',
    },
    {
      'pertanyaan': 'Apakah aplikasi bisa digunakan tanpa koneksi internet?',
      'jawaban':
          'Beberapa resep yang pernah dibuka akan tersimpan cache dan bisa dilihat secara offline. Namun untuk mengakses seluruh fitur dan katalog terbaru, koneksi internet diperlukan.',
    },
  ];

  List<Map<String, String>> get _filteredFaq {
    if (_searchQuery.isEmpty) return _faqList;
    return _faqList.where((item) {
      return item['pertanyaan']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item['jawaban']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _kirimPesan() {
    final pesan = _pesanController.text.trim();
    if (pesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pesan tidak boleh kosong.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    _pesanController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF5E6D3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFFD4865A),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesan Terkirim!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tim kami akan segera merespons pertanyaanmu dalam 1×24 jam.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4865A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Oke'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaq;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bantuan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner Header ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4865A), Color(0xFFE8A07A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ada yang bisa\nkami bantu?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Temukan jawaban di FAQ atau\nhubungi tim kami.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.support_agent_rounded,
                    size: 64,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Search Bar ────────────────────────────────────────────
            Container(
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
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {
                  _searchQuery = val;
                  _expandedIndex = null;
                }),
                decoration: InputDecoration(
                  hintText: 'Cari pertanyaan...',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFFD4865A), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: Colors.grey.shade400),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── FAQ Section ───────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Pertanyaan Umum',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4865A),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada hasil untuk\n"$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
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
                  children: filtered.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isExpanded = _expandedIndex == idx;
                    final isLast = idx == filtered.length - 1;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() {
                            _expandedIndex = isExpanded ? null : idx;
                          }),
                          borderRadius: BorderRadius.vertical(
                            top: idx == 0
                                ? const Radius.circular(16)
                                : Radius.zero,
                            bottom: isLast
                                ? const Radius.circular(16)
                                : Radius.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isExpanded
                                        ? const Color(0xFFD4865A)
                                        : const Color(0xFFF5E6D3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.help_outline_rounded,
                                    size: 16,
                                    color: isExpanded
                                        ? Colors.white
                                        : const Color(0xFFD4865A),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['pertanyaan']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isExpanded
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: const Color(0xFF2D2D2D),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: isExpanded
                                        ? const Color(0xFFD4865A)
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF6F0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFF5E6D3), width: 1),
                            ),
                            child: Text(
                              item['jawaban']!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.6,
                              ),
                            ),
                          ),
                          secondChild: const SizedBox.shrink(),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 60,
                            color: Colors.grey.shade100,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 28),

            // ── Hubungi Kami Section ──────────────────────────────────
            const Text(
              'Hubungi Kami',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tidak menemukan jawaban? Kirim pesanmu.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 14),

            // ── Quick Contact Chips ───────────────────────────────────
            Row(
              children: [
                _QuickContactChip(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    // TODO: launchUrl(Uri.parse('https://wa.me/6281234567890'));
                  },
                ),
                const SizedBox(width: 8),
                _QuickContactChip(
                  icon: Icons.camera_alt_rounded,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: () {
                    // TODO: launchUrl(Uri.parse('https://instagram.com/resepkita.id'));
                  },
                ),
                const SizedBox(width: 8),
                _QuickContactChip(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  color: const Color(0xFFD4865A),
                  onTap: () {
                    // TODO: launchUrl(Uri.parse('mailto:support@resepkita.id'));
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Form Pesan ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header form
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E6D3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_rounded,
                          color: Color(0xFFD4865A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kirim Pesan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          Text(
                            'Respons dalam 1×24 jam',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0E6DC)),
                  const SizedBox(height: 16),

                  // Label + counter
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded,
                          size: 16, color: Color(0xFFD4865A)),
                      const SizedBox(width: 6),
                      Text(
                        'Isi Pesan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _pesanController,
                        builder: (_, value, __) => Text(
                          '${value.text.length}/300',
                          style: TextStyle(
                            fontSize: 11,
                            color: value.text.length > 280
                                ? Colors.red.shade400
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // TextField
                  TextField(
                    controller: _pesanController,
                    maxLines: 5,
                    maxLength: 300,
                    buildCounter: (_,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        const SizedBox.shrink(),
                    decoration: InputDecoration(
                      hintText:
                          'Ceritakan masalah atau pertanyaanmu di sini...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFFDF6F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFD4865A), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tombol Kirim
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _kirimPesan,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text(
                        'Kirim Pesan',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4865A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Contact Info Cards Grid ───────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.55,
              children: const [
                _ContactCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'support@resepkita.id',
                  iconColor: Color(0xFFD4865A),
                  bgColor: Color(0xFFF5E6D3),
                ),
                _ContactCard(
                  icon: Icons.access_time_rounded,
                  label: 'Jam Operasional',
                  value: 'Sen–Jum\n08.00–17.00',
                  iconColor: Color(0xFF5A8ED4),
                  bgColor: Color(0xFFE3EDFB),
                ),
                _ContactCard(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  value: '+62 812-3456-7890',
                  iconColor: Color(0xFF25D366),
                  bgColor: Color(0xFFE2F8EA),
                ),
                _ContactCard(
                  icon: Icons.camera_alt_rounded,
                  label: 'Instagram',
                  value: '@resepkita.id',
                  iconColor: Color(0xFFE1306C),
                  bgColor: Color(0xFFFDE8EF),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── _QuickContactChip ─────────────────────────────────────────────────────────
class _QuickContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickContactChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _ContactCard ──────────────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF2D2D2D),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
