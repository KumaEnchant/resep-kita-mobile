import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:midtrans_sdk/midtrans_sdk.dart';
import '../../../service/api_service.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  bool _isLoading = false;
  MidtransSDK? _midtrans;

  // ── Sandbox keys (ganti ke production key saat live) ─────────────────────
  static const _clientKey = 'Mid-client-gGONotBjo5a_ohI7';

  @override
  void initState() {
    super.initState();
    _initMidtrans();
  }

  @override
  void dispose() {
    _midtrans?.removeTransactionFinishedCallback();
    super.dispose();
  }

  // ── Inisialisasi Midtrans SDK ─────────────────────────────────────────────
  Future<void> _initMidtrans() async {
    _midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: _clientKey,
        merchantBaseUrl: ApiService.baseUrl, // static getter
        enableLog: true,
        colorTheme: ColorTheme(
          colorPrimary: const Color(0xFFD4865A),
          colorPrimaryDark: const Color(0xFFB8704A),
          colorSecondary: const Color(0xFFE8A07A),
        ),
      ),
    );

    // result.status adalah String: 'success' | 'pending' | 'failure' | 'invalid'
    _midtrans?.setTransactionFinishedCallback((result) async {
      if (!mounted) return;

      debugPrint('Midtrans → status: ${result.status}, '
          'transactionId: ${result.transactionId}, '
          'message: ${result.message}');

      final paket = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>? ?? {};

      final status = result.status?.toLowerCase() ?? '';

      if (status == 'success' || status == 'pending') {
        // Beritahu backend (fallback selain webhook)
        await _konfirmasiKeBackend(result.transactionId ?? '');

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/pembayaran-berhasil',
            arguments: paket,
          );
        }
      } else {
        // 'failure', 'invalid', atau user tekan back (status null/kosong)
        if (mounted && status.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'failure'
                    ? 'Pembayaran gagal. Silakan coba lagi.'
                    : 'Pembayaran dibatalkan.',
              ),
              backgroundColor:
                  status == 'failure' ? Colors.red : Colors.orange,
            ),
          );
        }
      }
    });
  }

  // ── Konfirmasi ke backend setelah SDK callback sukses ─────────────────────
  Future<void> _konfirmasiKeBackend(String orderId) async {
    if (orderId.isEmpty) return;
    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/api/payment/success'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId}),
      );
    } catch (e) {
      debugPrint('Konfirmasi backend error: $e');
    }
  }

  // ── Hit backend → dapat snap_token → buka UI Midtrans ────────────────────
  Future<void> _handleBayar(Map<String, dynamic> paket) async {
    setState(() => _isLoading = true);

    try {
      final userId = ApiService().userId    ?? '';
      final nama   = ApiService().userName  ?? 'User';
      final email  = ApiService().userEmail ?? 'user@email.com';
      final orderId = 'PREMIUM-${DateTime.now().millisecondsSinceEpoch}';

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/payment/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id'      : userId,
          'order_id'     : orderId,
          'gross_amount' : paket['harga'],
          'durasi'       : paket['durasi'],
          'customer'     : {'name': nama, 'email': email},
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true || data['snap_token'] == null) {
        throw Exception(data['message'] ?? 'Gagal mendapat token pembayaran');
      }

      _midtrans?.startPaymentUiFlow(token: data['snap_token'] as String);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatHarga(int harga) {
    return 'Rp ${harga.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    final paket =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {'durasi': '1 Bulan', 'harga': 29900};

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Konfirmasi Pembayaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── RINGKASAN PAKET ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD4865A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium,
                              color: Color(0xFFD4865A), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resep Kita Premium',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  paket['durasi'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatHarga(paket['harga']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4865A),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── INFO METODE PEMBAYARAN ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5E6D3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.payment,
                                color: Color(0xFFD4865A), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pilih Metode Pembayaran',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'DANA, OVO, GoPay, Transfer Bank & lainnya',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Colors.grey, size: 18),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── BADGE AMAN ──
                    Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Pembayaran aman & terenkripsi oleh Midtrans',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Kamu akan diarahkan ke halaman pembayaran Midtrans. '
                      'Pilih metode favoritmu di sana.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── TOMBOL BAYAR ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleBayar(paket),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4865A),
                      disabledBackgroundColor:
                          const Color(0xFFD4865A).withValues(alpha: 0.6),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Bayar Sekarang · ${_formatHarga(paket['harga'])}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey),
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