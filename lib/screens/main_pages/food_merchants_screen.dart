import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/merchant_model.dart';
import '../../services/fare_pricing_service.dart';
import '../../services/map_route_service.dart';
import '../../services/merchant_service.dart';
import '../../services/wallet_service.dart';
import '../../widgets/insufficient_gaspay_sheet.dart';
import '../payment_success_screen.dart';
import 'food_order_tracking_screen.dart';
import 'service_order_screen.dart';
import 'topup_modal.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kPrimaryDeep = Color(0xFF8DBF1A);
const Color kBgDark = Color(0xFF0E1009);
const Color kBgLight = Color(0xFFF5F7F0);
const Color kCardDark = Color(0xFF1C2414);
const Color kBorderDark = Color(0xFF2A3518);
const Color kBorderLight = Color(0xFFE8EDE0);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(
      color: c,
      fontSize: sz,
      fontWeight: w,
      letterSpacing: ls,
      height: h,
    );

/// Halaman daftar Merchant Toko Makanan yang tampil saat mahasiswa menekan tombol "Makan".
/// Menampilkan banner toko, alamat toko, dan preview menu apa saja yang tersedia.
class FoodMerchantsScreen extends StatefulWidget {
  const FoodMerchantsScreen({super.key});

  @override
  State<FoodMerchantsScreen> createState() => _FoodMerchantsScreenState();
}

class _FoodMerchantsScreenState extends State<FoodMerchantsScreen> {
  final MerchantService _merchantService = MerchantService();
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedCategory = 'Semua';
  LatLng _studentPos =
      MapRouteService.lastKnownDriverGps?.position ??
      MapRouteService.defaultKampusCenter;

  @override
  void initState() {
    super.initState();
    FarePricingService.init();
    _detectStudentGps();
  }

