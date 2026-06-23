import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../service/api_service.dart';

class VerifikasiOtpScreen extends StatefulWidget {
  const VerifikasiOtpScreen({super.key});

  @override
  State<VerifikasiOtpScreen> createState() => _VerifikasiOtpScreenState();
}

class _VerifikasiOtpScreenState extends State<VerifikasiOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _countdown = 45;
  Timer? _timer;
  bool _isLoading = false;
  String _email = '';
  String _method = 'email';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _email  = args['email']  as String? ?? '';
      _method = args['method'] as String? ?? 'email';
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      _handleVerifikasi(otp);
    }
  }

  Future<void> _handleVerifikasi(String otp) async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService().verifyOtp(
        email: _email,
        otp: otp,
      );

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result['success'] == true) {
        final resetToken = result['reset_token'] as String;
        Navigator.pushNamed(
          context,
          '/password-baru',
          arguments: {'reset_token': resetToken},
        );
      } else {
        // Kosongkan semua field OTP
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Kode OTP salah'),
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

  Future<void> _handleKirimUlang() async {
    if (_email.isEmpty) return;
    try {
      final result = await ApiService().forgotPassword(_email);
      if (!mounted) return;
      if (result['success'] == true) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kode OTP baru telah dikirim'),
            backgroundColor: const Color(0xFFD4865A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal mengirim ulang OTP'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
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

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
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
                'Verifikasi OTP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4865A).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFFD4865A),
                    size: 48,
                  ),
                ),
              ),

              Center(
                child: Text(
                  _method == 'email'
                      ? 'Kami telah mengirimkan kode OTP ke\nemail kamu di\n$_email'
                      : 'Kami telah mengirimkan kode OTP ke\nWhatsApp kamu',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // OTP Input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextFormField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !_isLoading,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4865A),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (v) => _onOtpChanged(v, i),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Countdown timer
              Center(
                child: _countdown > 0
                    ? Text(
                        'Kirim ulang kode dalam ${_formatTime(_countdown)}',
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 13),
                      )
                    : GestureDetector(
                        onTap: _handleKirimUlang,
                        child: const Text(
                          'Kirim Ulang OTP',
                          style: TextStyle(
                            color: Color(0xFFD4865A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              const Spacer(),

              // Tombol verifikasi
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          final otp =
                              _controllers.map((c) => c.text).join();
                          if (otp.length == 6) {
                            _handleVerifikasi(otp);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Masukkan 6 digit kode OTP'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
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
                          'Verifikasi',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Tidak menerima kode? Kirim ulang OTP',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12),
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