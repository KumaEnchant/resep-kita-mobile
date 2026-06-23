import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TentangAplikasiScreen extends StatelessWidget {
  const TentangAplikasiScreen({super.key});

  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '100';
  static const String _developer = 'Tim Resep Kita';
  static const String _email = 'support@resepkita.id';
  static const String _website = 'https://resepkita.id';
  static const String _privacyUrl = 'https://resepkita.id/privasi';
  static const String _termsUrl = 'https://resepkita.id/syarat';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=id.resepkita.app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildDescriptionCard(),
                  const SizedBox(height: 12),
                  _buildStatsRow(),
                  const SizedBox(height: 12),
                  _buildFeaturesCard(),
                  const SizedBox(height: 12),
                  _buildInfoCard(),
                  const SizedBox(height: 12),
                  _buildLinksCard(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFFE8521A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B35), Color(0xFFE8521A)],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              top: 30,
              left: 30,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 38,
                    color: Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Resep Kita',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Versi $_appVersion (Build $_buildNumber)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      title: const Text(
        'Tentang Aplikasi',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFFF6B35),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tentang Kami',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Resep Kita adalah aplikasi masak yang hadir untuk membantu kamu menemukan, menyimpan, dan memasak hidangan favorit dengan cara yang menyenangkan. Dari masakan tradisional Nusantara hingga kuliner mancanegara — semua ada di sini.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF555555),
              height: 1.65,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dibuat dengan ❤️ untuk para pecinta kuliner Indonesia.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book_rounded,
            value: '500+',
            label: 'Resep',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_rounded,
            value: '10rb+',
            label: 'Pengguna',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            value: '4.8',
            label: 'Rating',
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesCard() {
    const features = [
      _FeatureData(
        icon: Icons.search_rounded,
        title: 'Cari Resep',
        subtitle:
            'Temukan resep berdasarkan bahan, kategori, atau nama masakan dengan mudah.',
      ),
      _FeatureData(
        icon: Icons.camera_alt_rounded,
        title: 'Scan Bahan Makanan',
        subtitle:
            'Foto bahan yang ada di dapur, lalu dapatkan rekomendasi resep secara otomatis.',
      ),
      _FeatureData(
        icon: Icons.bookmark_rounded,
        title: 'Simpan & Favorit',
        subtitle:
            'Koleksi resep favorit dan buat daftar masakan yang ingin kamu coba.',
      ),
      _FeatureData(
        icon: Icons.workspace_premium_rounded,
        title: 'Paket Premium',
        subtitle:
            'Nikmati ribuan resep eksklusif dan fitur tanpa batas dengan berlangganan Pro.',
      ),
      _FeatureData(
        icon: Icons.notifications_rounded,
        title: 'Notifikasi Resep',
        subtitle:
            'Dapatkan inspirasi masak harian langsung di notifikasi kamu.',
      ),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Fitur Unggulan'),
          const SizedBox(height: 12),
          ...features.asMap().entries.map((entry) {
            final isLast = entry.key == features.length - 1;
            return Column(
              children: [
                _FeatureItem(data: entry.value),
                if (!isLast)
                  const Divider(
                      height: 20, thickness: 0.5, color: Color(0xFFEEEEEE)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final rows = [
      const _InfoRowData(
          label: 'Versi Aplikasi', value: '$_appVersion ($_buildNumber)'),
      const _InfoRowData(label: 'Dikembangkan oleh', value: _developer),
      const _InfoRowData(label: 'Platform', value: 'Android & iOS'),
      const _InfoRowData(label: 'Terakhir diperbarui', value: 'Juni 2026'),
      const _InfoRowData(label: 'Kontak', value: _email, isLink: true),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Info Aplikasi'),
          const SizedBox(height: 12),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                _InfoRow(data: entry.value),
                if (!isLast)
                  const Divider(
                      height: 16, thickness: 0.5, color: Color(0xFFEEEEEE)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLinksCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Tautan'),
          const SizedBox(height: 8),
          _LinkItem(
            icon: Icons.shield_outlined,
            label: 'Kebijakan Privasi',
            onTap: () => _launchUrl(_privacyUrl),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _LinkItem(
            icon: Icons.description_outlined,
            label: 'Syarat & Ketentuan',
            onTap: () => _launchUrl(_termsUrl),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _LinkItem(
            icon: Icons.language_rounded,
            label: 'Kunjungi Website Kami',
            onTap: () => _launchUrl(_website),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _LinkItem(
            icon: Icons.star_outline_rounded,
            label: 'Beri Ulasan di Play Store',
            onTap: () => _launchUrl(_playStoreUrl),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _LinkItem(
            icon: Icons.share_outlined,
            label: 'Bagikan ke Teman',
            onTap: () {
              // Implement share functionality using share_plus package:
              // Share.share('Coba deh aplikasi Resep Kita! $_playStoreUrl');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          '© 2026 Resep Kita. Semua hak dilindungi.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFAAAAAA),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Made with ❤️ in Indonesia',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFFAAAAAA),
        letterSpacing: 1.1,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _FeatureItem extends StatelessWidget {
  final _FeatureData data;
  const _FeatureItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(data.icon, color: const Color(0xFFFF6B35), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRowData {
  final String label;
  final String value;
  final bool isLink;
  const _InfoRowData({
    required this.label,
    required this.value,
    this.isLink = false,
  });
}

class _InfoRow extends StatelessWidget {
  final _InfoRowData data;
  const _InfoRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF888888),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              data.value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: data.isLink
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF6B35), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }
}
