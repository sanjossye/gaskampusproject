import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/admin_service.dart';
import '../../../services/fare_pricing_service.dart';
import 'package:gas_kampusapp/services/zone_service.dart';
import '../merchants/admin_merchant_management_screen.dart';

const Color kPrimary = Color(0xFF68CD5C);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

class AdminDriversScreen extends StatefulWidget {
  final int initialTab; // 0: Mahasiswa, 1: Driver Mahasiswa, 2: Driver Umum

  const AdminDriversScreen({super.key, this.initialTab = 1});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void didUpdateWidget(covariant AdminDriversScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _tabController.animateTo(widget.initialTab.clamp(0, 3));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSeedData() async {
    setState(() => _isSeeding = true);
    try {
      final count = await _adminService.seedSampleDriversIfEmpty();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Berhasil mengisi $count data pengguna (Mahasiswa & Driver) ke Firebase!'
                : 'Data pengguna sudah ada di Firebase.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengisi data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _toggleSuspendUser(UserModel user) async {
    final bool isCurrentlySuspended = !user.isActive;
    final String name = user.name;

    if (isCurrentlySuspended) {
      try {
        await _adminService.updateDriverActiveStatus(user.uid, true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Akun $name berhasil diaktifkan kembali.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Suspend Akun: $name'),
          content: Text(
            'Akun ini akan dibekukan di Firebase dan tidak dapat menggunakan layanan aplikasi.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _adminService.updateDriverActiveStatus(user.uid, false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Akun $name berhasil di-suspend.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Suspend'),
            ),
          ],
        ),
      );
    }
  }

