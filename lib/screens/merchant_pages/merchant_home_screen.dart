import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart' show themeNotifier;
import '../../models/merchant_model.dart';
import '../../services/auth_services.dart';
import '../../services/map_route_service.dart';
import '../../services/merchant_service.dart';
import '../login_screen.dart';

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

/// Halaman utama khusus akun **Merchant Toko Makanan**.
/// Memungkinkan pemilik warung/kantin mengatur banner, alamat, menu makanan,
/// dan memantau pesanan mahasiswa secara real-time.
class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  final MerchantService _merchantService = MerchantService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _navIndex = 0;
  int _orderTabIndex = 0;

  String _ownerName = 'Pemilik Toko';
  String _ownerEmail = '';
  String _ownerPhone = '';

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfoAndEnsureStore();
  }

  Future<void> _loadOwnerInfoAndEnsureStore() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data() ?? {};
        setState(() {
          _ownerName = (data['name'] ?? 'Pemilik Toko').toString();
          _ownerEmail = (data['email'] ?? '').toString();
          _ownerPhone = (data['phone'] ?? '').toString();
        });
      }

      final storeDoc = await _db.collection('merchants').doc(uid).get();
      if (!storeDoc.exists) {
        final now = DateTime.now();
        final data = userDoc.data() ?? {};
        final initialStore = MerchantModel(
          id: uid,
          ownerUid: uid,
          name: (data['storeName'] ?? 'Toko $_ownerName').toString(),
          ownerName: _ownerName,
          phone: _ownerPhone,
          category: (data['storeCategory'] ?? kMerchantCategories.first)
              .toString(),
          address: (data['storeAddress'] ?? 'Area Kampus USU, Medan')
              .toString(),
          bannerHeadline: 'Pesan makanan hangat langsung diantar ke kampus!',
          bannerTheme: 'lime',
          isOpen: true,
          createdAt: now,
          updatedAt: now,
          menus: const [],
        );
        await _merchantService.upsertMerchant(initialStore);
      }
    } catch (_) {}
  }

  MerchantModel _defaultFallbackStore() {
    final now = DateTime.now();
    return MerchantModel(
      id: _uid ?? 'merchant_local',
      ownerUid: _uid ?? 'merchant_local',
      name: 'Toko $_ownerName',
      ownerName: _ownerName,
      phone: _ownerPhone,
      address: 'Area Kampus USU, Medan',
      bannerHeadline: 'Pesan makanan hangat langsung ke kampus!',
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _handleLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun Merchant?'),
        content: const Text('Anda akan kembali ke halaman login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final card = isDark ? kCardDark : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);
    final border = isDark ? kBorderDark : kBorderLight;

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    final uid = _uid;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: uid == null
            ? Center(
                child: Text(
                  'Silakan login kembali.',
                  style: _body(tp, 14, FontWeight.w600),
                ),
              )
            : StreamBuilder<MerchantModel?>(
                stream: _merchantService.streamMerchantById(uid),
                builder: (context, storeSnap) {
                  final store = storeSnap.data ?? _defaultFallbackStore();
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _merchantService.streamMerchantOrders(uid),
                    builder: (context, orderSnap) {
                      final orders = orderSnap.data?.docs ?? const [];
                      return switch (_navIndex) {
                        0 => _buildStoreTab(
                          store: store,
                          orders: orders,
                          isDark: isDark,
                          card: card,
                          tp: tp,
                          ts: ts,
                          border: border,
                        ),
                        1 => _buildMenuTab(
                          store: store,
                          isDark: isDark,
                          card: card,
                          tp: tp,
                          ts: ts,
                          border: border,
                        ),
                        2 => _buildOrdersTab(
                          orders: orders,
                          isDark: isDark,
                          card: card,
                          tp: tp,
                          ts: ts,
                          border: border,
                        ),
                        _ => _buildProfileTab(
                          store: store,
                          isDark: isDark,
                          card: card,
                          tp: tp,
                          ts: ts,
                          border: border,
                        ),
                      };
                    },
                  );
                },
              ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark, border, tp, ts),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 0: DASHBOARD TOKO, ALAMAT & BANNER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStoreTab({
    required MerchantModel store,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
    required bool isDark,
    required Color card,
    required Color tp,
    required Color ts,
    required Color border,
  }) {
    final pendingCount = orders
        .where((d) => (d.data()['status'] ?? 'pending') == 'pending')
        .length;
    final availableMenus = store.menus.where((m) => m.isAvailable).length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF0A0F02),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MERCHANT MAKANAN',
                    style: _body(ts, 10.5, FontWeight.w800, ls: 0.8),
                  ),
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _body(tp, 17, FontWeight.bold),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  store.isOpen ? 'Buka' : 'Tutup',
                  style: _body(
                    store.isOpen ? const Color(0xFF16A34A) : ts,
                    12,
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Switch.adaptive(
                  value: store.isOpen,
                  activeTrackColor: kPrimary,
                  activeThumbColor: const Color(0xFF0A0F02),
                  onChanged: (v) => _merchantService.setStoreOpen(store.id, v),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Preview Banner seperti tampil di Mahasiswa
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tampilan Banner di Mahasiswa',
              style: _body(tp, 14.5, FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () =>
                  _showEditStoreDialog(store, isDark, card, tp, ts, border),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit Toko & Banner'),
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryDeep,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MerchantBannerView(merchant: store, height: 152),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: const Color(0xFFFF9F43),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            store.address,
                            style: _body(tp, 13, FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.menus.isEmpty
                          ? 'Belum ada menu. Tambahkan di tab Menu agar muncul di Mahasiswa.'
                          : 'Menu aktif ($availableMenus): ${store.menus.take(3).map((m) => m.name).join(' • ')}${store.menus.length > 3 ? ' +${store.menus.length - 3} lainnya' : ''}',
                      style: _body(ts, 12, FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Ringkasan Statistik
        Row(
          children: [
            Expanded(
              child: _statBox(
                label: 'Menu Tersedia',
                value: '$availableMenus / ${store.menus.length}',
                icon: Icons.restaurant_menu_rounded,
                accent: const Color(0xFFFF9F43),
                card: card,
                border: border,
                tp: tp,
                ts: ts,
                onTap: () => setState(() => _navIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statBox(
                label: 'Pesanan Baru',
                value: '$pendingCount',
                icon: Icons.receipt_long_rounded,
                accent: kPrimaryDeep,
                card: card,
                border: border,
                tp: tp,
                ts: ts,
                onTap: () => setState(() => _navIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Quick Actions
        Text('Kelola Toko Makanan', style: _body(tp, 14.5, FontWeight.bold)),
        const SizedBox(height: 10),
        _quickActionTile(
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFFFF9F43),
          title: 'Tambah Menu Makanan / Minuman',
          subtitle: 'Atur nama menu, harga, kategori, dan foto',
          card: card,
          border: border,
          tp: tp,
          ts: ts,
          onTap: () => _showMenuEditorDialog(
            store: store,
            isDark: isDark,
            card: card,
            tp: tp,
            ts: ts,
            border: border,
          ),
        ),
        const SizedBox(height: 10),
        _quickActionTile(
          icon: Icons.photo_library_outlined,
          color: kPrimaryDeep,
          title: 'Atur Alamat, Foto Banner & Promo',
          subtitle: 'Ubah lokasi warung dan banner yang dilihat mahasiswa',
          card: card,
          border: border,
          tp: tp,
          ts: ts,
          onTap: () =>
              _showEditStoreDialog(store, isDark, card, tp, ts, border),
        ),
      ],
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    required Color card,
    required Color border,
    required Color tp,
    required Color ts,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 10),
            Text(value, style: _body(tp, 20, FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: _body(ts, 11.5, FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color card,
    required Color border,
    required Color tp,
    required Color ts,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _body(tp, 14, FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _body(ts, 11.5, FontWeight.normal)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: ts),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: KELOLA MENU MAKANAN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMenuTab({
    required MerchantModel store,
    required bool isDark,
    required Color card,
    required Color tp,
    required Color ts,
    required Color border,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Menu Toko',
                      style: _body(tp, 19, FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${store.menus.length} menu tampil di halaman Makanan mahasiswa',
                      style: _body(ts, 12, FontWeight.w500),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showMenuEditorDialog(
                  store: store,
                  isDark: isDark,
                  card: card,
                  tp: tp,
                  ts: ts,
                  border: border,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: const Color(0xFF0A0F02),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Tambah',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Divider(color: border, height: 1),
        Expanded(
          child: store.menus.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 56,
                          color: ts.withValues(alpha: 0.45),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada menu makanan',
                          style: _body(tp, 16, FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tambahkan menu pertama Anda agar mahasiswa bisa melihat dan memesan makanan dari toko ini.',
                          textAlign: TextAlign.center,
                          style: _body(ts, 12.5, FontWeight.normal, h: 1.4),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () => _showMenuEditorDialog(
                            store: store,
                            isDark: isDark,
                            card: card,
                            tp: tp,
                            ts: ts,
                            border: border,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: const Color(0xFF0A0F02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Tambah Menu Pertama',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  itemCount: store.menus.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = store.menus[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 64,
                              height: 64,
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
                                const SizedBox(height: 2),
                                Text(
                                  '${item.category} · ${MerchantService.formatRupiah(item.price)}',
                                  style: _body(
                                    kPrimaryDeep,
                                    12.5,
                                    FontWeight.w700,
                                  ),
                                ),
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    item.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: _body(ts, 11.5, FontWeight.normal),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch.adaptive(
                                value: item.isAvailable,
                                activeTrackColor: kPrimary,
                                activeThumbColor: const Color(0xFF0A0F02),
                                onChanged: (val) async {
                                  final updated = List<MerchantMenuItem>.from(
                                    store.menus,
                                  );
                                  updated[index] = item.copyWith(
                                    isAvailable: val,
                                  );
                                  await _merchantService.updateMenus(
                                    store.id,
                                    updated,
                                  );
                                },
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: ts,
                                      size: 18,
                                    ),
                                    onPressed: () => _showMenuEditorDialog(
                                      store: store,
                                      existing: item,
                                      existingIndex: index,
                                      isDark: isDark,
                                      card: card,
                                      tp: tp,
                                      ts: ts,
                                      border: border,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      final updated =
                                          List<MerchantMenuItem>.from(
                                            store.menus,
                                          )..removeAt(index);
                                      await _merchantService.updateMenus(
                                        store.id,
                                        updated,
                                      );
                                    },
                                  ),
                                ],
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
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: PESANAN MASUK MAHASISWA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOrdersTab({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
    required bool isDark,
    required Color card,
    required Color tp,
    required Color ts,
    required Color border,
  }) {
    final sorted = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      orders,
    )..sort((a, b) {
        final da = DateTime.tryParse(a.data()['createdAt']?.toString() ?? '');
        final db = DateTime.tryParse(b.data()['createdAt']?.toString() ?? '');
        return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
      });

    final filtered = sorted.where((doc) {
      final st = (doc.data()['status'] ?? 'pending').toString();
      if (_orderTabIndex == 0) return st == 'pending';
      if (_orderTabIndex == 1) {
        return st == 'accepted' ||
            st == 'preparing' ||
            st == 'going_to_merchant' ||
            st == 'picked_up' ||
            st == 'onTrip';
      }
      return st == 'completed' || st == 'cancelled';
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
            children: [
              Text('Pesanan Masuk', style: _body(tp, 19, FontWeight.bold)),
            ],
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _orderTabIndex = i),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 12, top: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _orderTabIndex == i
                              ? kPrimary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      ['Baru', 'Diproses', 'Selesai'][i],
                      textAlign: TextAlign.center,
                      style: _body(
                        _orderTabIndex == i ? tp : ts,
                        13.5,
                        _orderTabIndex == i ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Divider(color: border, height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada pesanan di tab ini.',
                    style: _body(ts, 13.5, FontWeight.w500),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final status = (data['status'] ?? 'pending').toString();
                    final items = (data['items'] ?? '').toString();
                    final dest = (data['destinationAddress'] ?? '').toString();
                    final buyer = (data['passengerName'] ?? 'Mahasiswa')
                        .toString();
                    final note = (data['note'] ?? '').toString();
                    final fare = (data['fareAmount'] as num?)?.toInt() ?? 0;
                    final method = (data['paymentMethod'] ?? 'GasPay')
                        .toString();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: status == 'pending' ? kPrimary : border,
                          width: status == 'pending' ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  buyer,
                                  style: _body(tp, 15, FontWeight.bold),
                                ),
                              ),
                              Text(
                                MerchantService.formatRupiah(fare),
                                style: _body(
                                  kPrimaryDeep,
                                  14.5,
                                  FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(items, style: _body(tp, 13.5, FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            'Antar ke: $dest',
                            style: _body(ts, 12, FontWeight.w500),
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Catatan: $note',
                              style: _body(ts, 12, FontWeight.normal),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Pembayaran: $method (${(data['paymentStatus'] == 'unpaid' || (method.toLowerCase() == 'tunai' && data['paymentStatus'] != 'paid' && status != 'completed')) ? 'Belum Dibayar' : 'Lunas'}) · Status: ${_statusLabel(status)}',
                            style: _body(ts, 11.5, FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          if (status == 'pending')
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _merchantService
                                        .updateOrderStatus(doc.id, 'cancelled'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: const Text('Tolak'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _merchantService
                                        .updateOrderStatus(doc.id, 'accepted'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: const Color(0xFF0A0F02),
                                      elevation: 0,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: const Text(
                                      'Terima & Masak',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else if (status == 'accepted' ||
                              status == 'preparing' ||
                              status == 'going_to_merchant')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (status == 'going_to_merchant')
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Driver sedang menuju toko untuk mengambil makanan.',
                                      style: _body(
                                        kPrimaryDeep,
                                        12,
                                        FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ElevatedButton.icon(
                                  onPressed: () => _merchantService
                                      .markFoodPickedUpByDriver(doc.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: const Color(0xFF0A0F02),
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                  ),
                                  icon: const Icon(
                                    Icons.inventory_2_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Makanan Telah Diambil Driver',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else if (status == 'picked_up')
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFFFF9F43),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Makanan telah diambil driver · menunggu pengantaran.',
                                    style: _body(ts, 12.5, FontWeight.w600),
                                  ),
                                ),
                              ],
                            )
                          else if (status == 'onTrip')
                            Row(
                              children: [
                                const Icon(
                                  Icons.two_wheeler_rounded,
                                  color: kPrimaryDeep,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Sedang diantar ke pemesan (driver akan centang Saya Sudah Sampai).',
                                    style: _body(ts, 12, FontWeight.w600),
                                  ),
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
    );
  }

  String _statusLabel(String s) {
    return switch (s) {
      'pending' => 'Menunggu Konfirmasi',
      'accepted' || 'preparing' => 'Sedang Disiapkan',
      'going_to_merchant' => 'Driver Menuju Merchant',
      'picked_up' => 'Makanan Telah Diambil Driver',
      'onTrip' => 'Sedang Diantar ke Pemesan',
      'completed' => 'Selesai (Sudah Sampai)',
      'cancelled' => 'Dibatalkan',
      _ => s,
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3: PROFIL TOKO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileTab({
    required MerchantModel store,
    required bool isDark,
    required Color card,
    required Color tp,
    required Color ts,
    required Color border,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: kPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF0A0F02),
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          store.name,
          textAlign: TextAlign.center,
          style: _body(tp, 19, FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '$_ownerName · ${store.category}',
          textAlign: TextAlign.center,
          style: _body(ts, 13, FontWeight.w500),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoLine('Alamat Toko', store.address, tp, ts),
              const SizedBox(height: 12),
              _infoLine(
                'WhatsApp',
                _ownerPhone.isEmpty ? '-' : _ownerPhone,
                tp,
                ts,
              ),
              const SizedBox(height: 12),
              _infoLine(
                'Email',
                _ownerEmail.isEmpty ? '-' : _ownerEmail,
                tp,
                ts,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mode Gelap', style: _body(tp, 14, FontWeight.w600)),
              Switch.adaptive(
                value: isDark,
                activeTrackColor: kPrimary,
                activeThumbColor: const Color(0xFF0A0F02),
                onChanged: (v) {
                  themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Keluar Akun',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoLine(String label, String val, Color tp, Color ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _body(ts, 11, FontWeight.w600)),
        const SizedBox(height: 2),
        Text(val, style: _body(tp, 13.5, FontWeight.w600)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODAL EDIT TOKO, ALAMAT & BANNER
  // ══════════════════════════════════════════════════════════════════════════
  void _showEditStoreDialog(
    MerchantModel store,
    bool isDark,
    Color card,
    Color tp,
    Color ts,
    Color border,
  ) {
    final nameCtrl = TextEditingController(text: store.name);
    final addrCtrl = TextEditingController(text: store.address);
    final headlineCtrl = TextEditingController(text: store.bannerHeadline);
    final bannerUrlCtrl = TextEditingController(
      text: store.bannerData.startsWith('http') ? store.bannerData : '',
    );

    String category = kMerchantCategories.contains(store.category)
        ? store.category
        : kMerchantCategories.first;
    String bannerTheme = store.bannerTheme;
    String bannerData = store.bannerData;
    double lat = store.latitude;
    double lng = store.longitude;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            final previewMerchant = store.copyWith(
              name: nameCtrl.text.trim().isEmpty
                  ? store.name
                  : nameCtrl.text.trim(),
              category: category,
              address: addrCtrl.text.trim().isEmpty
                  ? store.address
                  : addrCtrl.text.trim(),
              bannerHeadline: headlineCtrl.text.trim(),
              bannerTheme: bannerTheme,
              bannerData: bannerData,
            );

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.9,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                    'Edit Toko, Alamat & Banner',
                    style: _body(tp, 18, FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  MerchantBannerView(
                    merchant: previewMerchant,
                    height: 132,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  const SizedBox(height: 14),
                  _dialogInput(
                    label: 'Nama Toko Makanan',
                    controller: nameCtrl,
                    tp: tp,
                    ts: ts,
                    border: border,
                    onChanged: (_) => setSheet(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kategori Toko',
                    style: _body(tp, 12.5, FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: card,
                    style: _body(tp, 13.5, FontWeight.w600),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: kMerchantCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => category = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Alamat Lengkap Toko',
                        style: _body(tp, 12.5, FontWeight.w700),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final gps =
                              await MapRouteService.getCurrentDriverPosition(
                                campusFallback:
                                    MapRouteService.defaultKampusCenter,
                              );
                          final addr =
                              await MapRouteService.reverseGeocodePosition(
                                gps.position,
                              );
                          if (!sheetCtx.mounted) return;
                          setSheet(() {
                            lat = gps.position.latitude;
                            lng = gps.position.longitude;
                            addrCtrl.text = addr;
                          });
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: kPrimaryDeep,
                        ),
                        icon: const Icon(Icons.my_location_rounded, size: 15),
                        label: const Text(
                          'Deteksi GPS',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: addrCtrl,
                    maxLines: 2,
                    style: _body(tp, 13.5, FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Kantin Pusat USU Lt. 1, Medan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dialogInput(
                    label: 'Teks / Promo di Banner',
                    controller: headlineCtrl,
                    tp: tp,
                    ts: ts,
                    border: border,
                    onChanged: (_) => setSheet(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tema Warna Banner',
                    style: _body(tp, 12.5, FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: kMerchantBannerThemes.map((t) {
                        final selected = bannerTheme == t.key;
                        return GestureDetector(
                          onTap: () => setSheet(() => bannerTheme = t.key),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: t.gradient),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: selected ? tp : Colors.transparent,
                                width: 2.2,
                              ),
                            ),
                            child: Text(
                              t.label,
                              style: TextStyle(
                                color: t.textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Foto Banner Toko (Opsional)',
                    style: _body(tp, 12.5, FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 60,
                              maxWidth: 960,
                            );
                            if (picked == null) return;
                            final bytes = await picked.readAsBytes();
                            if (bytes.length > 500 * 1024) {
                              if (sheetCtx.mounted) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ukuran gambar terlalu besar (maks 500 KB).',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            final uri = MerchantService.bytesToDataUri(
                              bytes,
                              picked.name,
                            );
                            setSheet(() {
                              bannerData = uri;
                              bannerUrlCtrl.clear();
                            });
                          },
                          icon: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 18,
                          ),
                          label: const Text('Upload Foto'),
                        ),
                      ),
                      if (bannerData.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setSheet(() {
                            bannerData = '';
                            bannerUrlCtrl.clear();
                          }),
                          child: const Text(
                            'Hapus Foto',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bannerUrlCtrl,
                    style: _body(tp, 12.5, FontWeight.w500),
                    onChanged: (val) {
                      setSheet(() {
                        if (val.trim().startsWith('http')) {
                          bannerData = val.trim();
                        } else if (val.trim().isEmpty &&
                            bannerData.startsWith('http')) {
                          bannerData = '';
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Atau tempel URL gambar banner (https://...)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty ||
                                  addrCtrl.text.trim().isEmpty) {
                                return;
                              }
                              setSheet(() => saving = true);
                              final updated = store.copyWith(
                                name: nameCtrl.text.trim(),
                                category: category,
                                address: addrCtrl.text.trim(),
                                latitude: lat,
                                longitude: lng,
                                bannerHeadline: headlineCtrl.text.trim(),
                                bannerTheme: bannerTheme,
                                bannerData: bannerData,
                                updatedAt: DateTime.now(),
                              );
                              await _merchantService.upsertMerchant(updated);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: const Color(0xFF0A0F02),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text(
                              'Simpan Perubahan Toko',
                              style: TextStyle(fontWeight: FontWeight.bold),
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

  // ══════════════════════════════════════════════════════════════════════════
  // MODAL TAMBAH / EDIT MENU MAKANAN
  // ══════════════════════════════════════════════════════════════════════════
  void _showMenuEditorDialog({
    required MerchantModel store,
    MerchantMenuItem? existing,
    int? existingIndex,
    required bool isDark,
    required Color card,
    required Color tp,
    required Color ts,
    required Color border,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? '${existing.price}' : '',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final urlCtrl = TextEditingController(
      text: (existing != null && existing.imageData.startsWith('http'))
          ? existing.imageData
          : '',
    );

    String cat = (existing != null && kMenuCategories.contains(existing.category))
        ? existing.category
        : kMenuCategories.first;
    String imageData = existing?.imageData ?? '';
    bool isAvailable = existing?.isAvailable ?? true;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                    existing == null ? 'Tambah Menu Baru' : 'Edit Menu',
                    style: _body(tp, 18, FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _dialogInput(
                    label: 'Nama Menu Makanan / Minuman',
                    controller: nameCtrl,
                    tp: tp,
                    ts: ts,
                    border: border,
                  ),
                  const SizedBox(height: 12),
                  _dialogInput(
                    label: 'Harga (Rp)',
                    controller: priceCtrl,
                    tp: tp,
                    ts: ts,
                    border: border,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Text('Kategori Menu', style: _body(tp, 12.5, FontWeight.w700)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: cat,
                    dropdownColor: card,
                    style: _body(tp, 13.5, FontWeight.w600),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: kMenuCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => cat = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  _dialogInput(
                    label: 'Deskripsi Singkat (Opsional)',
                    controller: descCtrl,
                    tp: tp,
                    ts: ts,
                    border: border,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menu Tersedia untuk Dipesan',
                        style: _body(tp, 13, FontWeight.w600),
                      ),
                      Switch.adaptive(
                        value: isAvailable,
                        activeTrackColor: kPrimary,
                        activeThumbColor: const Color(0xFF0A0F02),
                        onChanged: (v) => setSheet(() => isAvailable = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (imageData.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: MerchantImageRenderer(
                              imageData: imageData,
                              fallback: const Icon(Icons.fastfood_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 55,
                              maxWidth: 640,
                            );
                            if (picked == null) return;
                            final bytes = await picked.readAsBytes();
                            if (bytes.length > 350 * 1024) {
                              if (sheetCtx.mounted) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ukuran foto menu maksimal 350 KB.',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            setSheet(() {
                              imageData = MerchantService.bytesToDataUri(
                                bytes,
                                picked.name,
                              );
                              urlCtrl.clear();
                            });
                          },
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('Foto Menu'),
                        ),
                      ),
                      if (imageData.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setSheet(() {
                            imageData = '';
                            urlCtrl.clear();
                          }),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: urlCtrl,
                    style: _body(tp, 12.5, FontWeight.w500),
                    onChanged: (val) {
                      setSheet(() {
                        if (val.trim().startsWith('http')) {
                          imageData = val.trim();
                        } else if (val.trim().isEmpty &&
                            imageData.startsWith('http')) {
                          imageData = '';
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Atau tempel URL foto menu (https://...)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final price =
                                  int.tryParse(priceCtrl.text.trim()) ?? 0;
                              if (name.isEmpty || price <= 0) return;

                              setSheet(() => saving = true);
                              final newItem = MerchantMenuItem(
                                id:
                                    existing?.id ??
                                    'menu_${DateTime.now().millisecondsSinceEpoch}',
                                name: name,
                                description: descCtrl.text.trim(),
                                price: price,
                                category: cat,
                                imageData: imageData,
                                isAvailable: isAvailable,
                              );
                              final updated = List<MerchantMenuItem>.from(
                                store.menus,
                              );
                              if (existingIndex != null &&
                                  existingIndex >= 0 &&
                                  existingIndex < updated.length) {
                                updated[existingIndex] = newItem;
                              } else {
                                updated.add(newItem);
                              }
                              await _merchantService.updateMenus(
                                store.id,
                                updated,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: const Color(0xFF0A0F02),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Simpan Menu',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _dialogInput({
    required String label,
    required TextEditingController controller,
    required Color tp,
    required Color ts,
    required Color border,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _body(tp, 12.5, FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: _body(tp, 13.5, FontWeight.w500),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(bool isDark, Color border, Color tp, Color ts) {
    const items = [
      (Icons.storefront_rounded, 'Toko'),
      (Icons.restaurant_menu_rounded, 'Menu'),
      (Icons.receipt_long_rounded, 'Pesanan'),
      (Icons.person_rounded, 'Profil'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? kCardDark : Colors.white,
        border: Border(top: BorderSide(color: border)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = _navIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _navIndex = i),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].$1,
                      size: 22,
                      color: active ? kPrimaryDeep : ts,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].$2,
                      style: _body(
                        active ? tp : ts,
                        11,
                        active ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
