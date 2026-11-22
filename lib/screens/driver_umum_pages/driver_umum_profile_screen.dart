import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/document_service.dart';
import '../wallet_screen.dart';
import '../notifications_screen.dart';
import '../login_screen.dart';

const Color kPrimary = Color(0xFFC0F637);

class DriverUmumProfileScreen extends StatefulWidget {
  final VoidCallback onBack;

  const DriverUmumProfileScreen({super.key, required this.onBack});

  @override
  State<DriverUmumProfileScreen> createState() => _DriverUmumProfileScreenState();
}

class _DriverUmumProfileScreenState extends State<DriverUmumProfileScreen> {
  final DocumentService _docService = DocumentService();

  String _name = 'Agus Prabowo';
  String _phone = '+62 812-0000-0003';
  String _nik = '1271012345670001';
  String _vehiclePlate = 'BK 5678 UMM';
  String _vehicleBrand = 'Honda Beat';
  String _photoUrl = '';
  double _rating = 4.8;
  int _totalTrips = 512;
  int _walletBalance = 0;
  bool _isVerified = true;

  @override
  void initState() {
    super.initState();
    _listenToProfileData();
  }

  void _listenToProfileData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ensureKtpDocumentExists(user.uid);

      // Listen users/{uid}
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          final profile = (data['driverProfile'] as Map<String, dynamic>?) ?? {};
          setState(() {
            _name = data['name'] ?? _name;
            _phone = data['phone'] ?? _phone;
            _nik = data['nik'] ?? _nik;
            _photoUrl = (data['photoUrl'] ?? '').toString().trim();
            _vehiclePlate = data['vehiclePlate'] ?? profile['vehiclePlate'] ?? _vehiclePlate;
            _vehicleBrand = data['vehicleBrand'] ?? profile['vehicleBrand'] ?? _vehicleBrand;
            _rating = (data['rating'] as num?)?.toDouble() ?? (profile['rating'] as num?)?.toDouble() ?? _rating;
            _totalTrips = (data['totalTrips'] as num?)?.toInt() ?? (profile['totalTrips'] as num?)?.toInt() ?? _totalTrips;
            _isVerified = data['isVerified'] ?? true;
          });
        }
      });

      // Listen wallets/{uid}
      FirebaseFirestore.instance.collection('wallets').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          setState(() {
            _walletBalance = (data['balance'] as num?)?.toInt() ?? _walletBalance;
          });
        }
      });
    }
  }

  Future<void> _ensureKtpDocumentExists(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('documents').doc('ktp');
      final doc = await docRef.get();
      if (!doc.exists) {
        await _docService.uploadKtpDriverUmum(
          uid: uid,
          nik: _nik,
          fileName: 'scaled_IMG_0226.jpg',
        );
      }
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1D2210) : Colors.white;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: widget.onBack,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.arrow_back, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Profil Driver Umum',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    // Profile Hero
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kPrimary.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1D2210) : Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: _photoUrl.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            _photoUrl,
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Center(
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 58,
                                                color: kPrimary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.person_rounded,
                                            size: 58,
                                            color: kPrimary,
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1D2210) : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _name,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (_isVerified) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'TIER 3 · MITRA DRIVER UMUM',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'NIK: $_nik · $_vehiclePlate',
                            style: TextStyle(
                              color: textMutedColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Trips',
                              value: '$_totalTrips',
                              isDark: isDark,
                              textColor: textColor,
                              textMutedColor: textMutedColor,
                              cardBg: cardBg,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Rating',
                              value: _rating.toStringAsFixed(1),
                              icon: Icons.star,
                              iconColor: Colors.orange,
                              isDark: isDark,
                              textColor: textColor,
                              textMutedColor: textMutedColor,
                              cardBg: cardBg,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'GasPay',
                              value: 'Rp ${_formatNumber(_walletBalance)}',
                              isDark: isDark,
                              textColor: kPrimary,
                              textMutedColor: textMutedColor,
                              cardBg: cardBg,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Menu List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'VERIFIKASI & DOKUMEN',
                              style: TextStyle(
                                color: textMutedColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          // Menu Dokumen KTP Driver Umum
                          _buildMenuItem(
                            icon: Icons.badge_outlined,
                            title: 'Dokumen Resmi Driver Umum',
                            subtitle: 'KTP, SIM C & STNK (users/{uid}/documents/ktp)',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                            onTap: () => _showKtpModal(context, isDark, textColor, textMutedColor, cardBg, borderColor),
                          ),

                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'MENU UTAMA',
                              style: TextStyle(
                                color: textMutedColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          _buildMenuItem(
                            icon: Icons.edit_outlined,
                            title: 'Edit Data Profil Driver',
                            subtitle: 'Nama, No. HP, Plat & Motor',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                            onTap: () => _showEditProfileModal(context, isDark, textColor, textMutedColor, cardBg, borderColor),
                          ),
                          _buildMenuItem(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Dompet & Pendapatan GasPay',
                            subtitle: 'Cek saldo dan mutasi bagi hasil',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => WalletScreen(onBack: () => Navigator.pop(context))),
                              );
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.notifications_none_outlined,
                            title: 'Notifikasi & Pengumuman',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                              );
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.local_police_outlined,
                            title: 'Pusat Keamanan & Kontak Satpam',
                            subtitle: 'Pos Satpam USU Medan 061-8211633',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                            onTap: () => _showSafetyModal(context),
                          ),

                          const SizedBox(height: 24),

                          // Tombol Logout
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                              label: const Text(
                                'Keluar dari Akun Driver',
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    IconData? icon,
    Color? iconColor,
    required bool isDark,
    required Color textColor,
    required Color textMutedColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(color: textMutedColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 4),
                  Icon(icon, color: iconColor, size: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    required Color textColor,
    required Color textMutedColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: textMutedColor, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textMutedColor, size: 20),
          ],
        ),
      ),
    );
  }

  /// Modal Dokumen KTP Driver Umum (Sesuai Skema Firestore: users/{uid}/documents/ktp)
  void _showKtpModal(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color textMutedColor,
    Color cardBg,
    Color borderColor,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'driveru_demo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _docService.streamKtpDocument(uid),
          builder: (context, snapshot) {
            final docData = snapshot.data?.data() ?? {};
            final fileName = docData['fileName'] ?? 'scaled_IMG_0226.jpg';
            final uploadedAt = docData['uploadedAt'] ?? DateTime.now().toIso8601String();
            final nikStored = docData['nik'] ?? _nik;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Dokumen Resmi Driver Umum',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Khusus Mitra Driver Umum menggunakan KTP (Path: users/$uid/documents/ktp)',
                      style: TextStyle(color: textMutedColor, fontSize: 12),
                    ),
                    const SizedBox(height: 20),

                    // KTP Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kPrimary.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: const [
                                    Icon(Icons.badge, color: Color(0xFF68CD5C), size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Kartu Tanda Penduduk (KTP)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '✓ Terverifikasi',
                                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('NIK: $nikStored', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('File: $fileName (Base64 JPEG)', style: TextStyle(color: textMutedColor, fontSize: 11)),
                          Text('Waktu Upload: $uploadedAt', style: TextStyle(color: textMutedColor, fontSize: 11)),
                          const SizedBox(height: 12),

                          // KTP Image Box
                          Container(
                            height: 110,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                              child: const Text('KTP Driver Umum', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await _docService.uploadKtpDriverUmum(
                                    uid: user.uid,
                                    nik: _nik,
                                    fileName: 'scaled_IMG_0226.jpg',
                                  );
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('KTP berhasil diperbarui ke Firestore users/{uid}/documents/ktp!'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: const Text('Perbarui / Upload Ulang KTP', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SIM C Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.drive_eta, color: kPrimary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SIM C (Surat Izin Mengemudi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('users/$uid/documents/sim', style: TextStyle(color: textMutedColor, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileModal(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color textMutedColor,
    Color cardBg,
    Color borderColor,
  ) {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    final plateCtrl = TextEditingController(text: _vehiclePlate);
    final brandCtrl = TextEditingController(text: _vehicleBrand);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profil Driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Nomor WhatsApp / HP', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: plateCtrl,
                      decoration: const InputDecoration(labelText: 'Nomor Plat Motor', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: brandCtrl,
                      decoration: const InputDecoration(labelText: 'Merk Motor', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'vehiclePlate': plateCtrl.text.trim(),
                        'vehicleBrand': brandCtrl.text.trim(),
                        'updatedAt': DateTime.now().toIso8601String(),
                      });
                      setState(() {
                        _name = nameCtrl.text.trim();
                        _phone = phoneCtrl.text.trim();
                        _vehiclePlate = plateCtrl.text.trim();
                        _vehicleBrand = brandCtrl.text.trim();
                      });
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSafetyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.shield, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Keamanan & Kontak Satpam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Kontak Darurat Resmi Kampus USU Medan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 6),
            Text('• Pos Satpam Pusat USU: 061-8211633', style: TextStyle(fontSize: 13)),
            Text('• PKD Fakultas Teknik USU: 061-8212090', style: TextStyle(fontSize: 13)),
            Text('• Hotline GasKampus 24 Jam: 0812-9988-7766', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}
