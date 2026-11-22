import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/fare_pricing_service.dart';
import '../../services/map_route_service.dart';

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

/// Penyimpanan pesanan sesi lokal agar pesanan Makan / Titip / Antar tetap
/// langsung tampil di Riwayat Pesanan meskipun pengguna sedang mode offline / demo.
class LocalOrderRecord {
  final String id;
  final String serviceType; // 'makan' | 'titip' | 'antar'
  final String items;
  final String originAddress;
  final String destinationAddress;
  final String note;
  final String status;
  final String price;
  final DateTime createdAt;

  const LocalOrderRecord({
    required this.id,
    required this.serviceType,
    required this.items,
    required this.originAddress,
    required this.destinationAddress,
    required this.note,
    this.status = 'pending',
    this.price = 'Rp 10.000',
    required this.createdAt,
  });
}

class SessionOrderStore {
  static final List<LocalOrderRecord> orders = [];

  static void addOrder(LocalOrderRecord record) {
    orders.insert(0, record);
  }
}

/// Formulir pesanan layanan Makan dan Titip.
///
/// - `makan`: makanan yang dipesan + alamat pengantaran (+ warung/kantin opsional)
/// - `titip`: barang apa yang mau dititip + dari alamat mana (+ alamat tujuan)
///
/// Setelah disimpan, pesanan masuk ke koleksi Firestore `orders` serta
/// `SessionOrderStore`, lalu langsung tampil di halaman Riwayat Pesanan.
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

  int _selectedPayment = 0;
  bool _loading = false;

  final MapController _mapController = MapController();
  LatLng _studentPos =
      MapRouteService.lastKnownDriverGps?.position ??
      MapRouteService.defaultKampusCenter;
  String _detectedStreet = 'Kampus USU Medan';

  @override
  void initState() {
    super.initState();
    _initGps();
  }

  Future<void> _initGps() async {
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: MapRouteService.defaultKampusCenter,
    );
    if (!mounted) return;
    setState(() => _studentPos = gps.position);
    final street = await MapRouteService.reverseGeocodePosition(gps.position);
    if (!mounted) return;
    setState(() {
      _detectedStreet = street;
      if (_isMakan && _destinationController.text.trim().isEmpty) {
        _destinationController.text = street;
      } else if (!_isMakan && _originController.text.trim().isEmpty) {
        _originController.text = street;
      }
    });
  }

  bool get _isMakan => widget.serviceType == 'makan';

  String get _title => _isMakan ? 'Pesan Makan' : 'Titip Barang';

  String get _subtitle => _isMakan
      ? 'Pilih atau tulis makanan yang mau dipesan beserta alamat pengantarannya.'
      : 'Tulis barang apa yang mau dititip dan dari alamat mana barang diambil.';

  static const List<String> _foodPresets = [
    'Nasi Ayam Geprek + Es Teh',
    'Mie Goreng Kampus + Telur',
    'Soto Ayam + Nasi Putih',
    'Kopi Susu Gula Aren',
    'Nasi Padang Ayam Bakar',
  ];

  static const List<String> _titipPresets = [
    'Print & Fotokopi Tugas',
    'Dokumen / Map KTM',
    'Beli Alat Tulis (ATK)',
    'Ambil Paket / Barang',
    'Buku / Modul Kuliah',
  ];

  static const List<Map<String, dynamic>> _paymentMethods = [
    {
      'label': 'GasPay',
      'code': 'wallet',
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'label': 'QRIS Kampus',
      'code': 'qris',
      'icon': Icons.qr_code_scanner_rounded,
    },
    {
      'label': 'Tunai (COD)',
      'code': 'cash',
      'icon': Icons.payments_rounded,
    },
  ];

  @override
  void dispose() {
    _itemsController.dispose();
    _vendorController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    final current = _itemsController.text.trim();
    setState(() {
      if (current.isEmpty) {
        _itemsController.text = preset;
      } else if (!current.contains(preset)) {
        _itemsController.text = '$current, $preset';
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final now = DateTime.now();
    final itemsText = _itemsController.text.trim();
    final originText = _isMakan
        ? (_vendorController.text.trim().isEmpty
              ? 'Kantin Kampus'
              : _vendorController.text.trim())
        : _originController.text.trim();
    final destinationText = _destinationController.text.trim().isEmpty
        ? 'Area Kampus'
        : _destinationController.text.trim();
    final noteText = _noteController.text.trim();
    final paymentCode =
        _paymentMethods[_selectedPayment]['code'] as String? ?? 'wallet';

    final int calculatedFare = FarePricingService.calculateMotorFare(1.0);
    final String formattedFare = FarePricingService.formatRupiah(calculatedFare);

    String docId = 'local_${now.millisecondsSinceEpoch}';

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final docRef = await FirebaseFirestore.instance
            .collection('orders')
            .add({
              'passengerId': uid,
              'driverId': null,
              'serviceType': widget.serviceType,
              'status': 'pending',
              'items': itemsText,
              'originName': _isMakan ? originText : null,
              'originAddress': originText,
              'destinationAddress': destinationText,
              'note': noteText,
              'fareAmount': calculatedFare,
              'paymentMethod': paymentCode,
              'createdAt': now.toIso8601String(),
            })
            .timeout(const Duration(seconds: 10));
        docId = docRef.id;
      }
    } catch (_) {
      // Tetap lanjutkan dengan penyimpanan sesi lokal jika koneksi Firestore terkendala
    }

    SessionOrderStore.addOrder(
      LocalOrderRecord(
        id: docId,
        serviceType: widget.serviceType,
        items: itemsText,
        originAddress: originText,
        destinationAddress: destinationText,
        note: noteText,
        status: 'pending',
        price: formattedFare,
        createdAt: now,
      ),
    );

    if (!mounted) return;
    setState(() => _loading = false);
    _showSnack(
      _isMakan
          ? 'Pesanan makan berhasil dibuat!'
          : 'Pesanan titip barang berhasil dibuat!',
      Colors.green,
    );
    Navigator.pop(context, true);
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
    final presets = _isMakan ? _foodPresets : _titipPresets;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title, style: _body(textPrimary, 18, FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Banner Info Layanan
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
                    width: 48,
                    height: 48,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isMakan
                              ? 'Layanan Pesan Makan Kampus'
                              : 'Layanan Titip Barang & Dokumen',
                          style: _body(textPrimary, 14, FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _subtitle,
                          style: _body(
                            textSecondary,
                            12,
                            FontWeight.w400,
                            h: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Peta Lokasi Live Kampus USU Medan
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 165,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GasKampusLiveMap(
                        mapController: _mapController,
                        mapStyle: GasMapStyle.street,
                        initialCenter: _studentPos,
                        initialZoom: 15.0,
                        markers: [
                          MapRouteService.buildPlacePinMarker(
                            point: _studentPos,
                            label: _detectedStreet,
                            color: accent,
                            icon: _isMakan
                                ? Icons.restaurant_rounded
                                : Icons.shopping_bag_rounded,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: kBgDark.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gps_fixed, color: kPrimary, size: 12),
                            const SizedBox(width: 5),
                            Text(
                              'Titik GPS: $_detectedStreet',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Pilihan Cepat (Quick Chips)
            Text(
              _isMakan ? 'Pilihan Cepat Menu Kampus' : 'Pilihan Cepat Titipan',
              style: _body(textSecondary, 12, FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: presets.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      onPressed: () => _applyPreset(preset),
                      backgroundColor: cardBg,
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      avatar: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16,
                        color: accent,
                      ),
                      label: Text(
                        preset,
                        style: _body(textPrimary, 12, FontWeight.w500),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Input Makanan yang Dipesan / Barang yang Mau Dititip
            _buildField(
              label: _isMakan
                  ? 'Makanan yang Dipesan'
                  : 'Barang Apa yang Mau Dititip',
              hint: _isMakan
                  ? 'Contoh: 1 Nasi Ayam Geprek pedas + 1 Es Teh Manis'
                  : 'Contoh: Dokumen KTM, 1 map plastik / Print modul 20 lembar',
              icon: _isMakan
                  ? Icons.fastfood_outlined
                  : Icons.inventory_2_outlined,
              iconColor: accent,
              controller: _itemsController,
              cardBg: cardBg,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            if (_isMakan) ...[
              // Untuk Makan: Alamat Pengantaran + Lokasi Kantin/Warung
              _buildField(
                label: 'Alamat Pengantaran',
                hint: 'Contoh: Gedung Fakultas Teknik Lt. 2 / Asrama Blok C',
                icon: Icons.location_on_outlined,
                iconColor: accent,
                controller: _destinationController,
                cardBg: cardBg,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Nama Warung / Kantin (Opsional)',
                hint: 'Contoh: Kantin Pusat Lt. 2 / Warung Bunda',
                icon: Icons.storefront_outlined,
                iconColor: textSecondary,
                controller: _vendorController,
                cardBg: cardBg,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isRequired: false,
              ),
            ] else ...[
              // Untuk Titip: Dari Alamat Mana + Alamat Tujuan Pengantaran
              _buildField(
                label: 'Dari Alamat Mana (Lokasi Pengambilan)',
                hint: 'Contoh: Gedung A Lantai 1, Lobby / Fotokopi Kampus',
                icon: Icons.my_location_rounded,
                iconColor: accent,
                controller: _originController,
                cardBg: cardBg,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Alamat Tujuan Pengantaran (Opsional)',
                hint: 'Contoh: Perpustakaan Kampus, Meja Resepsionis',
                icon: Icons.location_on_outlined,
                iconColor: textSecondary,
                controller: _destinationController,
                cardBg: cardBg,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isRequired: false,
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 16),

            // Catatan Tambahan
            _buildField(
              label: 'Catatan untuk Driver (Opsional)',
              hint: _isMakan
                  ? 'Contoh: Jangan pakai sambal, hubungi jika sudah sampai'
                  : 'Contoh: Barang mudah lecek, harap hati-hati',
              icon: Icons.sticky_note_2_outlined,
              iconColor: textSecondary,
              controller: _noteController,
              cardBg: cardBg,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isRequired: false,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Metode Pembayaran
            Text(
              'Metode Pembayaran',
              style: _body(textPrimary, 14, FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(_paymentMethods.length, (i) {
                final pm = _paymentMethods[i];
                final selected = _selectedPayment == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPayment = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(
                        right: i < _paymentMethods.length - 1 ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? kPrimary.withOpacity(isDark ? 0.2 : 0.25)
                            : cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? kPrimary : border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            pm['icon'] as IconData,
                            size: 20,
                            color: selected ? textPrimary : textSecondary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pm['label'] as String,
                            textAlign: TextAlign.center,
                            style: _body(
                              textPrimary,
                              11,
                              selected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Tombol Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: const Color(0xFF0F172A),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                icon: _loading
                    ? const SizedBox.shrink()
                    : Icon(
                        _isMakan
                            ? Icons.restaurant_menu_rounded
                            : Icons.local_shipping_outlined,
                        size: 20,
                      ),
                label: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF0F172A),
                        ),
                      )
                    : Text(
                        _isMakan ? 'Pesan Makan Sekarang' : 'Kirim Titipan',
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
              'Pesanan akan langsung tercatat di Riwayat Pesanan dan diteruskan ke driver terdekat.',
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
    required IconData icon,
    required Color iconColor,
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
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
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
          ),
        ),
      ],
    );
  }
}
