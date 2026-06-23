import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../../models/resep_model.dart';
import '../../../service/api_service.dart';

class TambahResepScreen extends StatefulWidget {
  final ResepModel? resepEdit;
  const TambahResepScreen({super.key, this.resepEdit});

  @override
  State<TambahResepScreen> createState() => _TambahResepScreenState();
}

class _TambahResepScreenState extends State<TambahResepScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isAnalyzingGizi = false;
  bool get _isEdit => widget.resepEdit != null;

  final _namaController      = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _waktuController     = TextEditingController(text: '30');

  final _kaloriController      = TextEditingController();
  final _proteinController     = TextEditingController();
  final _lemakController       = TextEditingController();
  final _karbohidratController = TextEditingController();
  final _seratController       = TextEditingController();
  final _natriumController     = TextEditingController();

  String _selectedKategori = 'Makanan';
  File? _fotoFile;
  String? _fotoUrlLama;

  final List<TextEditingController> _bahanControllers   = [TextEditingController()];
  final List<TextEditingController> _langkahControllers = [TextEditingController()];
  final List<String> _kategoriOptions = ['Makanan', 'Minuman', 'Kue'];

 static const String _openRouterApiKey = '';

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final r = widget.resepEdit!;
      _namaController.text      = r.nama;
      _deskripsiController.text = r.tipe;
      _waktuController.text     = r.waktuMenit.toString();
      _selectedKategori         = r.kategori;
      _fotoUrlLama              = r.gambar;

      if (r.infoGizi.isNotEmpty) {
        _kaloriController.text      = r.infoGizi['kalori']?.toString()      ?? '';
        _proteinController.text     = r.infoGizi['protein']?.toString()     ?? '';
        _lemakController.text       = r.infoGizi['lemak']?.toString()       ?? '';
        _karbohidratController.text = r.infoGizi['karbohidrat']?.toString() ?? '';
        _seratController.text       = r.infoGizi['serat']?.toString()       ?? '';
        _natriumController.text     = r.infoGizi['natrium']?.toString()     ?? '';
      }

      _bahanControllers.clear();
      for (final b in r.bahan.isEmpty ? [''] : r.bahan) {
        _bahanControllers.add(TextEditingController(text: b));
      }
      _langkahControllers.clear();
      for (final l in r.langkah.isEmpty ? [''] : r.langkah) {
        _langkahControllers.add(TextEditingController(text: l));
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _waktuController.dispose();
    _kaloriController.dispose();
    _proteinController.dispose();
    _lemakController.dispose();
    _karbohidratController.dispose();
    _seratController.dispose();
    _natriumController.dispose();
    for (final c in _bahanControllers) c.dispose();
    for (final c in _langkahControllers) c.dispose();
    super.dispose();
  }

  Future<void> _analisisGizi() async {
    final bahan = _bahanControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (bahan.isEmpty) {
      _showError('Isi bahan-bahan dulu sebelum analisis gizi!');
      return;
    }

    setState(() => _isAnalyzingGizi = true);

    try {
      final namaResep = _namaController.text.trim().isEmpty
          ? 'resep ini'
          : _namaController.text.trim();

      final prompt = '''
Saya punya resep "$namaResep" dengan bahan-bahan berikut:
${bahan.map((b) => '- $b').join('\n')}

Tolong estimasikan info gizi per porsi (1 sajian) untuk resep ini.
Berikan jawaban HANYA dalam format JSON berikut, tanpa penjelasan tambahan, tanpa markdown:
{
  "kalori": "xxx kkal",
  "protein": "xx gram",
  "lemak": "xx gram",
  "karbohidrat": "xx gram",
  "serat": "xx gram",
  "natrium": "xxx mg"
}
''';

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterApiKey',
        },
        body: jsonEncode({
          'model': 'openai/gpt-oss-120b:free',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('OpenRouter status: ${response.statusCode}');
      debugPrint('OpenRouter body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String;

        final cleaned = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
        if (jsonMatch != null) {
          final gizi = jsonDecode(jsonMatch.group(0)!);
          setState(() {
            _kaloriController.text      = gizi['kalori']?.toString()      ?? '';
            _proteinController.text     = gizi['protein']?.toString()     ?? '';
            _lemakController.text       = gizi['lemak']?.toString()       ?? '';
            _karbohidratController.text = gizi['karbohidrat']?.toString() ?? '';
            _seratController.text       = gizi['serat']?.toString()       ?? '';
            _natriumController.text     = gizi['natrium']?.toString()     ?? '';
          });

          if (mounted) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFD4865A), size: 48),
          const SizedBox(height: 12),
          const Text(
            'Analisis Gizi Berhasil! ✨',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Info gizi telah diisi otomatis oleh AI',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK', style: TextStyle(color: Color(0xFFD4865A))),
        ),
      ],
    ),
  );
}
        } else {
          _showError('Gagal parse response AI, coba lagi');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? 'Status ${response.statusCode}';
        _showError('AI error: $errorMsg');
      }
    } on Exception catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzingGizi = false);
    }
  }

  Future<void> _pilihFoto() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFD4865A)),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (picked != null) setState(() => _fotoFile = File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFD4865A)),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (picked != null) setState(() => _fotoFile = File(picked.path));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final bahan   = _bahanControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final langkah = _langkahControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    if (bahan.isEmpty)   { _showError('Tambahkan minimal 1 bahan');   return; }
    if (langkah.isEmpty) { _showError('Tambahkan minimal 1 langkah'); return; }

    setState(() => _isLoading = true);

    try {
      String gambarUrl = _fotoUrlLama ?? '';
      if (_fotoFile != null) {
        final uploadResult = await ApiService().uploadFoto(_fotoFile!);
        if (uploadResult['success'] == true) gambarUrl = uploadResult['url'] ?? '';
      }

      final infoGizi = {
        'kalori'     : _kaloriController.text.trim().isEmpty      ? '0 kkal' : _kaloriController.text.trim(),
        'protein'    : _proteinController.text.trim().isEmpty     ? '0 gram' : _proteinController.text.trim(),
        'lemak'      : _lemakController.text.trim().isEmpty       ? '0 gram' : _lemakController.text.trim(),
        'karbohidrat': _karbohidratController.text.trim().isEmpty ? '0 gram' : _karbohidratController.text.trim(),
        'serat'      : _seratController.text.trim().isEmpty       ? '0 gram' : _seratController.text.trim(),
        'natrium'    : _natriumController.text.trim().isEmpty     ? '0 mg'   : _natriumController.text.trim(),
      };

      final data = {
        'nama'       : _namaController.text.trim(),
        'kategori'   : _selectedKategori,
        'deskripsi'  : _deskripsiController.text.trim(),
        'waktu_menit': int.tryParse(_waktuController.text) ?? 30,
        'gambar'     : gambarUrl,
        'bahan'      : bahan,
        'langkah'    : langkah,
        'info_gizi'  : infoGizi,
        'rating'     : _isEdit ? widget.resepEdit!.rating : 0.0,
        'is_premium' : false,
        'dibuat_oleh': ApiService().userId ?? '',
      };

      final result = _isEdit
          ? await ApiService().editResep(widget.resepEdit!.id, data)
          : await ApiService().tambahResep(data);

      if (result['success'] == true && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Resep berhasil diupdate!' : 'Resep berhasil ditambahkan!'),
          backgroundColor: const Color(0xFFD4865A),
        ));
      } else {
        _showError(result['message'] ?? 'Gagal menyimpan resep');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? '✏️ Edit Resep' : '🍳 Tambah Resep Baru',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── INFORMASI DASAR ──
                      _SectionCard(
                        icon: '📋', title: 'Informasi Dasar',
                        child: Column(children: [
                          _buildLabel('Judul Resep *'),
                          TextFormField(
                            controller: _namaController,
                            decoration: _inputDecor('Contoh: Nasi Goreng Spesial'),
                            validator: (v) => v == null || v.isEmpty ? 'Judul tidak boleh kosong' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Kategori *'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedKategori,
                                isExpanded: true,
                                items: _kategoriOptions.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                                onChanged: (v) => setState(() => _selectedKategori = v!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Deskripsi'),
                          TextFormField(
                            controller: _deskripsiController,
                            maxLines: 3,
                            decoration: _inputDecor('Ceritakan sedikit tentang resep ini...'),
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('Durasi (menit) *'),
                          TextFormField(
                            controller: _waktuController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecor('30'),
                            validator: (v) => v == null || v.isEmpty ? 'Durasi tidak boleh kosong' : null,
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // ── FOTO ──
                      _SectionCard(
                        icon: '📸', title: 'Foto Resep',
                        child: GestureDetector(
                          onTap: _pilihFoto,
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _fotoFile != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_fotoFile!, fit: BoxFit.cover, width: double.infinity))
                                : _fotoUrlLama != null && _fotoUrlLama!.isNotEmpty
                                    ? Stack(children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(_fotoUrlLama!, fit: BoxFit.cover, width: double.infinity, height: 180),
                                        ),
                                        Positioned(bottom: 8, right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                            child: const Text('Tap untuk ganti', style: TextStyle(color: Colors.white, fontSize: 11)),
                                          )),
                                      ])
                                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text('Tap untuk upload foto resep', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text('JPG, PNG maksimal 5MB', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                      ]),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── BAHAN ──
                      _SectionCard(
                        icon: '🥕', title: 'Bahan-Bahan',
                        child: Column(children: [
                          ..._bahanControllers.asMap().entries.map((e) {
                            final i = e.key;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(color: const Color(0xFFF5E6D3), borderRadius: BorderRadius.circular(8)),
                                  child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD4865A)))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: TextFormField(controller: e.value, decoration: _inputDecor('Contoh: 500g ayam'))),
                                if (_bahanControllers.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                    onPressed: () => setState(() { _bahanControllers[i].dispose(); _bahanControllers.removeAt(i); }),
                                  ),
                              ]),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => setState(() => _bahanControllers.add(TextEditingController())),
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4865A)),
                            label: const Text('Tambah Bahan', style: TextStyle(color: Color(0xFFD4865A))),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // ── LANGKAH ──
                      _SectionCard(
                        icon: '📝', title: 'Langkah Memasak',
                        child: Column(children: [
                          ..._langkahControllers.asMap().entries.map((e) {
                            final i = e.key;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 28, height: 28,
                                  margin: const EdgeInsets.only(top: 12),
                                  decoration: BoxDecoration(color: const Color(0xFFD4865A), borderRadius: BorderRadius.circular(8)),
                                  child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: TextFormField(controller: e.value, maxLines: 2, decoration: _inputDecor('Jelaskan langkah ${i + 1}...'))),
                                if (_langkahControllers.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                    onPressed: () => setState(() { _langkahControllers[i].dispose(); _langkahControllers.removeAt(i); }),
                                  ),
                              ]),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => setState(() => _langkahControllers.add(TextEditingController())),
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4865A)),
                            label: const Text('Tambah Langkah', style: TextStyle(color: Color(0xFFD4865A))),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // ── INFO GIZI ──
                      _SectionCard(
                        icon: '🥗', title: 'Info Gizi',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isAnalyzingGizi ? null : _analisisGizi,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90D9),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFF4A90D9).withValues(alpha: 0.6),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _isAnalyzingGizi
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.auto_awesome, size: 18),
                              label: Text(_isAnalyzingGizi ? 'Menganalisis...' : '✨ Analisis Gizi dengan AI'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Isi bahan-bahan dulu, lalu klik tombol di atas untuk auto-generate info gizi',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _buildGiziField('Kalori', _kaloriController, 'kkal')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildGiziField('Protein', _proteinController, 'gram')),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: _buildGiziField('Lemak', _lemakController, 'gram')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildGiziField('Karbohidrat', _karbohidratController, 'gram')),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: _buildGiziField('Serat', _seratController, 'gram')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildGiziField('Natrium', _natriumController, 'mg')),
                          ]),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      // ── TOMBOL SIMPAN ──
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4865A),
                          disabledBackgroundColor: const Color(0xFFD4865A).withValues(alpha: 0.6),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text(
                                _isEdit ? 'Simpan Perubahan' : 'Publikasikan Resep',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiziField(String label, TextEditingController controller, String satuan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D))),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '0 $satuan',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4865A), width: 1.5)),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4865A), width: 1.5)),
      );

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D))),
      );
}

class _SectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}