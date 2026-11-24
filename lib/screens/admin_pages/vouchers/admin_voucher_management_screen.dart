import 'package:flutter/material.dart';
import '../../../models/voucher_model.dart';
import '../../../services/voucher_service.dart';

const Color kPrimary = Color(0xFF68CD5C);
const Color kPrimaryDeep = Color(0xFF8DBF1A);
const Color kBgDark = Color(0xFF1D2210);

/// Layar / Manajemen Voucher & Promo lengkap khusus Admin
class AdminVoucherManagementScreen extends StatefulWidget {
  const AdminVoucherManagementScreen({super.key});

  @override
  State<AdminVoucherManagementScreen> createState() =>
      _AdminVoucherManagementScreenState();
}

class _AdminVoucherManagementScreenState
    extends State<AdminVoucherManagementScreen> {
  String _selectedCategory = 'SEMUA';
  String _searchQuery = '';

  final List<String> _categories = [
    'SEMUA',
    'ANTAR',
    'MAKAN',
    'DOMPET',
    'TITIP',
    'EVENT',
  ];

  @override
  void initState() {
    super.initState();
    VoucherService.seedDefaultVouchersIfEmpty();
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toUpperCase()) {
      case 'ANTAR':
        return Icons.motorcycle_rounded;
      case 'MAKAN':
        return Icons.restaurant_rounded;
      case 'DOMPET':
        return Icons.account_balance_wallet_rounded;
      case 'TITIP':
        return Icons.shopping_bag_rounded;
      case 'EVENT':
        return Icons.event_available_rounded;
      default:
        return Icons.discount_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toUpperCase()) {
      case 'ANTAR':
        return const Color(0xFF68CD5C);
      case 'MAKAN':
        return const Color(0xFFFF9F43);
      case 'DOMPET':
        return const Color(0xFF54A0FF);
      case 'TITIP':
        return const Color(0xFFA55EEA);
      case 'EVENT':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.green;
    }
  }

  void _showAddOrEditVoucherModal([VoucherModel? existingVoucher]) {
    final isEdit = existingVoucher != null;
    final codeCtrl = TextEditingController(text: existingVoucher?.code ?? '');
    final titleCtrl = TextEditingController(text: existingVoucher?.title ?? '');
    final descCtrl =
        TextEditingController(text: existingVoucher?.description ?? '');
    final discountValCtrl = TextEditingController(
      text: existingVoucher != null
          ? existingVoucher.discountValue.toString()
          : '',
    );
    final minOrderCtrl = TextEditingController(
      text: existingVoucher != null
          ? existingVoucher.minOrder.toString()
          : '0',
    );
    final quotaCtrl = TextEditingController(
      text: existingVoucher != null ? existingVoucher.quota.toString() : '100',
    );
    final validUntilTextCtrl = TextEditingController(
      text: existingVoucher?.validUntilText ?? 'Hingga 31 Des 2026',
    );

    String category = existingVoucher?.category ?? 'ANTAR';
    String discountType = existingVoucher?.discountType ?? 'fixed';

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
              height: MediaQuery.of(context).size.height * 0.90,
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_note_rounded
                                : Icons.add_circle_outline_rounded,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit Voucher Promo' : 'Buat Voucher Promo Baru',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                'Terhubung realtime ke akun mahasiswa',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.black54,
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Live Preview Voucher (Sama persis tampilan di akun mahasiswa)
                          Text(
                            'LIVE PREVIEW DI APLIKASI MAHASISWA',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPreviewVoucherCard(
                            title: titleCtrl.text.isEmpty
                                ? 'Judul Promo Mahasiswa'
                                : titleCtrl.text,
                            desc: descCtrl.text.isEmpty
                                ? 'Deskripsi potongan promo kampus...'
                                : descCtrl.text,
                            code: codeCtrl.text.isEmpty
                                ? 'PROMO'
                                : codeCtrl.text.toUpperCase(),
                            category: category,
                            validText: validUntilTextCtrl.text.isEmpty
                                ? 'Hingga 31 Des 2026'
                                : validUntilTextCtrl.text,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),

                          // Form Inputs
                          TextField(
                            controller: codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Kode Voucher (Huruf Kapital)*',
                              hintText: 'Misal: DISKONKAMPUS, MABAGAS',
                              prefixIcon: const Icon(Icons.confirmation_number_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: titleCtrl,
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Judul Promo*',
                              hintText: 'Misal: Diskon Kuliah Pagi 50%',
                              prefixIcon: const Icon(Icons.title_rounded),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: descCtrl,
                            onChanged: (_) => setModalState(() {}),
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Deskripsi / Syarat & Ketentuan',
                              hintText: 'Min order Rp 10.000 untuk rute kampus...',
                              prefixIcon: const Icon(Icons.description_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Dropdown Kategori Layanan
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: category,
                            decoration: InputDecoration(
                              labelText: 'Kategori Layanan',
                              prefixIcon: Icon(_getCategoryIcon(category),
                                  color: _getCategoryColor(category)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'ANTAR',
                                  child: Text('ANTAR (Ojek / Mobil)',
                                      overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(
                                  value: 'MAKAN',
                                  child: Text('MAKAN (Kantin Kampus)',
                                      overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(
                                  value: 'DOMPET',
                                  child: Text('DOMPET (GasPay Topup)',
                                      overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(
                                  value: 'TITIP',
                                  child: Text('TITIP (Jastip ATK & Print)',
                                      overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(
                                  value: 'EVENT',
                                  child: Text('EVENT (Pekan Ujian / Wisuda)',
                                      overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => category = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // Tipe Diskon
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: discountType,
                                  decoration: InputDecoration(
                                    labelText: 'Tipe Diskon',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'fixed',
                                      child: Text('Nominal Tetap',
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem(
                                      value: 'percent',
                                      child: Text('Persentase (%)',
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => discountType = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 5,
                                child: TextField(
                                  controller: discountValCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: discountType == 'fixed'
                                        ? 'Nominal (Rp)*'
                                        : 'Persen (%)*',
                                    prefixText: discountType == 'fixed' ? 'Rp ' : null,
                                    suffixText: discountType == 'percent' ? '%' : null,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Minimal Belanja & Kuota
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minOrderCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Min. Belanja (Rp)',
                                    prefixText: 'Rp ',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: quotaCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Kuota Kupon',
                                    suffixText: 'User',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: validUntilTextCtrl,
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Label Masa Berlaku',
                              hintText: 'Misal: Hingga 31 Des 2026',
                              prefixIcon: const Icon(Icons.calendar_today_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 24),
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
                          onPressed: () async {
                            final code = codeCtrl.text.trim().toUpperCase();
                            final title = titleCtrl.text.trim();
                            final desc = descCtrl.text.trim();
                            final discountVal =
                                int.tryParse(discountValCtrl.text.trim()) ?? 0;
                            final minOrder =
                                int.tryParse(minOrderCtrl.text.trim()) ?? 0;
                            final quota =
                                int.tryParse(quotaCtrl.text.trim()) ?? 100;
                            final validUntilText =
                                validUntilTextCtrl.text.trim().isEmpty
                                    ? 'Hingga 31 Des 2026'
                                    : validUntilTextCtrl.text.trim();

                            if (code.isEmpty || title.isEmpty || discountVal <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Harap lengkapi kode, judul, dan nilai diskon.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(ctx);

                            try {
                              if (isEdit) {
                                final updated = existingVoucher.copyWith(
                                  code: code,
                                  title: title,
                                  description: desc,
                                  category: category,
                                  discountType: discountType,
                                  discountValue: discountVal,
                                  minOrder: minOrder,
                                  quota: quota,
                                  validUntilText: validUntilText,
                                );
                                await VoucherService.updateVoucher(updated);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Voucher $code berhasil diperbarui!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                final newVoucher = VoucherModel(
                                  id: '',
                                  code: code,
                                  title: title,
                                  description: desc,
                                  category: category,
                                  discountType: discountType,
                                  discountValue: discountVal,
                                  minOrder: minOrder,
                                  quota: quota,
                                  validUntilText: validUntilText,
                                  createdAt: DateTime.now(),
                                );
                                await VoucherService.createVoucher(newVoucher);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Voucher baru $code berhasil dipublikasikan ke Firestore!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan voucher: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.cloud_upload_rounded),
                          label: Text(
                            isEdit
                                ? 'Simpan Pembaruan Voucher'
                                : 'Publikasikan Voucher ke Mahasiswa',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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

  Widget _buildPreviewVoucherCard({
    required String title,
    required String desc,
    required String code,
    required String category,
    required String validText,
    required bool isDark,
  }) {
    final catColor = _getCategoryColor(category);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2612) : const Color(0xFFF6FAF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getCategoryIcon(category), color: catColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: catColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Kode: $code',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  validText,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'Pakai',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(VoucherModel voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Voucher ${voucher.code}?'),
        content: Text(
          'Voucher "${voucher.title}" akan dihapus permanen dari Firestore dan tidak bisa lagi dipakai oleh mahasiswa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await VoucherService.deleteVoucher(voucher.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Voucher ${voucher.code} telah dihapus.'),
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : const Color(0xFFF7F8F5);
    final cardBg = isDark ? const Color(0xFF1A1F0C) : Colors.white;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text(
          'Kelola Voucher & Promo',
          style: TextStyle(
            color: textColorPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah Voucher Baru',
            icon: const Icon(Icons.add_circle, color: kPrimary, size: 28),
            onPressed: () => _showAddOrEditVoucherModal(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Info Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: cardBg,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari kode promo, judul, kategori...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter kategori chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final isSel = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: kPrimary,
                        backgroundColor: isDark ? const Color(0xFF232A18) : const Color(0xFFE2E8F0),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : textColorPrimary,
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Stream Daftar Voucher dari Firestore
          Expanded(
            child: StreamBuilder<List<VoucherModel>>(
              stream: VoucherService.streamAllVouchers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allVouchers = snapshot.data ?? [];
                final filtered = allVouchers.where((v) {
                  final matchesCat = _selectedCategory == 'SEMUA' ||
                      v.category.toUpperCase() == _selectedCategory;
                  final matchesSearch = v.code.toLowerCase().contains(_searchQuery) ||
                      v.title.toLowerCase().contains(_searchQuery) ||
                      v.description.toLowerCase().contains(_searchQuery);
                  return matchesCat && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.discount_outlined,
                            size: 64, color: textColorSecondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada voucher promo',
                          style: TextStyle(
                            color: textColorPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Klik tombol + di atas untuk membuat voucher baru',
                          style: TextStyle(color: textColorSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final voucher = filtered[index];
                    final catColor = _getCategoryColor(voucher.category);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: voucher.isActive
                              ? borderColor
                              : Colors.red.withOpacity(0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(voucher.category),
                                    color: catColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: catColor.withOpacity(0.18),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              voucher.category,
                                              style: TextStyle(
                                                color: catColor,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Kode: ${voucher.code}',
                                            style: TextStyle(
                                              color: textColorSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          // Status Switch Aktif / Nonaktif
                                          Row(
                                            children: [
                                              Text(
                                                voucher.isActive ? 'Aktif' : 'Nonaktif',
                                                style: TextStyle(
                                                  color: voucher.isActive
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Transform.scale(
                                                scale: 0.75,
                                                child: Switch(
                                                  value: voucher.isActive,
                                                  activeColor: kPrimary,
                                                  onChanged: (val) {
                                                    VoucherService.toggleVoucherStatus(
                                                        voucher.id, val);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        voucher.title,
                                        style: TextStyle(
                                          color: textColorPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        voucher.description,
                                        style: TextStyle(
                                          color: textColorSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined,
                                              size: 11, color: textColorSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            voucher.validUntilText,
                                            style: TextStyle(
                                              color: textColorSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.people_outline_rounded,
                                              size: 12, color: textColorSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pakai: ${voucher.usedCount}/${voucher.quota}',
                                            style: TextStyle(
                                              color: textColorSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showAddOrEditVoucherModal(voucher),
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _confirmDelete(voucher),
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 16, color: Colors.red),
                                  label: const Text('Hapus',
                                      style: TextStyle(fontSize: 12, color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
}
