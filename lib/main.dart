import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'service/fcm_service.dart';
import 'screens/auth/dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/daftar_screen.dart';
import 'screens/auth/lupa_password_screen.dart';
import 'screens/auth/verifikasi_otp_screen.dart';
import 'screens/auth/password_baru_screen.dart';
import 'screens/beranda/beranda_screen.dart';
import 'screens/katalog/katalog_screen.dart';
import 'screens/favorit/favorit_screen.dart';
import 'screens/detail/detail_resep_screen.dart';
import 'screens/detail/mulai_memasak_screen.dart';
import 'screens/notifikasi/notifikasi_screen.dart';
import 'screens/profil/profil_screen.dart';
import 'screens/payment/berlangganan_screen.dart';
import 'screens/payment/pembayaran_screen.dart';
import 'screens/payment/pembayaran_berhasil_screen.dart';
import 'screens/kamera/kamera_screen.dart';
import 'screens/resep_saya/resep_saya_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM dibungkus try-catch biar ga crash app kalau gagal
  try {
    await FcmService().init();
  } catch (e) {
    debugPrint('FCM skip: $e');
  }

  runApp(const ResepKitaApp());
}

class ResepKitaApp extends StatelessWidget {
  const ResepKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resep Kita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4865A),
          primary: const Color(0xFFD4865A),
          secondary: const Color(0xFFF5E6D3),
          background: const Color(0xFFFDF6F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF6F0),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2D2D2D),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4865A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD4865A),
            side: const BorderSide(color: Color(0xFFD4865A)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFD4865A), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/daftar': (context) => const DaftarScreen(),
        '/lupa-password': (context) => const LupaPasswordScreen(),
        '/verifikasi-otp': (context) => const VerifikasiOtpScreen(),
        '/password-baru': (context) => const PasswordBaruScreen(),
        '/beranda': (context) => const BerandaScreen(),
        '/katalog': (context) => const KatalogScreen(),
        '/favorit': (context) => const FavoritScreen(),
        '/detail-resep': (context) => const DetailResepScreen(),
        '/mulai-memasak': (context) => const MulaiMemasakScreen(),
        '/notifikasi': (context) => const NotifikasiScreen(),
        '/profil': (context) => const ProfilScreen(),
        '/berlangganan': (context) => const BerlanggananScreen(),
        '/pembayaran': (context) => const PembayaranScreen(),
        '/pembayaran-berhasil': (context) => const PembayaranBerhasilScreen(),
        '/kamera': (context) => const KameraScreen(),
        '/resep-saya': (context) => const ResepSayaScreen(),
      },
    );
  }
}