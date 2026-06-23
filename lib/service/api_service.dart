import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? userId;
  String? userName;
  String? userEmail;
  bool isPremium = false;

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ─── AUTH ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({'nama': nama, 'email': email, 'password': password, 'phone': phone}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      userId    = data['data']['id']?.toString();
      userName  = data['data']['nama'];
      userEmail = data['data']['email'];
      isPremium = data['data']['is_premium'] ?? false;
    }
    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: _headers,
      body: jsonEncode({'id_token': idToken}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      userId    = data['data']['id']?.toString();
      userName  = data['data']['nama'];
      userEmail = data['data']['email'];
      isPremium = data['data']['is_premium'] ?? false;
    }
    return data;
  }

  Future<bool> refreshPremiumStatus() async {
    if (userId == null) return isPremium;
    try {
      final result = await getUser();
      if (result['success'] == true) {
        isPremium = result['data']['is_premium'] ?? false;
      }
    } catch (_) {}
    return isPremium;
  }

  Future<void> simpanFcmToken(String token) async {
    if (userId == null) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/api/auth/fcm-token'),
        headers: _headers,
        body: jsonEncode({'user_id': userId, 'token': token}),
      );
    } catch (_) {}
  }

  void logout() {
    userId    = null;
    userName  = null;
    userEmail = null;
    isPremium = false;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: _headers,
      body: jsonEncode({'reset_token': resetToken, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ─── RESEP ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getResep({String? search, String? kategori}) async {
    String url = '$baseUrl/api/resep?';
    if (userId != null) url += 'user_id=$userId&';
    if (search != null && search.isNotEmpty) url += 'search=$search&';
    if (kategori != null && kategori != 'Semua') url += 'kategori=$kategori';
    final res = await http.get(Uri.parse(url));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getDetailResep(String resepId) async {
    String url = '$baseUrl/api/resep/$resepId';
    if (userId != null) url += '?user_id=$userId';
    final res = await http.get(Uri.parse(url));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getRekomendasi() async {
    String url = '$baseUrl/api/resep/rekomendasi/list';
    if (userId != null) url += '?user_id=$userId';
    final res = await http.get(Uri.parse(url));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getResepPopuler({String? tipe}) async {
    String url = '$baseUrl/api/resep/populer/list?';
    if (userId != null) url += 'user_id=$userId&';
    if (tipe != null) url += 'tipe=$tipe';
    final res = await http.get(Uri.parse(url));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getResepSaya() async {
    if (userId == null) return {'success': false, 'data': []};
    final res = await http.get(Uri.parse('$baseUrl/api/resep/user/$userId'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> tambahResep(Map<String, dynamic> data) async {
    if (userId == null) return {'success': false, 'message': 'Belum login'};
    data['dibuat_oleh'] = userId;
    final res = await http.post(
      Uri.parse('$baseUrl/api/resep'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> editResep(String resepId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/resep/$resepId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> hapusResep(String resepId) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/resep/$resepId'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> uploadFotoProfil(File file) async {
    try {
      final bytes = await file.readAsBytes();

      if (bytes.length > 700 * 1024) {
        return {
          'success': false,
          'message': 'Ukuran foto terlalu besar, coba pilih foto lain',
        };
      }

      final ext  = file.path.split('.').last.toLowerCase();
      final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';

      return {'success': true, 'url': dataUri};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadFoto(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload/foto'),
      );
      request.files.add(await http.MultipartFile.fromPath('foto', file.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── FAVORIT ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFavorit() async {
    if (userId == null) return {'success': false, 'data': []};
    final res = await http.get(Uri.parse('$baseUrl/api/favorit/$userId'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> toggleFavorit(String resepId) async {
    if (userId == null) return {'success': false};
    final res = await http.post(
      Uri.parse('$baseUrl/api/favorit/toggle'),
      headers: _headers,
      body: jsonEncode({'user_id': userId, 'resep_id': resepId}),
    );
    return jsonDecode(res.body);
  }

  // ─── NOTIFIKASI ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getNotifikasi() async {
    if (userId == null) return {'success': false, 'data': []};
    final res = await http.get(Uri.parse('$baseUrl/api/notifikasi/$userId'));
    return jsonDecode(res.body);
  }

  Future<void> bacaNotifikasi(String notifId) async {
    await http.put(Uri.parse('$baseUrl/api/notifikasi/baca/$notifId'));
  }

  Future<void> bacaSemuaNotifikasi() async {
    if (userId == null) return;
    await http.put(Uri.parse('$baseUrl/api/notifikasi/baca-semua/$userId'));
  }

  // ─── PREMIUM / PAKET ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPaketPremium() async {
    final res = await http.get(Uri.parse('$baseUrl/api/premium/paket'));
    return jsonDecode(res.body);
  }

  // ─── PAYMENT ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createPayment({
    required int grossAmount,
    required String durasi,
    required String customerNama,
    required String customerEmail,
  }) async {
    final orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';
    final res = await http.post(
      Uri.parse('$baseUrl/api/payment/create'),
      headers: _headers,
      body: jsonEncode({
        'user_id'      : userId,
        'order_id'     : orderId,
        'gross_amount' : grossAmount,
        'durasi'       : durasi,
        'customer'     : {'name': customerNama, 'email': customerEmail},
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/payment/status/$orderId'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> paymentSuccess(String orderId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/payment/success'),
      headers: _headers,
      body: jsonEncode({'order_id': orderId}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      isPremium = true;
    }
    return data;
  }

  // ─── USER ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUser() async {
    if (userId == null) return {'success': false};
    final res = await http.get(Uri.parse('$baseUrl/api/user/$userId'));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      isPremium = data['data']['is_premium'] ?? false;
    }
    return data;
  }

  Future<Map<String, dynamic>> updateUser({
    required String nama,
    String? phone,
    String? username,
    String? bio,
    String? fotoUrl,
  }) async {
    if (userId == null) return {'success': false};
    final body = <String, dynamic>{
      'nama': nama,
      if (phone    != null) 'phone'   : phone,
      if (username != null) 'username': username,
      if (bio      != null) 'bio'     : bio,
      if (fotoUrl  != null) 'foto_url': fotoUrl,
    };
    final res = await http.put(
      Uri.parse('$baseUrl/api/user/$userId'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }
}