  Future<void> _detectStudentGps() async {
    final gps = await MapRouteService.getCurrentDriverPosition(
      campusFallback: MapRouteService.defaultKampusCenter,
    );
    if (!mounted) return;
    setState(() => _studentPos = gps.position);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double _distanceKmTo(MerchantModel m) {
    final meters = MapRouteService.distanceInMeters(
      _studentPos,
      LatLng(m.latitude, m.longitude),
    );
    return math.max(0.3, meters / 1000.0);
  }

  Future<void> _openManualFoodForm() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ServiceOrderScreen(serviceType: 'makan'),
      ),
    );
    if (res == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _openMerchantDetail(MerchantModel merchant) async {
    final ordered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantDetailOrderScreen(
          merchant: merchant,
          studentPos: _studentPos,
        ),
      ),
    );
    if (ordered == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final card = isDark ? kCardDark : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);
    final border = isDark ? kBorderDark : kBorderLight;

    final filterCategories = ['Semua', ...kMerchantCategories];
    final query = _searchCtrl.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Toko Makanan Kampus',
          style: _body(tp, 18, FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openManualFoodForm,
            icon: const Icon(
              Icons.edit_note_rounded,
              size: 18,
              color: kPrimaryDeep,
            ),
            label: Text(
              'Pesan Manual',
              style: _body(kPrimaryDeep, 12, FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: ts, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: _body(tp, 13.5, FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Cari nama toko, menu makanan, atau alamat...',
                        hintStyle: _body(ts, 13, FontWeight.normal),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _searchCtrl.clear()),
                      child: Icon(Icons.close_rounded, color: ts, size: 18),
                    ),
                ],
              ),
            ),
          ),

          // Filter Kategori (Slide horizontal)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filterCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = filterCategories[i];
                final active = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active ? kPrimary : card,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: active ? kPrimary : border),
                    ),
                    child: Text(
                      cat,
                      style: _body(
                        active ? const Color(0xFF0A0F02) : tp,
                        12,
                        active ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Daftar Toko Makanan
          Expanded(
            child: StreamBuilder<List<MerchantModel>>(
              stream: _merchantService.streamMerchants(),
              builder: (context, snapshot) {
                final rawList = snapshot.data ?? [];
                final merchants = rawList.isNotEmpty
                    ? rawList
                    : MerchantService.fallbackDemoMerchants;

                final filtered = merchants.where((m) {
                  if (_selectedCategory != 'Semua' &&
                      m.category != _selectedCategory) {
                    return false;
                  }
                  if (query.isEmpty) return true;
                  final matchStore =
                      m.name.toLowerCase().contains(query) ||
                      m.address.toLowerCase().contains(query) ||
                      m.category.toLowerCase().contains(query);
                  final matchMenu = m.menus.any(
                    (menu) => menu.name.toLowerCase().contains(query),
                  );
                  return matchStore || matchMenu;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 56,
                            color: ts.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Toko atau menu tidak ditemukan',
                            style: _body(tp, 15.5, FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Coba kata kunci lain atau pesan manual langsung ke warung pilihanmu.',
                            textAlign: TextAlign.center,
                            style: _body(ts, 12.5, FontWeight.normal),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _openManualFoodForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: const Color(0xFF0A0F02),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Pesan Manual Warung Lain',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final merchant = filtered[index];
                    final distKm = _distanceKmTo(merchant);
                    return _buildMerchantCard(
                      merchant: merchant,
                      distKm: distKm,
                      card: card,
                      border: border,
                      tp: tp,
                      ts: ts,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard({
    required MerchantModel merchant,
    required double distKm,
    required Color card,
    required Color border,
    required Color tp,
    required Color ts,
    required bool isDark,
  }) {
    final availableMenus = merchant.menus.where((m) => m.isAvailable).toList();

    return InkWell(
      onTap: () => _openMerchantDetail(merchant),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Toko Makanan
            MerchantBannerView(merchant: merchant, height: 144),

            // Informasi Nama, Alamat & Menu Tersedia
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          merchant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _body(tp, 16, FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        merchant.rating.toStringAsFixed(1),
                        style: _body(tp, 12.5, FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Alamat lengkap toko makanan
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Color(0xFFFF9F43),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${merchant.address} · ${distKm.toStringAsFixed(1)} km',
                          style: _body(ts, 12, FontWeight.w500, h: 1.35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Daftar menu apa saja yang tersedia di merchant ini
                  Text(
                    'Menu Tersedia:',
                    style: _body(tp, 11.5, FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (availableMenus.isEmpty)
                    Text(
                      'Belum ada menu aktif saat ini.',
                      style: _body(ts, 11.5, FontWeight.normal),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: availableMenus.map((menu) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF253019)
                                  : const Color(0xFFF5F7F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: border),
                            ),
                            child: Text(
                              '${menu.name} · ${MerchantService.formatRupiah(menu.price)}',
                              style: _body(tp, 11.5, FontWeight.w600),
                            ),
                          );
                        }).toList(),
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

/// Halaman detail satu toko makanan: menampilkan banner toko, alamat lengkap & peta lokasi toko,
/// daftar semua menu makanan beserta harga & stok, serta checkout order.
class MerchantDetailOrderScreen extends StatefulWidget {
  final MerchantModel merchant;
  final LatLng studentPos;

  const MerchantDetailOrderScreen({
    super.key,
    required this.merchant,
    required this.studentPos,
  });

  @override
  State<MerchantDetailOrderScreen> createState() =>
      _MerchantDetailOrderScreenState();
}

class _MerchantDetailOrderScreenState extends State<MerchantDetailOrderScreen> {
  final Map<String, int> _cartQty = {};
  final TextEditingController _destAddressCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  String _selectedMenuCategory = 'Semua';
  int _selectedPayment = 0; // 0: GasPay, 1: QRIS, 2: Tunai
  int _walletBalance = 0;
  bool _submitting = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _walletSub;

  @override
  void initState() {
    super.initState();
    _detectStudentDeliveryAddress();
    _listenWallet();
  }

  Future<void> _detectStudentDeliveryAddress() async {
    final street = await MapRouteService.reverseGeocodePosition(
      widget.studentPos,
    );
    if (!mounted) return;
    if (_destAddressCtrl.text.trim().isEmpty) {
      setState(() => _destAddressCtrl.text = street);
    }
  }

  void _listenWallet() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _walletSub = FirebaseFirestore.instance
        .collection('wallets')
        .doc(uid)
        .snapshots()
        .listen((doc) {
          if (!mounted) return;
          final bal = (doc.data()?['balance'] as num?)?.toInt() ?? 0;
          setState(() => _walletBalance = bal);
        });
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _destAddressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _distanceKm {
    final meters = MapRouteService.distanceInMeters(
      LatLng(widget.merchant.latitude, widget.merchant.longitude),
      widget.studentPos,
    );
    return math.max(0.5, meters / 1000.0);
  }

  int get _deliveryFee => FarePricingService.calculateMotorFare(_distanceKm);

  int get _totalQty => _cartQty.values.fold(0, (a, b) => a + b);

  int get _foodSubtotal {
    var sum = 0;
    for (final menu in widget.merchant.menus) {
      final qty = _cartQty[menu.id] ?? 0;
      sum += menu.price * qty;
    }
    return sum;
  }

  int get _grandTotal => _foodSubtotal + (_totalQty > 0 ? _deliveryFee : 0);

  void _changeQty(MerchantMenuItem item, int delta) {
    if (!item.isAvailable || !widget.merchant.isOpen) return;
    setState(() {
      final next = (_cartQty[item.id] ?? 0) + delta;
      if (next <= 0) {
        _cartQty.remove(item.id);
      } else {
        _cartQty[item.id] = next;
      }
    });
  }

  void _showStoreMapModal(Color card, Color tp, Color ts, Color border) {
    final storeLatLng = LatLng(
      widget.merchant.latitude,
      widget.merchant.longitude,
    );
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: 230,
                width: double.infinity,
                child: GasKampusLiveMap(
                  mapController: MapController(),
                  mapStyle: GasMapStyle.street,
                  initialCenter: storeLatLng,
                  initialZoom: 15.2,
                  markers: [
                    MapRouteService.buildPlacePinMarker(
                      point: storeLatLng,
                      label: widget.merchant.name,
                      color: const Color(0xFFFF9F43),
                      icon: Icons.storefront_rounded,
                    ),
                    MapRouteService.buildPlacePinMarker(
                      point: widget.studentPos,
                      label: 'Lokasimu',
                      color: const Color(0xFF16A34A),
                      icon: Icons.person_pin_circle_rounded,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.merchant.name,
                    style: _body(tp, 16, FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.merchant.address,
                    style: _body(ts, 12.5, FontWeight.w500, h: 1.35),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: const Color(0xFF0A0F02),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Tutup Peta',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  void _openCheckoutSheet(
    bool isDark,
    Color card,
    Color tp,
    Color ts,
    Color border,
  ) {
    if (_totalQty <= 0) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final selectedItems = widget.merchant.menus
                .where((m) => (_cartQty[m.id] ?? 0) > 0)
                .toList();

            const paymentOptions = [
              ('GasPay', Icons.account_balance_wallet_rounded),
              ('QRIS', Icons.qr_code_scanner_rounded),
              ('Tunai', Icons.payments_rounded),
            ];

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.9,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ts.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Konfirmasi Pesanan Makan',
                    style: _body(tp, 18, FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.merchant.name} · ${widget.merchant.address}',
                    style: _body(ts, 12, FontWeight.w500),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 12),

                  // Rincian Menu
                  ...selectedItems.map((m) {
                    final qty = _cartQty[m.id] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '${qty}x',
                            style: _body(kPrimaryDeep, 13, FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.name,
                              style: _body(tp, 13.5, FontWeight.w600),
                            ),
                          ),
                          Text(
                            MerchantService.formatRupiah(m.price * qty),
                            style: _body(tp, 13, FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                  Divider(color: border, height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal Menu', style: _body(ts, 12.5, FontWeight.w500)),
                      Text(
                        MerchantService.formatRupiah(_foodSubtotal),
                        style: _body(tp, 13, FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ongkir Antar (${_distanceKm.toStringAsFixed(1)} km)',
                        style: _body(ts, 12.5, FontWeight.w500),
                      ),
                      Text(
                        MerchantService.formatRupiah(_deliveryFee),
                        style: _body(tp, 13, FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Bayar', style: _body(tp, 15, FontWeight.bold)),
                      Text(
                        MerchantService.formatRupiah(_grandTotal),
                        style: _body(tp, 17, FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alamat Pengantaran Mahasiswa
                  Text(
                    'Alamat Pengantaran Kamu',
                    style: _body(tp, 13, FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _destAddressCtrl,
                    maxLines: 2,
                    style: _body(tp, 13.5, FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Gedung Fasilkom-TI USU Lt. 2',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Catatan (Opsional)',
                    style: _body(tp, 13, FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteCtrl,
                    style: _body(tp, 13.5, FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Jangan terlalu pedas, titip di pos',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metode Pembayaran
                  Text(
                    'Metode Pembayaran',
                    style: _body(tp, 13, FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(paymentOptions.length, (i) {
                      final active = _selectedPayment == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheet(() {});
                            setState(() => _selectedPayment = i);
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active
                                  ? kPrimary.withValues(alpha: 0.22)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active ? kPrimary : border,
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  paymentOptions[i].$2,
                                  size: 20,
                                  color: tp,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  paymentOptions[i].$1,
                                  style: _body(
                                    tp,
                                    11.5,
                                    active ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                                if (i == 0)
                                  Text(
                                    'Rp ${WalletService.formatRupiah(_walletBalance)}',
                                    style: _body(ts, 9.5, FontWeight.w500),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () => _submitMerchantOrder(sheetCtx, setSheet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: const Color(0xFF0A0F02),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF0A0F02),
                              ),
                            )
                          : Text(
                              'Pesan & Bayar (${MerchantService.formatRupiah(_grandTotal)})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitMerchantOrder(
    BuildContext sheetCtx,
    StateSetter setSheet,
  ) async {
    final dest = _destAddressCtrl.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(sheetCtx).showSnackBar(
        const SnackBar(content: Text('Isi alamat pengantaran terlebih dahulu.')),
      );
      return;
    }

    final totalPay = _grandTotal;
    final paymentCode = _selectedPayment == 0
        ? 'GasPay'
        : (_selectedPayment == 1 ? 'QRIS' : 'Tunai');

    if (_selectedPayment == 0 && _walletBalance < totalPay) {
      await showInsufficientGasPaySheet(
        context: sheetCtx,
        currentBalance: _walletBalance,
        requiredAmount: totalPay,
        onTopUp: () => showTopUpModal(context),
        onSwitchToCash: () {
          setSheet(() => _selectedPayment = 2);
          setState(() => _selectedPayment = 2);
        },
      );
      return;
    }

    setSheet(() => _submitting = true);
    setState(() => _submitting = true);

    final selectedItems = widget.merchant.menus
        .where((m) => (_cartQty[m.id] ?? 0) > 0)
        .toList();
    final itemsSummary = selectedItems
        .map((m) => '${_cartQty[m.id]}x ${m.name}')
        .join(', ');
    final now = DateTime.now();
    String docId = 'food_${now.millisecondsSinceEpoch}';
    int? remainingBalance;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final db = FirebaseFirestore.instance;
        String buyerName = 'Mahasiswa';
        try {
          final uDoc = await db.collection('users').doc(user.uid).get();
          buyerName = (uDoc.data()?['name'] ?? 'Mahasiswa').toString();
        } catch (_) {}

        if (_selectedPayment == 0) {
          final walletRef = db.collection('wallets').doc(user.uid);
          final txRef = walletRef.collection('transactions').doc();
          remainingBalance = await db.runTransaction<int>((tx) async {
            final snap = await tx.get(walletRef);
            final cur = (snap.data()?['balance'] as num?)?.toInt() ?? 0;
            final next = math.max(0, cur - totalPay);
            tx.set(walletRef, {
              'userId': user.uid,
              'balance': next,
              'updatedAt': now.toIso8601String(),
            }, SetOptions(merge: true));
            tx.set(txRef, {
              'transactionId': txRef.id,
              'walletId': user.uid,
              'type': 'payment',
              'amount': totalPay,
              'description': 'Pesan Makan di ${widget.merchant.name}',
              'createdAt': now.toIso8601String(),
            });
            return next;
          });
        }

        final docRef = await db.collection('orders').add({
          'passengerId': user.uid,
          'passengerName': buyerName,
          'driverId': null,
          'merchantId': widget.merchant.id,
          'merchantName': widget.merchant.name,
          'serviceType': 'makan',
          'status': 'pending',
          'items': itemsSummary,
          'orderedItems': selectedItems
              .map((m) => {
                    'id': m.id,
                    'name': m.name,
                    'qty': _cartQty[m.id],
                    'price': m.price,
                  })
              .toList(),
          'originName': widget.merchant.name,
          'originAddress': widget.merchant.address,
          'destinationAddress': dest,
          'note': _noteCtrl.text.trim(),
          'foodSubtotal': _foodSubtotal,
          'deliveryFare': _deliveryFee,
          'fareAmount': totalPay,
          'distanceKm': _distanceKm,
          'paymentMethod': paymentCode,
          'paymentStatus': paymentCode == 'Tunai' ? 'unpaid' : 'paid',
          'createdAt': now.toIso8601String(),
        }).timeout(const Duration(seconds: 8));
        docId = docRef.id;
      }
    } catch (_) {}

    final formattedTotal = MerchantService.formatRupiah(totalPay);
    SessionOrderStore.addOrder(
      LocalOrderRecord(
        id: docId,
        serviceType: 'makan',
        items: '${widget.merchant.name}: $itemsSummary',
        originAddress: widget.merchant.address,
        destinationAddress: dest,
        note: _noteCtrl.text.trim(),
        status: 'pending',
        price: formattedTotal,
        createdAt: now,
      ),
    );
    AppNotificationStore.add(
      title: 'Pesanan Makan ke ${widget.merchant.name}',
      message: '$itemsSummary • $formattedTotal ($paymentCode)',
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFFF9F43),
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (sheetCtx.mounted) Navigator.pop(sheetCtx);

    final isCash = paymentCode == 'Tunai';
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PaymentSuccessScreen(
          title: isCash ? 'Pesanan Makanan Berhasil!' : 'Pembayaran Berhasil!',
          receiverName: widget.merchant.name,
          receiverSub: widget.merchant.address,
          amountLabel: formattedTotal,
          amountCaption: isCash
              ? 'Total Tagihan (Bayar Tunai)'
              : 'Nominal Transaksi',
          isPaid: !isCash,
          paymentStatusNote: isCash
              ? 'Status: Belum Dibayar · Bayar tunai ke driver saat tiba'
              : null,
          details: [
            MapEntry('Pesanan', itemsSummary),
            MapEntry('Pengantaran', dest),
            MapEntry('Metode', paymentCode),
            MapEntry(
              'Status Pembayaran',
              isCash ? 'Belum Dibayar (Tunai)' : 'Lunas',
            ),
            if (paymentCode == 'GasPay' && remainingBalance != null)
              MapEntry(
                'Sisa saldo',
                'Rp ${WalletService.formatRupiah(remainingBalance)}',
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodOrderTrackingScreen(
          orderId: docId,
          merchantName: widget.merchant.name,
          merchantAddress: widget.merchant.address,
          destinationAddress: dest,
          itemsSummary: itemsSummary,
          totalLabel: formattedTotal,
          paymentMethod: paymentCode,
          initialPaymentStatus: isCash ? 'unpaid' : 'paid',
        ),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final card = isDark ? kCardDark : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);
    final border = isDark ? kBorderDark : kBorderLight;

    final menuCategories = [
      'Semua',
      ...{
        for (final m in widget.merchant.menus) m.category,
      },
    ];
    final filteredMenus = _selectedMenuCategory == 'Semua'
        ? widget.merchant.menus
        : widget.merchant.menus
            .where((m) => m.category == _selectedMenuCategory)
            .toList();

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                MerchantBannerView(
                  merchant: widget.merchant,
                  height: 210,
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 14,
                  child: Material(
                    color: card.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: tp,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informasi Toko & Alamat Lengkap
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                color: card,
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.merchant.name,
                          style: _body(tp, 20, FontWeight.bold),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.merchant.rating.toStringAsFixed(1),
                        style: _body(tp, 14, FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.merchant.category,
                    style: _body(kPrimaryDeep, 12.5, FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFFF9F43),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.merchant.address,
                              style: _body(tp, 13, FontWeight.w600, h: 1.35),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Jarak ${_distanceKm.toStringAsFixed(1)} km · Ongkir mulai ${MerchantService.formatRupiah(_deliveryFee)}',
                              style: _body(ts, 11.5, FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _showStoreMapModal(card, tp, ts, border),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryDeep,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text(
                          'Peta',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filter Kategori Menu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Menu (${widget.merchant.menus.length})',
                    style: _body(tp, 16, FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: menuCategories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = menuCategories[i];
                        final active = _selectedMenuCategory == c;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMenuCategory = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: active ? kPrimary : card,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: active ? kPrimary : border,
                              ),
                            ),
                            child: Text(
                              c,
                              style: _body(
                                active ? const Color(0xFF0A0F02) : tp,
                                11.5,
                                active ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List Menu
          if (filteredMenus.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    'Toko ini belum menambahkan daftar menu.',
                    style: _body(ts, 13.5, FontWeight.w500),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
              sliver: SliverList.separated(
                itemCount: filteredMenus.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filteredMenus[index];
                  final qty = _cartQty[item.id] ?? 0;
                  final canOrder = item.isAvailable && widget.merchant.isOpen;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: qty > 0 ? kPrimary : border,
                        width: qty > 0 ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 68,
                            height: 68,
                            child: MerchantImageRenderer(
                              imageData: item.imageData,
                              fallback: Container(
                                color: const Color(
                                  0xFFFF9F43,
                                ).withValues(alpha: 0.14),
                                child: const Icon(
                                  Icons.fastfood_rounded,
                                  color: Color(0xFFFF9F43),
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: _body(tp, 14.5, FontWeight.bold),
                              ),
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: _body(ts, 11.5, FontWeight.normal),
                                ),
                              ],
                              const SizedBox(height: 5),
                              Text(
                                MerchantService.formatRupiah(item.price),
                                style: _body(kPrimaryDeep, 13.5, FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!canOrder)
                          Text(
                            !widget.merchant.isOpen ? 'Tutup' : 'Habis',
                            style: _body(
                              Colors.redAccent,
                              11.5,
                              FontWeight.bold,
                            ),
                          )
                        else if (qty == 0)
                          ElevatedButton(
                            onPressed: () => _changeQty(item, 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: const Color(0xFF0A0F02),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              '+ Tambah',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _qtyBtn(
                                icon: Icons.remove_rounded,
                                onTap: () => _changeQty(item, -1),
                                tp: tp,
                                border: border,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  '$qty',
                                  style: _body(tp, 14, FontWeight.bold),
                                ),
                              ),
                              _qtyBtn(
                                icon: Icons.add_rounded,
                                onTap: () => _changeQty(item, 1),
                                tp: tp,
                                border: border,
                                filled: true,
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _totalQty == 0
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 14,
              ),
              decoration: BoxDecoration(
                color: card,
                border: Border(top: BorderSide(color: border)),
              ),
              child: ElevatedButton(
                onPressed: () =>
                    _openCheckoutSheet(isDark, card, tp, ts, border),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: const Color(0xFF0A0F02),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_totalQty Menu Dipilih',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pesan · ${MerchantService.formatRupiah(_foodSubtotal)}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color tp,
    required Color border,
    bool filled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? kPrimary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: filled ? kPrimary : border),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? const Color(0xFF0A0F02) : tp,
        ),
      ),
    );
  }
}
