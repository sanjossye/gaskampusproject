import 'package:flutter/material.dart';
import '../../../models/merchant_model.dart';
import '../../../services/admin_merchant_service.dart';
import '../../../services/merchant_service.dart';

const Color kPrimary = Color(0xFF68CD5C);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

class AdminMerchantManagementScreen extends StatefulWidget {
  const AdminMerchantManagementScreen({super.key});

  @override
  State<AdminMerchantManagementScreen> createState() =>
      _AdminMerchantManagementScreenState();
}

class _AdminMerchantManagementScreenState
    extends State<AdminMerchantManagementScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  final List<String> _categories = [
    'Semua',
    'Ayam & Nasi',
    'Mie & Bakso',
    'Kopi & Minuman',
    'Snack & Bakery',
    'Aneka Masakan',
  ];

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ayam & Nasi':
        return const Color(0xFFFF9F43);
      case 'Mie & Bakso':
        return const Color(0xFFFF5252);
      case 'Kopi & Minuman':
        return const Color(0xFF54A0FF);
      case 'Snack & Bakery':
        return const Color(0xFFA55EEA);
      default:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ayam & Nasi':
        return Icons.lunch_dining_rounded;
      case 'Mie & Bakso':
        return Icons.ramen_dining_rounded;
      case 'Kopi & Minuman':
        return Icons.local_cafe_rounded;
      case 'Snack & Bakery':
        return Icons.bakery_dining_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  // ── 1. MODAL TAMBAH TITIK KANTIN OLEH ADMIN (UNCLAIMED LISTING) ───────────
  void _showAddStoreModal() {
    final storeNameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final ownerNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    String selectedCategory = kMerchantCategories.first;
    String selectedTheme = 'orange';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgCard = isDark ? const Color(0xFF161A0E) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;
            final textSec = isDark ? Colors.white70 : Colors.black54;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header Modal
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_location_alt_rounded,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tambah Titik Kantin Kampus',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                'Petakan lokasi kantin (siap diklaim pemiliknya)',
                                style: TextStyle(
                                  color: textSec,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: textColor,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Petunjuk
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline,
                                    color: Colors.amber, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Admin hanya menandai lokasi kantin & jenis jualannya. Akun login dan daftar menu akan dilengkapi oleh pemilik kantin saat proses klaim / ambil alih toko.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.amber[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nama Toko / Kantin
                          TextField(
                            controller: storeNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nama Kantin / Toko*',
                              hintText: 'Misal: Kantin Fasilkom Bu Siti',
                              prefixIcon: const Icon(Icons.storefront_rounded),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Kategori Kantin
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Kategori / Jual Apa?*',
                              prefixIcon: Icon(
                                _getCategoryIcon(selectedCategory),
                                color: _getCategoryColor(selectedCategory),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                            ),
                            items: kMerchantCategories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(
                                        cat,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedCategory = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Alamat Lokasi di Kampus
                          TextField(
                            controller: addressCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Lokasi di Area Kampus / Alamat*',
                              hintText:
                                  'Misal: Kantin Gedung B Lt. 1 Fasilkom USU',
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Nama Pemilik (Opsional)
                          TextField(
                            controller: ownerNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nama Pemilik / Pengelola (Opsional)',
                              hintText: 'Misal: Ibu Siti (Boleh dikosongkan)',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Nomor WhatsApp / HP (Opsional)
                          TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'No WhatsApp / HP (Opsional)',
                              hintText: 'Misal: 081200008801',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tema Tampilan Banner Toko
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedTheme,
                            decoration: InputDecoration(
                              labelText: 'Warna Tema Banner',
                              prefixIcon:
                                  const Icon(Icons.color_lens_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                            ),
                            items: kMerchantBannerThemes
                                .map((t) => DropdownMenuItem(
                                      value: t.key,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                  colors: t.gradient),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              t.label,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedTheme = val);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Tombol Aksi Simpan
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgCard,
                        border: Border(
                          top: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: isLoading
                              ? const SizedBox.shrink()
                              : const Icon(Icons.check_circle_rounded, size: 20),
                          label: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'Simpan Titik Kantin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final storeName = storeNameCtrl.text.trim();
                                  final address = addressCtrl.text.trim();
                                  final ownerName = ownerNameCtrl.text.trim();
                                  final phone = phoneCtrl.text.trim();

                                  if (storeName.isEmpty || address.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Nama Kantin dan Alamat lokasi wajib diisi.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isLoading = true);

                                  final res = await AdminMerchantService
                                      .addStoreListingByAdmin(
                                    storeName: storeName,
                                    category: selectedCategory,
                                    address: address,
                                    ownerName: ownerName,
                                    phone: phone,
                                    bannerTheme: selectedTheme,
                                  );

                                  setModalState(() => isLoading = false);

                                  if (res['success'] == true) {
                                    if (!context.mounted) return;
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Titik kantin "$storeName" berhasil ditambahkan dan siap diklaim!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['error'] ??
                                            'Gagal menambahkan titik kantin.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
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

  // ── 2. MODAL EDIT TOKO OLEH ADMIN ──────────────────────────────────────────
  void _showEditMerchantModal(MerchantModel merchant) {
    final nameCtrl = TextEditingController(text: merchant.name);
    final ownerCtrl = TextEditingController(text: merchant.ownerName);
    final phoneCtrl = TextEditingController(text: merchant.phone);
    final addressCtrl = TextEditingController(text: merchant.address);
    final headlineCtrl =
        TextEditingController(text: merchant.bannerHeadline);

    String category = merchant.category;
    String theme = merchant.bannerTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgCard = isDark ? const Color(0xFF161A0E) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note_rounded,
                            color: Colors.green, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Edit Data Titik Kantin',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nama Kantin',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: category,
                            decoration: InputDecoration(
                              labelText: 'Kategori / Jual Apa?',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                            ),
                            items: kMerchantCategories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => category = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: addressCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Alamat Lokasi Kampus',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: ownerCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nama Pemilik',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: phoneCtrl,
                            decoration: InputDecoration(
                              labelText: 'No WhatsApp / HP',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: headlineCtrl,
                            decoration: InputDecoration(
                              labelText: 'Slogan Banner Promo',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(ctx);
                            await AdminMerchantService.updateMerchant(
                              merchantId: merchant.id,
                              name: nameCtrl.text,
                              ownerName: ownerCtrl.text,
                              phone: phoneCtrl.text,
                              category: category,
                              address: addressCtrl.text,
                              bannerHeadline: headlineCtrl.text,
                              bannerTheme: theme,
                            );
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Data kantin berhasil diubah.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: const Text('Simpan Perubahan',
                              style: TextStyle(fontWeight: FontWeight.bold)),
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

  // ── 3. KONFIRMASI HAPUS TOKO ───────────────────────────────────────────────
  void _confirmDeleteMerchant(MerchantModel merchant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Titik Toko ${merchant.name}?'),
        content: Text(
          'Titik kantin "${merchant.name}" akan dihapus dari peta dan tidak akan muncul di aplikasi Mahasiswa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await AdminMerchantService.deleteMerchant(merchant.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Titik kantin "${merchant.name}" berhasil dihapus.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Hapus Toko'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final cardBg = isDark ? const Color(0xFF161A0E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelola Merchant & Kantin',
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Pemetaan Titik Kantin Kampus',
              style: TextStyle(color: textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.black87,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
              label: const Text(
                'Tambah Titik',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: _showAddStoreModal,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<MerchantModel>>(
        stream: AdminMerchantService.streamAllMerchants(),
        builder: (context, snapshot) {
          final merchants = snapshot.data ?? [];
          final totalStores = merchants.length;
          final unclaimedStores = merchants.where((m) => !m.isClaimed || m.ownerUid == 'unclaimed').length;
          final claimedStores = totalStores - unclaimedStores;

          // Filter berdasarkan search query dan kategori
          final filteredMerchants = merchants.where((m) {
            final matchesCat = _selectedCategory == 'Semua' ||
                m.category.toLowerCase() == _selectedCategory.toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                m.ownerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                m.address.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesCat && matchesSearch;
          }).toList();

          return CustomScrollView(
            slivers: [
              // 1. Stats Bar Ringkas
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        title: 'Total Kantin',
                        count: '$totalStores',
                        color: Colors.blue,
                        icon: Icons.store_rounded,
                        cardBg: cardBg,
                        border: borderColor,
                        textPrimary: textPrimary,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        title: 'Siap Diklaim',
                        count: '$unclaimedStores',
                        color: Colors.amber,
                        icon: Icons.pending_actions_rounded,
                        cardBg: cardBg,
                        border: borderColor,
                        textPrimary: textPrimary,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        title: 'Sudah Diklaim',
                        count: '$claimedStores',
                        color: Colors.green,
                        icon: Icons.verified_rounded,
                        cardBg: cardBg,
                        border: borderColor,
                        textPrimary: textPrimary,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Search Field
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari nama kantin atau lokasi...',
                      hintStyle:
                          TextStyle(color: textSecondary, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: textSecondary, size: 20),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ),

              // 3. Category Filter Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.black
                                  : textPrimary,
                            ),
                          ),
                          backgroundColor: cardBg,
                          selectedColor: kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                            side: BorderSide(
                              color: isSelected ? kPrimary : borderColor,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 4. List Merchant Cards
              filteredMerchants.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 56,
                                color: textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada titik kantin terdaftar',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Klik "Tambah Titik" untuk menandai kantin kampus.',
                              style: TextStyle(
                                  color: textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                              label: const Text('Tandai Kantin Sekarang'),
                              onPressed: _showAddStoreModal,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final merchant = filteredMerchants[index];
                            return _buildMerchantCard(
                              merchant: merchant,
                              cardBg: cardBg,
                              border: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isDark: isDark,
                            );
                          },
                          childCount: filteredMerchants.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
    required Color cardBg,
    required Color border,
    required Color textPrimary,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantCard({
    required MerchantModel merchant,
    required Color cardBg,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final themeStyle = merchantBannerThemeFor(merchant.bannerTheme);
    final catColor = _getCategoryColor(merchant.category);
    final bool isUnclaimed = !merchant.isClaimed || merchant.ownerUid == 'unclaimed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnclaimed
              ? Colors.amber.withValues(alpha: 0.5)
              : border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Mini Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeStyle.gradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(themeStyle.watermarkIcon,
                        color: themeStyle.textColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      merchant.category,
                      style: TextStyle(
                        color: themeStyle.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isUnclaimed
                        ? Colors.amber.shade900
                        : Colors.green.shade700,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    isUnclaimed ? 'SIAP DIKLAIM' : 'TERVERIFIKASI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail Toko
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(merchant.category),
                        color: catColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                isUnclaimed
                                    ? Icons.info_outline
                                    : Icons.person_outline,
                                size: 13,
                                color: isUnclaimed ? Colors.amber : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  isUnclaimed
                                      ? 'Belum diklaim pemilik kantin'
                                      : 'Pemilik: ${merchant.ownerName}',
                                  style: TextStyle(
                                    color: isUnclaimed
                                        ? Colors.amber
                                        : textSecondary,
                                    fontSize: 11,
                                    fontWeight: isUnclaimed
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Alamat
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        merchant.address,
                        style: TextStyle(color: textSecondary, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 20),

                // Action Bar
                Row(
                  children: [
                    // Switch Buka / Tutup Toko
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: merchant.isOpen,
                            activeColor: kPrimary,
                            onChanged: (val) async {
                              await AdminMerchantService.toggleStoreOpen(
                                  merchant.id, val);
                            },
                          ),
                        ),
                        Text(
                          merchant.isOpen ? 'Buka' : 'Tutup',
                          style: TextStyle(
                            color: merchant.isOpen ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Edit Toko
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Data Titik Kantin',
                      color: Colors.blue,
                      onPressed: () => _showEditMerchantModal(merchant),
                    ),

                    // Hapus Toko
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18),
                      tooltip: 'Hapus Titik Kantin',
                      color: Colors.red,
                      onPressed: () => _confirmDeleteMerchant(merchant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
