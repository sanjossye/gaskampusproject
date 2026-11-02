import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

class DriverVerificationScreen extends StatefulWidget {
  final int initialTab; // 0: Mahasiswa, 1: Umum

  const DriverVerificationScreen({super.key, this.initialTab = 0});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  // Dummy data Driver Mahasiswa
  final List<Map<String, dynamic>> _mahasiswaApplicants = [
    {
      'id': 'VM-01',
      'name': 'Fajar Ramadhan',
      'nim': '2205356012',
      'faculty': 'Fakultas Teknik (Informatika)',
      'phone': '0812-3456-7890',
      'vehicle': 'Honda Beat 2022 (Hitam)',
      'plate': 'B 3821 SDE',
      'registeredDate': 'Hari ini, 09:15',
      'ktm': 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
      'sim': 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=400',
      'stnk': 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
      'status': 'pending', // pending, approved, rejected
    },
    {
      'id': 'VM-02',
      'name': 'Annisa Putri',
      'nim': '2108102045',
      'faculty': 'Fakultas Ekonomi & Bisnis (Manajemen)',
      'phone': '0857-9912-3344',
      'vehicle': 'Yamaha Fazzio 2023 (Cyan)',
      'plate': 'B 4192 KLY',
      'registeredDate': 'Hari ini, 08:30',
      'ktm': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      'sim': 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=400',
      'stnk': 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
      'status': 'pending',
    },
    {
      'id': 'VM-03',
      'name': 'Rizky Kurniawan',
      'nim': '2301103019',
      'faculty': 'Fakultas MIPA (Statistika)',
      'phone': '0821-4455-6677',
      'vehicle': 'Honda Vario 160 (Putih)',
      'plate': 'B 6620 PQR',
      'registeredDate': 'Kemarin, 16:45',
      'ktm': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'sim': 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=400',
      'stnk': 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
      'status': 'pending',
    },
    {
      'id': 'VM-04',
      'name': 'Bagus Wicaksono',
      'nim': '2204101088',
      'faculty': 'Fakultas Hukum',
      'phone': '0813-8899-1122',
      'vehicle': 'Yamaha NMAX (Abu-abu)',
      'plate': 'B 5512 TUV',
      'registeredDate': 'Kemarin, 14:10',
      'ktm': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      'sim': 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=400',
      'stnk': 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
      'status': 'pending',
    },
  ];

