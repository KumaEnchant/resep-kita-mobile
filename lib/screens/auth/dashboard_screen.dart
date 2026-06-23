import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4865A),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4865A).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Judul
              const Text(
                'Resep Kita',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Selamat Datang!',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(flex: 2),

              // Tombol Masuk
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Masuk'),
              ),

              const SizedBox(height: 12),

              // Tombol Daftar
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/daftar'),
                child: const Text('Daftar'),
              ),

              const SizedBox(height: 24),

              // Lanjut sebagai tamu
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/beranda'),
                child: const Text(
                  'Lanjut Sebagai Tamu?',
                  style: TextStyle(
                    color: Color(0xFFD4865A),
                    fontSize: 14,
                    decoration: TextDecoration.underline,
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
