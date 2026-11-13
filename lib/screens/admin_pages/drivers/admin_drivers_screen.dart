import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/admin_service.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen> {
  final AdminService _adminService = AdminService();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isSeeding = false;

  final List<String> _categories = ['Semua', 'Mahasiswa', 'Umum', 'Aktif', 'Suspend'];

  Future<void> _handleSeedData() async {
    setState(() => _isSeeding = true);
    try {
      final count = await _adminService.seedSampleDriversIfEmpty();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Berhasil menambahkan $count data driver ke Firebase Console!'
                : 'Data driver sudah ada di Firebase.'),
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

  Future<void> _toggleSuspendDriver(UserModel driver) async {
    final bool isCurrentlySuspended = !driver.isActive;
    final String name = driver.name;

    if (isCurrentlySuspended) {
      // Aktifkan kembali
      try {
        await _adminService.updateDriverActiveStatus(driver.uid, true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Akun $name berhasil diaktifkan kembali di Firestore.'),
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
      // Tampilkan dialog suspend
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Suspend Driver: $name'),
            content: const Text(
              'Driver ini akan dinonaktifkan di Firebase dan tidak dapat menerima order perjalanan.',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _adminService.updateDriverActiveStatus(driver.uid, false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Akun $name berhasil di-suspend di Firestore.'),
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: _adminService.getDriversStream(),
          builder: (context, snapshot) {
            final List<UserModel> allDrivers = snapshot.data ?? [];
            final bool isLoading = snapshot.connectionState == ConnectionState.waiting && allDrivers.isEmpty;

            final onlineCount = allDrivers.where((d) => d.isActive).length;
            final suspendedCount = allDrivers.where((d) => !d.isActive).length;

            // Filter logic
            final filteredDrivers = allDrivers.where((d) {
              final matchesSearch = d.name.toLowerCase().contains(_searchQuery) ||
                  (d.nim != null && d.nim!.contains(_searchQuery)) ||
                  (d.facultas != null && d.facultas!.toLowerCase().contains(_searchQuery));

              if (!matchesSearch) return false;

              switch (_selectedCategory) {
                case 'Mahasiswa':
                  return d.role == 'driver_kampus';
                case 'Umum':
                  return d.role == 'driver_umum';
                case 'Aktif':
                  return d.isActive;
                case 'Suspend':
                  return !d.isActive;
                default:
                  return true;
              }
            }).toList();

            return Column(
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
                          Row(
                            children: [
                              Text('Manajemen Driver',
                                  style: TextStyle(
                                      color: textColorPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Firestore Live',
                                    style: TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Tersambung ke koleksi `users` di Firebase',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
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
                            : Icon(Icons.cloud_upload_rounded, color: kPrimary),
                      ),
                    ],
                  ),
                ),

                // Mini Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      _buildMiniStat('Total Driver', '${allDrivers.length}', Icons.groups_rounded, Colors.blue,
                          cardBg, borderColor, textColorPrimary),
                      const SizedBox(width: 12),
                      _buildMiniStat('Driver Aktif', '$onlineCount', Icons.electric_moped_rounded, kPrimary, cardBg,
                          borderColor, textColorPrimary),
                      const SizedBox(width: 12),
                      _buildMiniStat('Di-Suspend', '$suspendedCount', Icons.block_rounded, Colors.red, cardBg,
                          borderColor, textColorPrimary),
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
                              hintText: 'Cari nama, NIM, atau fakultas driver...',
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

                // Driver List Content
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : allDrivers.isEmpty
                          ? _buildEmptyStateWithSeedButton(textColorPrimary)
                          : filteredDrivers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_off_outlined,
                                          size: 54, color: Colors.grey.withOpacity(0.5)),
                                      const SizedBox(height: 8),
                                      const Text('Tidak ada driver pada filter ini',
                                          style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                                  itemCount: filteredDrivers.length,
                                  itemBuilder: (context, index) {
                                    final driver = filteredDrivers[index];
                                    final bool isActive = driver.isActive;
                                    final bool isStudent = driver.role == 'driver_kampus';

                                    return Container(
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
                                                    backgroundImage: (driver.photoUrl != null &&
                                                            driver.photoUrl!.isNotEmpty)
                                                        ? NetworkImage(driver.photoUrl!)
                                                        : null,
                                                    child: (driver.photoUrl == null || driver.photoUrl!.isEmpty)
                                                        ? Text(
                                                            driver.name.isNotEmpty ? driver.name[0] : 'D',
                                                            style: const TextStyle(
                                                                fontWeight: FontWeight.bold, color: Colors.black),
                                                          )
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
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            driver.name,
                                                            style: TextStyle(
                                                              color: textColorPrimary,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 15,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: isStudent
                                                                ? Colors.blue.withOpacity(0.15)
                                                                : Colors.amber.withOpacity(0.15),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            isStudent ? 'Mahasiswa' : 'Umum',
                                                            style: TextStyle(
                                                              color: isStudent ? Colors.blue : Colors.amber.shade800,
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      isStudent
                                                          ? (driver.facultas ?? 'Fakultas Belum Diisi')
                                                          : 'Mitra Pengemudi Umum',
                                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Popup Action Menu
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                                onSelected: (val) {
                                                  if (val == 'suspend') {
                                                    _toggleSuspendDriver(driver);
                                                  } else if (val == 'call') {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Menghubungi ${driver.phone ?? driver.email}...'),
                                                      ),
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
                                                        Text('Hubungi (${driver.phone ?? '-'})',
                                                            style: const TextStyle(fontSize: 13)),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'suspend',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          !isActive
                                                              ? Icons.check_circle_outline
                                                              : Icons.block_outlined,
                                                          size: 18,
                                                          color: !isActive ? Colors.green : Colors.red,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          !isActive ? 'Aktifkan Akun' : 'Suspend Driver',
                                                          style: TextStyle(
                                                            color: !isActive ? Colors.green : Colors.red,
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
                                                  Text('${driver.rating}',
                                                      style: TextStyle(
                                                          color: textColorPrimary,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12)),
                                                  Text(' (${driver.totalTrips} Trip)',
                                                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                                ],
                                              ),
                                              Text(
                                                driver.email,
                                                style: TextStyle(
                                                    color: textColorPrimary.withOpacity(0.7),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500),
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
          },
        ),
      ),
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
              'Belum Ada Driver di Firestore',
              style: TextStyle(color: textColorPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Koleksi `users` di Firebase Console masih kosong untuk role driver. Tekan tombol di bawah untuk membuat data awal driver.',
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

  Widget _buildMiniStat(String label, String value, IconData icon, Color color, Color cardBg, Color border,
      Color textPrimary) {
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
