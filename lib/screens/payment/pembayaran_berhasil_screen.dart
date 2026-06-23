import 'package:flutter/material.dart';

// ─── Pembayaran Berhasil ───────────────────────────────────────────────────

class PembayaranBerhasilScreen extends StatelessWidget {
  const PembayaranBerhasilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final paket =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {'durasi': '1 Bulan', 'harga': 29900};

    final now = DateTime.now();
    final berakhir = now.add(
      paket['id'] == '12_bulan'
          ? const Duration(days: 365)
          : paket['id'] == '3_bulan'
              ? const Duration(days: 90)
              : const Duration(days: 30),
    );

    String _fmt(DateTime d) =>
        '${d.day} ${['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'][d.month - 1]} ${d.year}';

    String _formatHarga(int h) =>
        'Rp ${h.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Ikon sukses
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4865A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFFD4865A), size: 64),
              ),

              const SizedBox(height: 24),

              const Text(
                'Pembayaran Berhasil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Terimakasih, kamu sekarang\npengguna premium!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 32),

              // Detail
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Paket', nilai: 'Resep Kita Premium ${paket['durasi']}'),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Tanggal', nilai: _fmt(now)),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Berakhir', nilai: _fmt(berakhir)),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Total',
                      nilai: _formatHarga(paket['harga']),
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/beranda', (r) => false),
                child: const Text('Kembali ke Beranda'),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String nilai;
  final bool isBold;
  const _DetailRow(
      {required this.label, required this.nilai, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        Text(
          nilai,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? const Color(0xFFD4865A) : const Color(0xFF2D2D2D),
          ),
        ),
      ],
    );
  }
}