class ResepModel {
  final String id;
  final String nama;
  final String gambar;
  final double rating;
  final int waktuMenit;
  final String kategori;
  final String tipe;
  final List<String> bahan;
  final List<String> langkah;
  final bool isPremium;
  bool isFavorit;
  final Map<String, dynamic> infoGizi;

  // ✅ Field info pembuat & jumlah favorit
  final String dibuatOleh;
  final String namaUser;
  final String fotoUser;
  int jumlahFavorit; // ✅ Dihapus 'final' biar bisa update realtime

  ResepModel({
    required this.id,
    required this.nama,
    required this.gambar,
    required this.rating,
    required this.waktuMenit,
    required this.kategori,
    required this.tipe,
    required this.bahan,
    required this.langkah,
    this.isPremium     = false,
    this.isFavorit     = false,
    this.infoGizi      = const {},
    this.dibuatOleh    = '',
    this.namaUser      = '',
    this.fotoUser      = '',
    this.jumlahFavorit = 0,
  });

  factory ResepModel.fromJson(Map<String, dynamic> json) {
    return ResepModel(
      id            : json['id']             ?? '',
      nama          : json['nama']           ?? '',
      gambar        : json['gambar']         ?? '',
      rating        : (json['rating']        ?? 0).toDouble(),
      waktuMenit    : json['waktu_menit']    ?? 0,
      kategori      : json['kategori']       ?? 'Makanan',
      tipe          : json['tipe']           ?? 'Semua',
      bahan         : List<String>.from(json['bahan']   ?? []),
      langkah       : List<String>.from(json['langkah'] ?? []),
      isPremium     : json['is_premium']     ?? false,
      isFavorit     : json['is_favorit']     ?? false,
      infoGizi      : Map<String, dynamic>.from(json['info_gizi'] ?? {}),
      dibuatOleh    : json['dibuat_oleh']    ?? '',
      namaUser      : json['nama_user']      ?? '',
      fotoUser      : json['foto_user']      ?? '',
      jumlahFavorit : json['jumlah_favorit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id'             : id,
      'nama'           : nama,
      'gambar'         : gambar,
      'rating'         : rating,
      'waktu_menit'    : waktuMenit,
      'kategori'       : kategori,
      'tipe'           : tipe,
      'bahan'          : bahan,
      'langkah'        : langkah,
      'is_premium'     : isPremium,
      'is_favorit'     : isFavorit,
      'info_gizi'      : infoGizi,
      'dibuat_oleh'    : dibuatOleh,
      'nama_user'      : namaUser,
      'foto_user'      : fotoUser,
      'jumlah_favorit' : jumlahFavorit,
    };
  }
}