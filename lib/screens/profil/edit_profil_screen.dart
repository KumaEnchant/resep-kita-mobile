import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../service/api_service.dart';

class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _usernameController = TextEditingController();
  final _nomorHpController  = TextEditingController();
  final _bioController      = TextEditingController();

  File?   _selectedImage;
  bool    _isLoading        = false;
  bool    _isUploadingFoto  = false;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadFromApi();
  }

  void _loadFromApi() {
    _namaController.text  = ApiService().userName  ?? '';
    _emailController.text = ApiService().userEmail ?? '';
    _loadDetailUser();
  }

  Future<void> _loadDetailUser() async {
    try {
      final result = await ApiService().getUser();
      if (result['success'] == true && mounted) {
        final data = result['data'];
        setState(() {
          _nomorHpController.text  = data['phone']    ?? '';
          _usernameController.text = data['username'] ?? '';
          _bioController.text      = data['bio']      ?? '';
          _currentPhotoUrl         = data['foto_url'] ?? data['photo_url'];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _nomorHpController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Pilih Foto Profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFD4865A)),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari galeri foto'),
                onTap: () { Navigator.pop(context); _getImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD4865A)),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto baru'),
                onTap: () { Navigator.pop(context); _getImage(ImageSource.camera); },
              ),
              if (_currentPhotoUrl != null || _selectedImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                  ),
                  title: const Text('Hapus Foto'),
                  subtitle: const Text('Gunakan foto default'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage   = null;
                      _currentPhotoUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final picker     = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85,
      );
      if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tidak bisa akses foto: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _simpanProfil() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? fotoUrl = _currentPhotoUrl;

      // ✅ Step 1: Upload foto dulu kalau ada foto baru yang dipilih
      if (_selectedImage != null) {
        setState(() => _isUploadingFoto = true);
        final uploadResult = await ApiService().uploadFotoProfil(_selectedImage!);
        setState(() => _isUploadingFoto = false);

        if (uploadResult['success'] == true) {
          fotoUrl = uploadResult['url'];
        } else {
          // Upload gagal, tapi lanjut simpan data lain tanpa update foto
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(uploadResult['message'] ?? 'Gagal upload foto, data lain tetap tersimpan'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      }

      // ✅ Step 2: Simpan semua field termasuk foto_url
      final result = await ApiService().updateUser(
        nama:     _namaController.text.trim(),
        phone:    _nomorHpController.text.trim().isEmpty
            ? null : _nomorHpController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null : _usernameController.text.trim(),
        bio:      _bioController.text.trim().isEmpty
            ? null : _bioController.text.trim(),
        fotoUrl:  fotoUrl, // ✅ kirim URL foto (bisa data URI base64 baru atau URL lama)
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ApiService().userName = _namaController.text.trim();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Profil berhasil diperbarui!'),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Gagal memperbarui profil'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading       = false;
        _isUploadingFoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak dapat terhubung ke server'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildDefaultAvatar() {
    final nama    = _namaController.text.isNotEmpty
        ? _namaController.text : (ApiService().userName ?? '?');
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFFF5E6D3),
      child: Center(
        child: Text(initial,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFD4865A))),
      ),
    );
  }

  // ✅ Render foto dari _currentPhotoUrl. Bisa berupa data URI base64 (opsi B)
  // atau URL biasa (kalau ada data lama dari sebelum migrasi).
  Widget _buildPhotoFromUrl(String url) {
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(bytes,
            fit: BoxFit.cover, width: 120, height: 120,
            errorBuilder: (_, __, ___) => _buildDefaultAvatar());
      } catch (_) {
        return _buildDefaultAvatar();
      }
    }
    return Image.network(url,
        fit: BoxFit.cover, width: 120, height: 120,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFF5E6D3),
            child: const Center(child: CircularProgressIndicator(
                color: Color(0xFFD4865A), strokeWidth: 2)),
          );
        },
        errorBuilder: (_, __, ___) => _buildDefaultAvatar());
  }

  Widget _buildFotoProfil() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _pickImage,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4865A), width: 3),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFD4865A).withOpacity(0.2),
                  blurRadius: 15, offset: const Offset(0, 5),
                )],
              ),
              child: ClipOval(
                child: _isUploadingFoto
                    // ✅ Tampilkan loading saat upload foto
                    ? Container(
                        color: const Color(0xFFF5E6D3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4865A), strokeWidth: 2),
                        ),
                      )
                    : _selectedImage != null
                        // ✅ Preview foto yang baru dipilih (belum diupload)
                        ? Image.file(_selectedImage!,
                            fit: BoxFit.cover, width: 120, height: 120,
                            errorBuilder: (_, __, ___) => _buildDefaultAvatar())
                        : _currentPhotoUrl != null
                            // ✅ Foto dari server (base64 atau URL)
                            ? _buildPhotoFromUrl(_currentPhotoUrl!)
                            : _buildDefaultAvatar(),
              ),
            ),
          ),
          // ✅ Badge kamera di pojok kanan bawah
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4865A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),

          // ✅ Overlay "Foto baru" kalau ada gambar yang dipilih tapi belum disimpan
          if (_selectedImage != null && !_isUploadingFoto)
            Positioned(
              top: 0, left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Baru',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(fontSize: 15, color: readOnly ? Colors.grey.shade500 : Colors.grey.shade800),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: const Color(0xFFD4865A), size: 20),
            helperText: helperText,
            helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4865A), width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            counterStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange.shade600))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Foto Profil ──
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    _buildFotoProfil(),
                    const SizedBox(height: 12),
                    Text(
                      _isUploadingFoto
                          ? 'Mengupload foto...'
                          : _selectedImage != null
                              ? 'Foto baru dipilih — tekan Simpan untuk menyimpan'
                              : 'Ketuk foto untuk mengubah',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedImage != null
                            ? Colors.green.shade600
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Informasi Akun ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informasi Akun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _namaController, label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap', icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                        if (v.trim().length < 3) return 'Nama minimal 3 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _usernameController, label: 'Username',
                      hint: 'Masukkan username (contoh: chef_budi)', icon: Icons.alternate_email_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Username tidak boleh kosong';
                        if (v.contains(' ')) return 'Username tidak boleh mengandung spasi';
                        if (v.trim().length < 3) return 'Username minimal 3 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController, label: 'Email',
                      hint: 'Email', icon: Icons.email_outlined,
                      readOnly: true, helperText: 'Email tidak dapat diubah',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Informasi Tambahan ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informasi Tambahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nomorHpController, label: 'Nomor HP',
                      hint: 'Contoh: 081234567890', icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          if (v.length < 10 || v.length > 15) return 'Nomor HP tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bioController, label: 'Bio',
                      hint: 'Ceritakan sedikit tentang dirimu...', icon: Icons.edit_note_rounded,
                      maxLines: 3, maxLength: 150,
                      validator: (v) {
                        if (v != null && v.length > 150) return 'Bio maksimal 150 karakter';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Tombol Simpan ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _simpanProfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4865A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD4865A).withOpacity(0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                              const SizedBox(width: 10),
                              Text(
                                _isUploadingFoto ? 'Mengupload foto...' : 'Menyimpan...',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : const Text('Simpan Perubahan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}