  // Dummy data Driver Umum
  final List<Map<String, dynamic>> _umumApplicants = [
    {
      'id': 'VU-01',
      'name': 'Hendro Susanto',
      'nik': '3171092801850003',
      'phone': '0812-9988-7711',
      'vehicle': 'Honda Scoopy 2021 (Merah)',
      'plate': 'B 3019 ERT',
      'registeredDate': 'Hari ini, 07:50',
      'ktp': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
      'sim': 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=400',
      'stnk': 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
      'status': 'pending',
    },
    {
      'id': 'VU-02',
      'name': 'Bambang Irawan',
      'nik': '3172081504900002',
      'phone': '0856-7788-9900',
      'vehicle': 'Yamaha Mio M3 (Hitam)',
      'plate': 'B 4821 WXY',
      'registeredDate': 'Kemarin, 19:20',
      'ktp': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
      'sim': 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=400',
      'stnk': 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
      'status': 'pending',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleApproval(Map<String, dynamic> applicant, bool approve) {
    setState(() {
      applicant['status'] = approve ? 'approved' : 'rejected';
    });

    final name = applicant['name'];
    final action = approve ? 'disetujui' : 'ditolak';
    final color = approve ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pendaftaran $name berhasil $action.'),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDocumentDetail(Map<String, dynamic> applicant, bool isMahasiswa) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
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

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicant['name'],
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isMahasiswa
                              ? 'NIM: ${applicant['nim']} • ${applicant['faculty']}'
                              : 'NIK: ${applicant['nik']}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
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

              // Content Document Preview
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDocSection(
                      title: isMahasiswa ? 'Kartu Tanda Mahasiswa (KTM)' : 'KTP',
                      imageUrl: isMahasiswa ? applicant['ktm'] : applicant['ktp'],
                      subtitle: isMahasiswa
                          ? 'Validasi keaktifan mahasiswa di kampus'
                          : 'Validasi identitas kependudukan',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    _buildDocSection(
                      title: 'Surat Izin Mengemudi (SIM C)',
                      imageUrl: applicant['sim'],
                      subtitle: 'SIM aktif untuk kendaraan roda dua',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    _buildDocSection(
                      title: 'Surat Tanda Nomor Kendaraan (STNK)',
                      imageUrl: applicant['stnk'],
                      subtitle: 'Plat: ${applicant['plate']} (${applicant['vehicle']})',
                      isDark: isDark,
                    ),
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
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleApproval(applicant, false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tolak Pendaftaran', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleApproval(applicant, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Setujui & Verifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildDocSection({
    required String title,
    required String imageUrl,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Icon(Icons.verified_user_outlined, size: 18, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.withOpacity(0.2),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColorPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verifikasi Driver',
          style: TextStyle(color: textColorPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1405) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Mahasiswa (${_mahasiswaApplicants.where((a) => a['status'] == 'pending').length})'),
                Tab(text: 'Umum (${_umumApplicants.where((a) => a['status'] == 'pending').length})'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: textColorPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama, NIM, atau nomor plat...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApplicantList(_mahasiswaApplicants, isMahasiswa: true, isDark: isDark, cardBg: cardBg, borderColor: borderColor, textPrimary: textColorPrimary),
                _buildApplicantList(_umumApplicants, isMahasiswa: false, isDark: isDark, cardBg: cardBg, borderColor: borderColor, textPrimary: textColorPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantList(
    List<Map<String, dynamic>> applicants, {
    required bool isMahasiswa,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
  }) {
    final filtered = applicants.where((a) {
      final matchesSearch = a['name'].toString().toLowerCase().contains(_searchQuery) ||
          (isMahasiswa ? a['nim'].toString().contains(_searchQuery) : a['nik'].toString().contains(_searchQuery)) ||
          a['plate'].toString().toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('Tidak ada pendaftaran driver baru', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final isPending = item['status'] == 'pending';
        final isApproved = item['status'] == 'approved';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPending
                  ? borderColor
                  : (isApproved ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: kPrimary.withOpacity(0.2),
                        child: Text(
                          item['name'][0],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            item['registeredDate'],
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusChip(item['status']),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Detail info
              _buildInfoRow(
                Icons.badge_outlined,
                isMahasiswa ? 'NIM' : 'NIK',
                isMahasiswa ? item['nim'] : item['nik'],
                textPrimary,
              ),
              if (isMahasiswa) ...[
                const SizedBox(height: 6),
                _buildInfoRow(Icons.school_outlined, 'Fakultas', item['faculty'], textPrimary),
              ],
              const SizedBox(height: 6),
              _buildInfoRow(Icons.phone_outlined, 'Telepon', item['phone'], textPrimary),
              const SizedBox(height: 6),
              _buildInfoRow(
                Icons.two_wheeler_outlined,
                'Kendaraan',
                '${item['vehicle']} • ${item['plate']}',
                textPrimary,
              ),

              const SizedBox(height: 16),

              // Action buttons
              if (isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text('Cek Berkas', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showDocumentDetail(item, isMahasiswa),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                      onPressed: () => _handleApproval(item, false),
                      tooltip: 'Tolak',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check_rounded, color: Colors.green),
                      onPressed: () => _handleApproval(item, true),
                      tooltip: 'Setujui',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isApproved ? '✓ Telah Disetujui' : '✕ Telah Ditolak',
                    style: TextStyle(
                      color: isApproved ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'approved':
        bg = Colors.green.withOpacity(0.15);
        text = Colors.green;
        label = 'Disetujui';
        break;
      case 'rejected':
        bg = Colors.red.withOpacity(0.15);
        text = Colors.red;
        label = 'Ditolak';
        break;
      default:
        bg = Colors.orange.withOpacity(0.15);
        text = Colors.orange;
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
