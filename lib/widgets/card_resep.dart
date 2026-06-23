import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/resep_model.dart';

class CardResep extends StatelessWidget {
  final ResepModel resep;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritTap;
  final bool isHorizontal;
  final bool showFavorit;

  const CardResep({
    super.key,
    required this.resep,
    this.onTap,
    this.onFavoritTap,
    this.isHorizontal = false,
    this.showFavorit  = true,
  });

  @override
  Widget build(BuildContext context) {
    return isHorizontal ? _buildHorizontal() : _buildVertical();
  }

  // ── Vertikal (card kecil untuk grid/horizontal scroll) ────────────────────
  Widget _buildVertical() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gambar + badge mahkota
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    resep.gambar,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: const Color(0xFFF5E6D3),
                      child: const Icon(Icons.restaurant, color: Color(0xFFD4865A), size: 40),
                    ),
                  ),
                ),
                if (resep.isPremium)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _PremiumBadge(),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nama resep
                  Text(
                    resep.nama,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Rating & waktu
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFFFA500)),
                      const SizedBox(width: 2),
                      Text(resep.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time, size: 12, color: Color(0xFF888888)),
                      const SizedBox(width: 2),
                      Text('${resep.waktuMenit}m',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ✅ Nama pembuat — selalu tampil
                  Row(
                    children: [
                      _avatarPembuat(size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          resep.namaUser.isNotEmpty ? resep.namaUser : 'Dapur Umami',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ✅ Jumlah favorit — selalu tampil
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 11, color: Colors.red),
                      const SizedBox(width: 3),
                      Text(
                        '${resep.jumlahFavorit} favorit',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Horizontal (card list) ────────────────────────────────────────────────
  Widget _buildHorizontal() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Gambar + badge mahkota
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: Image.network(
                    resep.gambar,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90, height: 90,
                      color: const Color(0xFFF5E6D3),
                      child: const Icon(Icons.restaurant, color: Color(0xFFD4865A), size: 36),
                    ),
                  ),
                ),
                if (resep.isPremium)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _PremiumBadge(small: true),
                  ),
              ],
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama resep
                    Text(
                      resep.nama,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rating & waktu
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: Color(0xFFFFA500)),
                        const SizedBox(width: 3),
                        Text(resep.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                        const SizedBox(width: 10),
                        const Icon(Icons.access_time, size: 13, color: Color(0xFF888888)),
                        const SizedBox(width: 3),
                        Text('${resep.waktuMenit} menit',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ✅ Nama pembuat + jumlah favorit
                    Row(
                      children: [
                        _avatarPembuat(size: 18),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            resep.namaUser.isNotEmpty ? resep.namaUser : 'Dapur Umami',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite, size: 12, color: Colors.red),
                        const SizedBox(width: 3),
                        Text(
                          '${resep.jumlahFavorit}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tombol favorit
            if (showFavorit)
              IconButton(
                onPressed: onFavoritTap,
                icon: Icon(
                  resep.isFavorit ? Icons.favorite : Icons.favorite_border,
                  color: resep.isFavorit ? Colors.red : Colors.grey.shade400,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Avatar pembuat ────────────────────────────────────────────────────────
  // ✅ Bisa render foto_user dari base64 data URI (opsi B) atau URL biasa
  Widget _avatarPembuat({required double size}) {
    final foto = resep.fotoUser;
    if (foto.isNotEmpty) {
      if (foto.startsWith('data:')) {
        try {
          final bytes = base64Decode(foto.split(',').last);
          return CircleAvatar(
            radius: size / 2,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {
          // jatuh ke avatar inisial di bawah
        }
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
          fontSize: size * 0.55,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFD4865A),
        ),
      ),
    );
  }
}

// ── Badge mahkota untuk resep premium ──────────────────────────────────────
class _PremiumBadge extends StatelessWidget {
  final bool small;
  const _PremiumBadge({this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(small ? 4 : 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Icon(
        Icons.workspace_premium_rounded,
        size: small ? 12 : 14,
        color: Colors.white,
      ),
    );
  }
}