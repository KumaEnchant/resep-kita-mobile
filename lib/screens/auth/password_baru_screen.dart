import 'package:flutter/material.dart';
import '../../../service/api_service.dart';

class PasswordBaruScreen extends StatefulWidget {
  const PasswordBaruScreen({super.key});

  @override
  State<PasswordBaruScreen> createState() => _PasswordBaruScreenState();
}

class _PasswordBaruScreenState extends State<PasswordBaruScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _konfirmasiController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  bool _isLoading = false;
  bool _berhasil = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  Future<void> _handleSimpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      final resetToken =
          (args is Map) ? args['reset_token'] as String? : null;

      if (resetToken == null || resetToken.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Token tidak valid, ulangi proses reset password'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final result = await ApiService().resetPassword(
        resetToken: resetToken,
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _berhasil = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal reset password'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tidak dapat terhubung ke server'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_berhasil) return _PasswordBerhasilView(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                padding: EdgeInsets.zero,
              ),

              const SizedBox(height: 32),

              const Text(
                'Buat Password Baru',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Password baru harus berbeda dengan\npassword sebelumnya.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Password Baru
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password Baru',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF888888)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF888888),
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFFD4865A), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Password tidak boleh kosong';
                        if (v.length < 8)
                          return 'Password minimal 8 karakter';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Konfirmasi Password
                    TextFormField(
                      controller: _konfirmasiController,
                      obscureText: _obscureKonfirmasi,
                      decoration: InputDecoration(
                        hintText: 'Konfirmasi Password',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF888888)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKonfirmasi
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF888888),
                          ),
                          onPressed: () => setState(
                              () => _obscureKonfirmasi = !_obscureKonfirmasi),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFFD4865A), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Konfirmasi password tidak boleh kosong';
                        if (v != _passwordController.text)
                          return 'Password tidak cocok';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSimpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4865A),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor:
                              const Color(0xFFD4865A).withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Simpan Password',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _PasswordBerhasilView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Ikon centang besar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4865A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFFD4865A),
                  size: 64,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Password Berhasil Dibuat',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                'Password kamu berhasil direset.\nSilakan masuk dengan password baru.',
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    height: 1.6),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4865A),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Masuk Sekarang',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}