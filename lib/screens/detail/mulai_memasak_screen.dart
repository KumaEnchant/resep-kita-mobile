import 'package:flutter/material.dart';
import '../../models/resep_model.dart';

class MulaiMemasakScreen extends StatefulWidget {
  const MulaiMemasakScreen({super.key});

  @override
  State<MulaiMemasakScreen> createState() => _MulaiMemasakScreenState();
}

class _MulaiMemasakScreenState extends State<MulaiMemasakScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final resep = ModalRoute.of(context)?.settings.arguments as ResepModel?;

    if (resep == null) {
      return const Scaffold(body: Center(child: Text('Resep tidak ditemukan')));
    }

    final totalStep = resep.langkah.length;
    final isLast = _currentStep == totalStep - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            // Gambar + header
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: Image.network(
                    resep.gambar,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFFF5E6D3),
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 64, color: Color(0xFFD4865A)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama resep + waktu
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resep.nama,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6D3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Color(0xFFD4865A)),
                              const SizedBox(width: 4),
                              Text(
                                '${resep.waktuMenit} mnt',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFD4865A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Progress indicator
                    Row(
                      children: [
                        Text(
                          'Langkah ${_currentStep + 1} dari $totalStep',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${((_currentStep + 1) / totalStep * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFD4865A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / totalStep,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4865A)),
                        minHeight: 8,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Langkah saat ini
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4865A),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${_currentStep + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            resep.langkah[_currentStep],
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF2D2D2D),
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Langkah selanjutnya (preview)
                    if (!isLast) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(() => _currentStep++),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6D3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Langkah Selanjutnya',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD4865A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                resep.langkah[_currentStep + 1],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Tombol navigasi
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Sebelumnya'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLast
                          ? () => Navigator.pop(context)
                          : () => setState(() => _currentStep++),
                      child: Text(isLast ? 'Selesai! 🎉' : 'Langkah Selanjutnya'),
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
