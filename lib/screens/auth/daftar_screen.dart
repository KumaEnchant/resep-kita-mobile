import 'package:flutter/material.dart';
import '../../../service/api_service.dart';

class DaftarScreen extends StatefulWidget {
  const DaftarScreen({super.key});

  @override
  State<DaftarScreen> createState() => _DaftarScreenState();
}

class _DaftarScreenState extends State<DaftarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  Future<void> _handleDaftar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService().register(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result['success'] == true) {
        // ✅ FIX: Hapus auto login, langsung ke halaman login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Akun berhasil dibuat! Silakan login 🎉'),
            backgroundColor: const Color(0xFFD4865A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal mendaftar, coba lagi'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat terhubung ke server'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper input decoration
  InputDecoration _inputDeco(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF888888)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD4865A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Logo + judul center ──────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4865A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4865A).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 36),
              ),

              const SizedBox(height: 20),

              const Text(
                'Buat Akun Baru',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
              ),

              const SizedBox(height: 6),

              Text(
                'Daftar dan mulai masak resep favoritmu',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 32),

              // ── Form ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nama
                      TextFormField(
                        controller: _namaController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDeco('Nama Lengkap', Icons.person_outline),
                        validator: (v) => (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDeco('Email atau No. HP', Icons.email_outlined),
                        validator: (v) => (v == null || v.isEmpty) ? 'Email tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDeco(
                          'Password',
                          Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF888888),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
                      ),
                      const SizedBox(height: 14),

                      // Konfirmasi password
                      TextFormField(
                        controller: _konfirmasiController,
                        obscureText: _obscureKonfirmasi,
                        decoration: _inputDeco(
                          'Konfirmasi Password',
                          Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureKonfirmasi ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF888888),
                            ),
                            onPressed: () => setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
                          ),
                        ),
                        validator: (v) => (v != _passwordController.text) ? 'Password tidak cocok' : null,
                      ),

                      const SizedBox(height: 28),

                      // Tombol daftar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleDaftar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4865A),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0xFFD4865A).withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Buat Akun',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Syarat & ketentuan
                      Text(
                        'Dengan mendaftar, kamu menyetujui\nSyarat & Ketentuan Resep Kita',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400, height: 1.5),
                      ),

                      const SizedBox(height: 24),

                      // Sudah punya akun
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Sudah punya akun? ', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(color: Color(0xFFD4865A), fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}