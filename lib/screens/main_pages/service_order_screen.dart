import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(
      color: c,
      fontSize: sz,
      fontWeight: w,
      letterSpacing: ls,
      height: h,
    );

/// Formulir pesanan layanan Makan dan Titip.
///
/// - `makan`: makanan/minuman yang dipesan + alamat pengantaran
/// - `titip`: barang yang dititip + alamat asal (penjemputan) + alamat tujuan
///
/// Setelah disimpan, pesanan masuk ke koleksi Firestore `orders` dan langsung
/// tampil di halaman Pesanan (tab Riwayat Pesanan).
class ServiceOrderScreen extends StatefulWidget {
  /// 'makan' atau 'titip'
  final String serviceType;

  const ServiceOrderScreen({super.key, required this.serviceType});

  @override
  State<ServiceOrderScreen> createState() => _ServiceOrderScreenState();
}

class _ServiceOrderScreenState extends State<ServiceOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _itemsController = TextEditingController();
  final _vendorController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _noteController = TextEditingController();

  bool _loading = false;

  bool get _isMakan => widget.serviceType == 'makan';

  String get _title => _isMakan ? 'Pesan Makan' : 'Titip Barang';

  String get _subtitle => _isMakan
      ? 'Tulis makanan yang mau dipesan, alamat warung, dan alamat pengantarannya.'
      : 'Tulis barang yang mau dititip, dari alamat mana, dan mau diantar ke mana.';

  @override
  void dispose() {
    _itemsController.dispose();
    _vendorController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showSnack('Kamu harus masuk dulu untuk memesan.', Colors.red);
      return;
    }

    setState(() => _loading = true);

    try {
      final origin = _isMakan
          ? _vendorController.text.trim()
          : _originController.text.trim();

      await FirebaseFirestore.instance.collection('orders').add({
        'passengerId': uid,
        'driverId': null,
        'serviceType': widget.serviceType,
        'status': 'pending',
        'items': _itemsController.text.trim(),
        'originName': _isMakan ? _vendorController.text.trim() : null,
        'originAddress': origin,
        'destinationAddress': _destinationController.text.trim(),
        'note': _noteController.text.trim(),
        'fareAmount': 0,
        'paymentMethod': 'wallet',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _showSnack(
        _isMakan ? 'Pesanan makan dikirim.' : 'Titipan dikirim.',
        Colors.green,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal membuat pesanan: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final cardBg = isDark ? const Color(0xFF1A2210) : Colors.white;
    final border = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final accent = _isMakan ? const Color(0xFFFF9F43) : const Color(0xFF54A0FF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title, style: _body(textPrimary, 17, FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isMakan
                          ? Icons.restaurant_rounded
                          : Icons.shopping_bag_rounded,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _subtitle,
                      style: _body(textSecondary, 13, FontWeight.w500, h: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildField(
              label: _isMakan
                  ? 'Makanan yang dipesan'
                  : 'Barang yang mau dititip',
              hint: _isMakan
                  ? 'Contoh: Nasi ayam geprek + es teh'
                  : 'Contoh: Dokumen KTM, 1 map plastik',
              controller: _itemsController,
              cardBg: cardBg,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            if (_isMakan) ...[
              _buildField(
                label: 'Alamat warung / kantin',
                hint: 'Contoh: Kantin Pusat, lantai 2',
                controller: _vendorController,
                cardBg: cardBg,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Alamat pengantaran',
                hint: 'Contoh: Asrama Mahasiswa Blok C, kamar 12',
                controller: _destinationController,
                cardBg: cardBg,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                maxLines: 2,
              ),
            ] else ...[
              _buildField(
                label: 'Alamat asal (titipan diambil dari)',
                hint: 'Contoh: Gedung A lantai 1, lobby',
                controller: _originController,
                cardBg: cardBg,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Alamat tujuan (titipan diantar ke)',
                hint: 'Contoh: Perpustakaan kampus, meja resepsionis',
                controller: _destinationController,
                cardBg: cardBg,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 16),

            _buildField(
              label: 'Catatan untuk driver (opsional)',
              hint: 'Contoh: jangan pakai sambal, telp kalau sudah sampai',
              controller: _noteController,
              cardBg: cardBg,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isRequired: false,
              maxLines: 2,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: const Color(0xFF0F172A),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF0F172A),
                        ),
                      )
                    : Text(
                        _isMakan ? 'Pesan Sekarang' : 'Kirim Titipan',
                        style: _body(
                          const Color(0xFF0F172A),
                          15,
                          FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pesanan akan langsung muncul di halaman Pesanan dan diteruskan ke driver terdekat.',
              textAlign: TextAlign.center,
              style: _body(textSecondary, 11, FontWeight.normal, h: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Color cardBg,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    bool isRequired = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _body(textPrimary, 14, FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: _body(textPrimary, 14, FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _body(
                textSecondary.withOpacity(0.6),
                13,
                FontWeight.normal,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            validator: isRequired
                ? (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return '$label wajib diisi.';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