  /// Modal detail akun & menampilkan foto identitas fisik (KTM / KTP)
  void _showUserDetailModal(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    final bool isStudent = user.role == 'mahasiswa';
    final bool isStudentDriver = user.role == 'driver_kampus';
    final bool isGeneralDriver = user.role == 'driver_umum';

    final String docTitle = isGeneralDriver ? 'Kartu Tanda Penduduk (KTP)' : 'Kartu Tanda Mahasiswa (KTM)';
    final String docSubtitle = isGeneralDriver
        ? 'NIK: ${user.nik ?? '-'}'
        : 'NIM: ${user.nim ?? '-'} • ${facultyDisplayName(user.facultas)}';

    final String docType = isGeneralDriver ? 'ktp' : 'ktm';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Top Bar Detail
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: kPrimary.withOpacity(0.2),
                          backgroundImage: (user.photoUrl != null && user.photoUrl!.startsWith('http'))
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: (user.photoUrl == null || !user.photoUrl!.startsWith('http'))
                              ? Text(user.name.isNotEmpty ? user.name[0] : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name,
                                style: TextStyle(
                                    color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              isStudent
                                  ? 'Mahasiswa (Customer)'
                                  : (isStudentDriver
                                      ? 'Driver Mahasiswa'
                                      : (user.role == 'merchant' ? 'Merchant Makanan' : 'Driver Umum')),
                              style: TextStyle(
                                color: isStudent
                                    ? Colors.blue
                                    : (isStudentDriver
                                        ? Colors.green
                                        : (user.role == 'merchant' ? Colors.deepOrange : Colors.amber.shade800)),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Scrollable Detail Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Informasi Utama Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.email_outlined, 'Email', user.email, textPrimary),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.phone_outlined, 'Telepon', user.phone ?? '-', textPrimary),
                          if (user.nim != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.badge_outlined, 'NIM', user.nim!, textPrimary),
                          ],
                          if (user.nik != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.badge_outlined, 'NIK', user.nik!, textPrimary),
                          ],
                          if (user.facultas != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.school_outlined, 'Fakultas', facultyDisplayName(user.facultas), textPrimary),
                          ],
                          if (user.vehiclePlate != null || user.vehicleBrand != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.two_wheeler_outlined,
                              'Kendaraan',
                              '${user.vehicleBrand ?? ''} • ${user.vehiclePlate ?? ''}',
                              textPrimary,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.check_circle_outline,
                            'Status Akun',
                            user.isActive ? 'Aktif' : 'Di-Suspend',
                            user.isActive ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section: Foto Identitas Fisik (KTM / KTP)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Foto Dokumen Identitas',
                            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isGeneralDriver ? 'KTP' : 'KTM Kampus',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Card Tampilan Foto Identitas (KTM / KTP)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isGeneralDriver ? Icons.credit_card_rounded : Icons.school_rounded,
                                size: 18,
                                color: kPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(docTitle,
                                  style: TextStyle(
                                      color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(docSubtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 14),

                          // Foto Preview (Membaca Base64 dari users/{uid}/documents/ktm atau URL ktmUrl)
                          _buildIdentityImageWidget(user, docType),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section: Penerapan Harga / Tarif Khusus Akun oleh Admin
                    _buildAccountFareCard(user, isDark, textPrimary),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(user.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                            size: 18, color: user.isActive ? Colors.red : Colors.green),
                        label: Text(user.isActive ? 'Suspend Akun' : 'Aktifkan Akun',
                            style: TextStyle(
                                color: user.isActive ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _toggleSuspendUser(user);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: user.isActive ? Colors.red : Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('Hubungi', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Menghubungi ${user.phone ?? user.email}...')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget untuk menampilkan foto identitas dengan prioritas:
  /// 1. Subkoleksi `users/{uid}/documents/{docType}` (base64) jika ktmStorage == 'firestore'
  /// 2. Field `ktmUrl` / `ktpUrl` jika tersimpan di Firebase Storage
  /// 3. Fallback placeholder jika belum mengunggah
  Widget _buildIdentityImageWidget(UserModel user, String docType) {
    return FutureBuilder<Uint8List?>(
      future: _adminService.getUserDocumentBase64(user.uid, docType),
      builder: (context, snapshot) {
        // Jika ada data base64 di subkoleksi documents
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        // Jika ada URL di ktmUrl atau ktpUrl
        final fallbackUrl = (docType == 'ktp' ? user.ktpUrl : user.ktmUrl);
        if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                fallbackUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderPhoto('Gagal memuat foto'),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        // Tampilan placeholder jika dokumen belum diunggah
        return _buildPlaceholderPhoto('Foto dokumen fisik belum diunggah');
      },
    );
  }

  Widget _buildPlaceholderPhoto(String message) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.document_scanner_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountFareCard(UserModel user, bool isDark, Color textPrimary) {
    final fareCtrl = TextEditingController(
      text: FarePricingService.pricePerKm.toString(),
    );

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final customFare = (data['customFarePerKm'] as num?)?.toInt();
        final activeRate = (customFare != null && customFare > 0)
            ? customFare
            : FarePricingService.pricePerKm;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kPrimary.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.price_change_rounded, color: kPrimary, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Penerapan Harga / Tarif Akun (1 Km)',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                customFare != null && customFare > 0
                    ? 'Tarif Khusus Akun Aktif: ${FarePricingService.formatRupiah(customFare)} / 1 km'
                    : 'Mengikuti Tarif Standar Admin: ${FarePricingService.formatRupiah(activeRate)} / 1 km',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: fareCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          prefixText: '1 Km = Rp ',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.black26 : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final val = int.tryParse(fareCtrl.text.trim());
                      if (val == null || val <= 0) return;
                      await FarePricingService.setAccountCustomFare(user.uid, val);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Harga ${FarePricingService.formatRupiah(val)}/km berhasil diterapkan ke akun ${user.name}!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (customFare != null && customFare > 0) ...[
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () async {
                        await FarePricingService.setAccountCustomFare(user.uid, null);
                      },
                      child: const Text('Reset', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final cardBg = isDark ? const Color(0xFF1A1F0C) : Colors.white;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: _adminService.getAllUsersStream(),
          builder: (context, snapshot) {
            final List<UserModel> allUsers = snapshot.data ?? [];
            final bool isLoading = snapshot.connectionState == ConnectionState.waiting && allUsers.isEmpty;

            final mahasiswaList = allUsers.where((u) => u.role == 'mahasiswa').toList();
            final driverMhsList = allUsers.where((u) => u.role == 'driver_kampus').toList();
            final driverUmumList = allUsers.where((u) => u.role == 'driver_umum').toList();
            final merchantList = allUsers.where((u) => u.role == 'merchant').toList();

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Manajemen Pengguna',
                                    style: TextStyle(
                                      color: textColorPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Live',
                                      style: TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kelola mahasiswa, driver kampus, dan umum',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Isi Data Contoh ke Firebase',
                        onPressed: _isSeeding ? null : _handleSeedData,
                        icon: _isSeeding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.cloud_upload_outlined, color: kPrimary),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: textColorPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Cari nama, NIM, NIK, atau fakultas...',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // TabBar (Mahasiswa | Driver Mhs | Driver Umum)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141908) : const Color(0xFFE9ECEF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicator: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: const Color(0xFF0F172A),
                    unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(
                        height: 36,
                        child: Text('Mahasiswa (${mahasiswaList.length})'),
                      ),
                      Tab(
                        height: 36,
                        child: Text('Driver Mhs (${driverMhsList.length})'),
                      ),
                      Tab(
                        height: 36,
                        child: Text('Driver Umum (${driverUmumList.length})'),
                      ),
                      Tab(
                        height: 36,
                        child: Text('Merchant (${merchantList.length})'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Tab Content
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : allUsers.isEmpty
                          ? _buildEmptyStateWithSeedButton(textColorPrimary)
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildUserList(mahasiswaList, 'mahasiswa', cardBg, borderColor, textColorPrimary),
                                _buildUserList(driverMhsList, 'driver_kampus', cardBg, borderColor, textColorPrimary),
                                _buildUserList(driverUmumList, 'driver_umum', cardBg, borderColor, textColorPrimary),
                                _buildUserList(merchantList, 'merchant', cardBg, borderColor, textColorPrimary),
                              ],
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserList(
    List<UserModel> users,
    String role,
    Color cardBg,
    Color borderColor,
    Color textColorPrimary,
  ) {
    final filtered = users.where((u) {
      final matchesSearch = u.name.toLowerCase().contains(_searchQuery) ||
          (u.nim != null && u.nim!.contains(_searchQuery)) ||
          (u.nik != null && u.nik!.contains(_searchQuery)) ||
          (u.facultas != null &&
              (u.facultas!.toLowerCase().contains(_searchQuery) ||
                  facultyDisplayName(u.facultas).toLowerCase().contains(_searchQuery)));
      return matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 54, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text('Tidak ada data pada kategori ini', style: const TextStyle(color: Colors.grey)),
            if (role == 'merchant') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_business_rounded, size: 18),
                label: const Text('Buka Manajemen & Pendaftaran Merchant'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminMerchantManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];
        final bool isActive = user.isActive;
        final bool isDriver = user.role == 'driver_kampus' || user.role == 'driver_umum';

        return InkWell(
          onTap: () => _showUserDetailModal(user),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: !isActive ? Colors.red.withOpacity(0.4) : borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: kPrimary.withOpacity(0.2),
                          backgroundImage: (user.photoUrl != null && user.photoUrl!.startsWith('http'))
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: (user.photoUrl == null || !user.photoUrl!.startsWith('http'))
                              ? Text(user.name.isNotEmpty ? user.name[0] : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.nim != null
                                ? '${user.nim} • ${facultyDisplayName(user.facultas)}'
                                : (user.nik != null ? 'NIK: ${user.nik}' : user.email),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.role == 'mahasiswa'
                                ? Colors.blue.withValues(alpha: 0.12)
                                : (user.role == 'driver_kampus'
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : (user.role == 'merchant'
                                        ? Colors.orange.withValues(alpha: 0.14)
                                        : Colors.amber.withValues(alpha: 0.12))),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.role == 'mahasiswa'
                                ? 'Mahasiswa'
                                : (user.role == 'driver_kampus'
                                    ? 'Driver Mhs'
                                    : (user.role == 'merchant' ? 'Merchant' : 'Driver Umum')),
                            style: TextStyle(
                              color: user.role == 'mahasiswa'
                                  ? Colors.blue.shade700
                                  : (user.role == 'driver_kampus'
                                      ? Colors.green.shade700
                                      : (user.role == 'merchant'
                                          ? Colors.deepOrange
                                          : Colors.amber.shade900)),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Info Tambahan Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isDriver) ...[
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${user.rating}',
                              style: TextStyle(
                                  color: textColorPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(' (${user.totalTrips} Trip)',
                              style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      Text(
                        user.vehiclePlate != null ? '${user.vehiclePlate}' : 'Lihat Detail',
                        style: TextStyle(
                            color: textColorPrimary.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ] else ...[
                      Text(
                        'Total Order: ${user.totalTrips}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 14, color: kPrimary),
                          const SizedBox(width: 4),
                          Text(
                            user.ktmStorage == 'firestore' ? 'KTM (Tersedia)' : 'Cek KTM',
                            style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateWithSeedButton(Color textColorPrimary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Pengguna di Firestore',
              style: TextStyle(color: textColorPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Koleksi `users` di Firebase Console masih kosong. Tekan tombol di bawah untuk membuat data awal Mahasiswa & Driver.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSeeding ? null : _handleSeedData,
              icon: _isSeeding
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded),
              label: const Text('Isi Data Contoh ke Firebase', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
