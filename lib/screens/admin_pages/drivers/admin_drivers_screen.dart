import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  final List<String> _categories = ['Semua', 'Mahasiswa', 'Umum', 'Online', 'Suspend'];

  final List<Map<String, dynamic>> _drivers = [
    {
      'id': 'DRV-101',
      'name': 'Dimas Anggara',
      'role': 'Driver Mahasiswa',
      'faculty': 'Fakultas Ilmu Komputer',
      'phone': '0812-3344-5566',
      'plate': 'B 4120 KLP',
      'vehicle': 'Honda Vario 125',
      'rating': 4.9,
      'trips': 342,
      'isOnline': true,
      'isSuspended': false,
      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
    },
    {
      'id': 'DRV-102',
      'name': 'Agus Prabowo',
      'role': 'Driver Umum',
      'faculty': '-',
      'phone': '0857-1122-3344',
      'plate': 'B 5590 XZZ',
      'vehicle': 'Yamaha Jupiter Z',
      'rating': 4.7,
      'trips': 512,
      'isOnline': true,
      'isSuspended': false,
      'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
    },
    {
      'id': 'DRV-103',
      'name': 'Rian Hidayat',
      'role': 'Driver Mahasiswa',
      'faculty': 'Fakultas Teknik Mesin',
      'phone': '0813-9900-1122',
      'plate': 'B 6678 TYU',
      'vehicle': 'Honda Beat Street',
      'rating': 4.8,
      'trips': 198,
      'isOnline': false,
      'isSuspended': false,
      'avatar': 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=200',
    },
    {
      'id': 'DRV-104',
      'name': 'Samsul Arifin',
      'role': 'Driver Umum',
      'faculty': '-',
      'phone': '0822-4455-8899',
      'plate': 'B 3012 WQA',
      'vehicle': 'Honda Supra X',
      'rating': 3.4,
      'trips': 85,
      'isOnline': false,
      'isSuspended': true,
      'suspendReason': 'Menerima 3 laporan tarif tidak sesuai sistem.',
      'avatar': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
    },
    {
      'id': 'DRV-105',
      'name': 'Kevin Sanjaya',
      'role': 'Driver Mahasiswa',
      'faculty': 'Fakultas Kedokteran Gigi',
      'phone': '0878-5566-7788',
      'plate': 'B 2291 POQ',
      'vehicle': 'Vespa Primavera',
      'rating': 5.0,
      'trips': 415,
      'isOnline': true,
      'isSuspended': false,
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    },
  ];

  void _toggleSuspendDriver(Map<String, dynamic> driver) {
    final bool currentSuspended = driver['isSuspended'] ?? false;
    final String name = driver['name'];

    if (currentSuspended) {
      // Unsuspend
      setState(() {
        driver['isSuspended'] = false;
        driver.remove('suspendReason');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun $name berhasil diaktifkan kembali.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Show confirmation dialog to suspend
      showDialog(
        context: context,
        builder: (ctx) {
          final TextEditingController reasonCtrl = TextEditingController(text: 'Pelanggaran ketentuan operasional kampus');
          return AlertDialog(
            title: Text('Suspend Driver: $name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Driver ini tidak akan bisa menerima orderan selama dibekukan.', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alasan Suspend',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () {
                  setState(() {
                    driver['isSuspended'] = true;
                    driver['isOnline'] = false;
                    driver['suspendReason'] = reasonCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Akun $name telah di-suspend.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Suspend'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final cardBg = isDark ? const Color(0xFF1A1F0C) : Colors.white;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    final onlineCount = _drivers.where((d) => d['isOnline'] == true && d['isSuspended'] == false).length;
    final suspendedCount = _drivers.where((d) => d['isSuspended'] == true).length;

    // Filter
    final filteredDrivers = _drivers.where((d) {
      final matchesSearch = d['name'].toString().toLowerCase().contains(_searchQuery) ||
          d['plate'].toString().toLowerCase().contains(_searchQuery) ||
          d['faculty'].toString().toLowerCase().contains(_searchQuery);

      if (!matchesSearch) return false;

      switch (_selectedCategory) {
        case 'Mahasiswa':
          return d['role'] == 'Driver Mahasiswa';
        case 'Umum':
          return d['role'] == 'Driver Umum';
        case 'Online':
          return d['isOnline'] == true && d['isSuspended'] == false;
        case 'Suspend':
          return d['isSuspended'] == true;
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
                      Text('Manajemen Driver', style: TextStyle(color: textColorPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Kelola driver mahasiswa dan driver umum', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 6),
                        Text('$onlineCount Online', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Mini Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildMiniStat('Total Driver', '${_drivers.length}', Icons.groups_rounded, Colors.blue, cardBg, borderColor, textColorPrimary),
                  const SizedBox(width: 12),
                  _buildMiniStat('Driver Aktif', '$onlineCount', Icons.electric_moped_rounded, kPrimary, cardBg, borderColor, textColorPrimary),
                  const SizedBox(width: 12),
                  _buildMiniStat('Di-Suspend', '$suspendedCount', Icons.block_rounded, Colors.red, cardBg, borderColor, textColorPrimary),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
                          hintText: 'Cari nama, plat motor, atau fakultas...',
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

            // Category Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: kPrimary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : textColorPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: isSelected ? kPrimary : borderColor),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Driver List
            Expanded(
              child: filteredDrivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 54, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          const Text('Tidak ada driver ditemukan', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      itemCount: filteredDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = filteredDrivers[index];
                        final bool isOnline = driver['isOnline'];
                        final bool isSuspended = driver['isSuspended'];
                        final bool isStudent = driver['role'] == 'Driver Mahasiswa';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSuspended ? Colors.red.withOpacity(0.4) : borderColor,
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
                                        backgroundImage: NetworkImage(driver['avatar']),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: isSuspended
                                                ? Colors.red
                                                : (isOnline ? Colors.green : Colors.grey),
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
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                driver['name'],
                                                style: TextStyle(
                                                  color: textColorPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            if (isStudent)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('Mhs', style: TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isStudent ? driver['faculty'] : 'Mitra Luar Kampus',
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Suspend/Menu Button
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                                    onSelected: (val) {
                                      if (val == 'suspend') {
                                        _toggleSuspendDriver(driver);
                                      } else if (val == 'call') {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Menghubungi ${driver['phone']}...')),
                                        );
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'call',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone, size: 18),
                                            const SizedBox(width: 8),
                                            Text('Telepon (${driver['phone']})', style: const TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'suspend',
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSuspended ? Icons.check_circle_outline : Icons.block_outlined,
                                              size: 18,
                                              color: isSuspended ? Colors.green : Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isSuspended ? 'Aktifkan Akun' : 'Suspend Driver',
                                              style: TextStyle(
                                                color: isSuspended ? Colors.green : Colors.red,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Metrics Info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text('${driver['rating']}', style: TextStyle(color: textColorPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text(' (${driver['trips']} Trip)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                  Text(
                                    '${driver['vehicle']} • ${driver['plate']}',
                                    style: TextStyle(color: textColorPrimary.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),

                              if (isSuspended && driver['suspendReason'] != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Alasan: ${driver['suspendReason']}',
                                          style: const TextStyle(color: Colors.red, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
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

  Widget _buildMiniStat(String label, String value, IconData icon, Color color, Color cardBg, Color border, Color textPrimary) {
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
