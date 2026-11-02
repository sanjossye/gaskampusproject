import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedFilter = 'Semua';
  String _searchQuery = '';

  final List<String> _filters = ['Semua', 'Perlu Tindakan', 'Investigasi', 'Selesai'];

  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'REP-501',
      'user': 'Rania Zahra (Mahasiswa)',
      'userPhone': '0812-8899-7766',
      'driver': 'Samsul Arifin (Driver Umum)',
      'orderId': 'GK-9750',
      'category': 'Tarif Tidak Sesuai',
      'categoryColor': Colors.red,
      'title': 'Driver minta tambahan tunai di luar aplikasi',
      'description': 'Driver meminta uang tambahan Rp 5.000 dengan alasan macet di pintu masuk utama, padahal pembayaran sudah lunas via GasPay.',
      'status': 'pending', // pending, investigating, resolved
      'statusLabel': 'Perlu Tindakan',
      'date': 'Hari ini, 10:20',
    },
    {
      'id': 'REP-502',
      'user': 'Fahri Alamsyah (Mahasiswa)',
      'userPhone': '0857-4433-2211',
      'driver': 'Dimas Anggara (Driver Mahasiswa)',
      'orderId': 'GK-9721',
      'category': 'Barang Tertinggal',
      'categoryColor': Colors.blue,
      'title': 'Flashdisk dan buku catatan tertinggal di helm/box',
      'description': 'Saya baru sadar buku catatan kuliah dan flashdisk tertinggal setelah turun di Gedung Rektorat. Mohon bantu hubungkan driver.',
      'status': 'investigating',
      'statusLabel': 'Investigasi',
      'date': 'Hari ini, 08:45',
    },
    {
      'id': 'REP-503',
      'user': 'Taufik Hidayat (Driver Mahasiswa)',
      'userPhone': '0813-1122-3344',
      'driver': 'Penumpang Tidak Muncul',
      'orderId': 'GK-9699',
      'category': 'Penolakan / No Show',
      'categoryColor': Colors.orange,
      'title': 'Penumpang tidak merespon di titik jemput > 15 mnt',
      'description': 'Saya sudah menunggu di Halte Asrama sesuai titik penjemputan, chat dan telepon tidak dijawab sampai 15 menit.',
      'status': 'resolved',
      'statusLabel': 'Selesai',
      'date': 'Kemarin, 17:30',
    },
    {
      'id': 'REP-504',
      'user': 'Citra Kirana (Mahasiswa)',
      'userPhone': '0821-6677-8899',
      'driver': 'Agus Prabowo (Driver Umum)',
      'orderId': 'GK-9650',
      'category': 'Keamanan Berkendara',
      'categoryColor': Colors.red,
      'title': 'Driver ngebut dan tidak menyediakan helm standar',
      'description': 'Helm yang diberikan tali penguncinya rusak, dan driver melaju terlalu kencang di area zona lambat kampus.',
      'status': 'pending',
      'statusLabel': 'Perlu Tindakan',
      'date': 'Kemarin, 14:15',
    },
  ];

  void _showReportDetailModal(Map<String, dynamic> report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(report['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (report['categoryColor'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report['category'],
                      style: TextStyle(color: report['categoryColor'] as Color, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(report['title'], style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Waktu: ${report['date']} • Order: ${report['orderId']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              Text('Pelapor: ${report['user']}', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              Text('No. Telp: ${report['userPhone']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Text('Pihak Terkait: ${report['driver']}', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),

              const SizedBox(height: 14),
              const Text('Isi Laporan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(report['description'], style: TextStyle(color: textPrimary, fontSize: 13, height: 1.4)),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          report['status'] = 'investigating';
                          report['statusLabel'] = 'Investigasi';
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Laporan ${report['id']} dipindahkan ke status Investigasi.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tandai Investigasi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          report['status'] = 'resolved';
                          report['statusLabel'] = 'Selesai';
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Laporan ${report['id']} diselesaikan.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Selesaikan Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
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

    final filteredReports = _reports.where((r) {
      final matchesSearch = r['id'].toString().toLowerCase().contains(_searchQuery) ||
          r['user'].toString().toLowerCase().contains(_searchQuery) ||
          r['title'].toString().toLowerCase().contains(_searchQuery) ||
          r['orderId'].toString().toLowerCase().contains(_searchQuery);

      if (!matchesSearch) return false;

      switch (_selectedFilter) {
        case 'Perlu Tindakan':
          return r['status'] == 'pending';
        case 'Investigasi':
          return r['status'] == 'investigating';
        case 'Selesai':
          return r['status'] == 'resolved';
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Laporan & Pengaduan', style: TextStyle(color: textColorPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Tindak lanjuti komplain mahasiswa dan driver', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_reports.where((r) => r['status'] == 'pending').length} Baru',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                          hintText: 'Cari laporan ID, pemesan, kata kunci...',
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

            // Filter Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    selectedColor: filter == 'Perlu Tindakan' ? Colors.red : kPrimary,
                    labelStyle: TextStyle(
                      color: isSelected ? (filter == 'Perlu Tindakan' ? Colors.white : Colors.black) : textColorPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: isSelected ? Colors.transparent : borderColor),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Reports List
            Expanded(
              child: filteredReports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 54, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          const Text('Tidak ada laporan pada filter ini', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        final isPending = report['status'] == 'pending';

                        return InkWell(
                          onTap: () => _showReportDetailModal(report),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isPending ? Colors.red.withOpacity(0.3) : borderColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (report['categoryColor'] as Color).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        report['category'],
                                        style: TextStyle(color: report['categoryColor'] as Color, fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                    ),
                                    Text(report['date'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  report['title'],
                                  style: TextStyle(color: textColorPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  report['description'],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Pelapor: ${report['user'].split(' ')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    Row(
                                      children: [
                                        Text('Detail', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kPrimary),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
