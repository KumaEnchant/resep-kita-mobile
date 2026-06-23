import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import '../../../service/api_service.dart';

class BerlanggananScreen extends StatefulWidget {
  const BerlanggananScreen({super.key});

  @override
  State<BerlanggananScreen> createState() => _BerlanggananScreenState();
}

class _BerlanggananScreenState extends State<BerlanggananScreen> {
  // ── Sandbox keys (ganti ke production key saat live) ─────────────────────
  static const _clientKey = 'Mid-client-gGONotBjo5a_ohI7';

  MidtransSDK? _midtrans;

  List<Map<String, dynamic>> _paket = [];
  String? _selectedPaket;
  bool _isLoadingPaket = true;
  String? _errorMsg;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _initMidtrans();
    _loadPaket();
  }

  @override
  void dispose() {
    _midtrans?.removeTransactionFinishedCallback();
    super.dispose();
  }

  // ✅ Ambil daftar paket premium dari API — bukan dummy lagi.
  // Backend yang nentuin harga/promo, bisa diubah tanpa update app.
  Future<void> _loadPaket() async {
    setState(() {
      _isLoadingPaket = true;
      _errorMsg = null;
    });
    try {
      final result = await ApiService().getPaketPremium();
      if (result['success'] == true && mounted) {
        final List data = result['data'] ?? [];
        final list = data.map((e) => Map<String, dynamic>.from(e)).toList();
        setState(() {
          _paket = list;
          _selectedPaket = list.isNotEmpty ? list.first['id'] as String : null;
          _isLoadingPaket = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMsg = 'Gagal memuat paket premium';
          _isLoadingPaket = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Tidak dapat terhubung ke server';
          _isLoadingPaket = false;
        });
      }
    }
  }

  // ── Inisialisasi Midtrans SDK ─────────────────────────────────────────────
  Future<void> _initMidtrans() async {
    _midtrans = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: _clientKey,
        merchantBaseUrl: ApiService.baseUrl,
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

      final selected = _paket.firstWhere(
        (p) => p['id'] == _selectedPaket,
        orElse: () => {'id': '1_bulan', 'durasi': '1 Bulan', 'harga': 0},
      );

      final status = result.status.toLowerCase() ;

      if (status == 'success' || status == 'pending') {
        // Beritahu backend (fallback selain webhook)
        if (result.transactionId != null && result.transactionId!.isNotEmpty) {
          await ApiService().paymentSuccess(result.transactionId!);
        }

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/pembayaran-berhasil',
            arguments: selected,
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

  // ── Hit backend → dapat snap_token → langsung buka UI Midtrans ───────────
  // (Dulu lewat layar ringkasan terpisah, sekarang langsung dari sini)
  Future<void> _handleBayar() async {
    final selected = _paket.firstWhere((p) => p['id'] == _selectedPaket);

    setState(() => _isProcessingPayment = true);

    try {
      final result = await ApiService().createPayment(
        grossAmount: (selected['harga'] as num).toInt(),
        durasi: selected['durasi'] as String,
        customerNama: ApiService().userName ?? 'User',
        customerEmail: ApiService().userEmail ?? 'user@email.com',
      );

      if (result['success'] != true || result['snap_token'] == null) {
        throw Exception(result['message'] ?? 'Gagal mendapat token pembayaran');
      }

      _midtrans?.startPaymentUiFlow(token: result['snap_token'] as String);
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
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  String _formatHarga(num harga) {
    final intHarga = harga.toInt();
    return 'Rp ${intHarga.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    final selected = _paket.isNotEmpty
        ? _paket.firstWhere(
            (p) => p['id'] == _selectedPaket,
            orElse: () => _paket.first,
          )
        : null;

    final bool bisaBayar = !_isLoadingPaket &&
        _errorMsg == null &&
        selected != null &&
        !_isProcessingPayment;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    'Resep Kita Premium',
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
                    // Banner premium
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4865A), Color(0xFFE8A07A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.workspace_premium,
                              color: Colors.white, size: 36),
                          const SizedBox(height: 12),
                          const Text(
                            'Resep Kita Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pilih paket yang paling cocok untukmu',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Fitur premium
                    const Text(
                      'Keuntungan Premium:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      'Akses semua resep VIP',
                      'Tanpa iklan',
                      'Bisa simpan resep tanpa batas',
                      'Konten premium tiap minggu',
                      'Fitur meal plan & belanja',
                    ].map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFFD4865A), size: 18),
                              const SizedBox(width: 10),
                              Text(f,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2D2D2D))),
                            ],
                          ),
                        )),

                    const SizedBox(height: 24),

                    // Pilihan paket
                    const Text(
                      'Pilih Paket:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingPaket)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFD4865A)),
                        ),
                      )
                    else if (_errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            const Icon(Icons.wifi_off,
                                size: 40, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(_errorMsg!,
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadPaket,
                              style:
                                  ElevatedButton.styleFrom(minimumSize: Size.zero),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._paket.map((paket) {
                        final isSelected = _selectedPaket == paket['id'];
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedPaket = paket['id'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFF3EC)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFD4865A)
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                isSelected 
                                    ? Icons.radio_button_checked 
                                    : Icons.radio_button_unchecked,
                                color: isSelected 
                                    ? const Color(0xFFD4865A) 
                                    : Colors.grey,
                                 ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            paket['durasi'] as String,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2D2D2D),
                                            ),
                                          ),
                                          if (paket['label'] != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color:
                                                    const Color(0xFFD4865A),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                paket['label'] as String,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _formatHarga(
                                                paket['harga'] as num),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD4865A),
                                            ),
                                          ),
                                          if (paket['harga_asli'] !=
                                              null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatHarga(
                                                  paket['harga_asli'] as num),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade400,
                                                decoration: TextDecoration
                                                    .lineThrough,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    if (!_isLoadingPaket &&
                        _errorMsg == null &&
                        _paket.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Pembayaran aman & terenkripsi oleh Midtrans. '
                              'Kamu bisa pilih GoPay, OVO, DANA, transfer bank, '
                              'QRIS, dan lainnya di langkah berikutnya.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Tombol bayar — langsung memicu Midtrans, tanpa layar ringkasan terpisah
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: bisaBayar ? _handleBayar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4865A),
                      disabledBackgroundColor:
                          const Color(0xFFD4865A).withValues(alpha: 0.5),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isProcessingPayment
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            selected != null
                                ? 'Bayar Sekarang · ${_formatHarga(selected['harga'] as num)}'
                                : 'Bayar Sekarang',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isProcessingPayment
                        ? null
                        : () => Navigator.pop(context),
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