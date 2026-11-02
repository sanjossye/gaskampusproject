import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBgDark = Color(0xFF1D2210);
const Color kBgLight = Color(0xFFF7F8F5);

class AdminOrdersScreen extends StatefulWidget {
  final String initialFilter;

  const AdminOrdersScreen({super.key, this.initialFilter = 'Semua'});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late String _selectedFilter;
  String _searchQuery = '';

  final List<String> _filters = ['Semua', 'Berjalan', 'Bermasalah', 'Selesai', 'Batal'];

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'GK-9821',
      'service': 'Antar (Ride)',
      'serviceIcon': Icons.electric_moped_rounded,
      'passenger': 'Nadia Savira',
      'passengerPhone': '0812-4455-6677',
      'driver': 'Dimas Anggara',
      'driverPhone': '0812-3344-5566',
      'driverRole': 'Driver Mahasiswa',
      'plate': 'B 4120 KLP',
      'pickup': 'Asrama Mahasiswa Putri UI',
      'destination': 'Fakultas Ilmu Komputer (Gedung B)',
      'fare': 'Rp 8.000',
      'payment': 'GasPay',
      'status': 'on_trip', // pending, on_trip, completed, issue, cancelled
      'statusLabel': 'Sedang Jalan',
      'time': '10 mnt lalu',
      'isIssue': false,
    },
    {
      'id': 'GK-9818',
      'service': 'Antar (Ride)',
      'serviceIcon': Icons.electric_moped_rounded,
      'passenger': 'Budi Santoso',
      'passengerPhone': '0857-1199-2233',
      'driver': 'Agus Prabowo',
      'driverPhone': '0857-1122-3344',
      'driverRole': 'Driver Umum',
      'plate': 'B 5590 XZZ',
      'pickup': 'Stasiun Pondok Cina',
      'destination': 'Balairung Kampus',
      'fare': 'Rp 14.000',
      'payment': 'Tunai',
      'status': 'issue',
      'statusLabel': 'Bermasalah',
      'time': '28 mnt lalu',
      'isIssue': true,
      'issueReason': 'Posisi GPS driver tidak bergerak selama 18 menit.',
    },
    {
      'id': 'GK-9815',
      'service': 'Makan (Food)',
      'serviceIcon': Icons.restaurant_rounded,
      'passenger': 'Dewi Lestari',
      'passengerPhone': '0821-3322-1144',
      'driver': 'Rian Hidayat',
      'driverPhone': '0813-9900-1122',
      'driverRole': 'Driver Mahasiswa',
      'plate': 'B 6678 TYU',
      'pickup': 'Kantin Vokasi - Soto Bu Sri',
      'destination': 'Perpustakaan Pusat Lantai 3',
      'fare': 'Rp 22.000',
      'payment': 'GasPay',
      'status': 'issue',
      'statusLabel': 'Bermasalah',
      'time': '35 mnt lalu',
      'isIssue': true,
      'issueReason': 'Driver melaporkan antrean kantin tutup mendadak.',
    },
    {
      'id': 'GK-9812',
      'service': 'Beliin (Jastip)',
      'serviceIcon': Icons.shopping_bag_rounded,
      'passenger': 'Farhan Maulana',
      'passengerPhone': '0878-1122-4455',
      'driver': 'Kevin Sanjaya',
      'driverPhone': '0878-5566-7788',
      'driverRole': 'Driver Mahasiswa',
      'plate': 'B 2291 POQ',
      'pickup': 'Fotokopi Kober Kampus',
      'destination': 'Lab Komputer FT',
      'fare': 'Rp 15.000',
      'payment': 'GasPay',
      'status': 'on_trip',
      'statusLabel': 'Sedang Diantar',
      'time': '12 mnt lalu',
      'isIssue': false,
    },
    {
      'id': 'GK-9805',
      'service': 'Antar (Ride)',
      'serviceIcon': Icons.electric_moped_rounded,
      'passenger': 'Alya Rohali',
      'passengerPhone': '0813-5566-7788',
      'driver': 'Hendro Susanto',
      'driverPhone': '0812-9988-7711',
      'driverRole': 'Driver Umum',
      'plate': 'B 3019 ERT',
      'pickup': 'Kukusan Kelurahan',
      'destination': 'Fakultas Ekonomi',
      'fare': 'Rp 10.000',
      'payment': 'GasPay',
      'status': 'completed',
      'statusLabel': 'Selesai',
      'time': '1 jam lalu',
      'isIssue': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  void _showResolveIssueDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Intervensi Order ${order['id']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Penumpang: ${order['passenger']} (${order['passengerPhone']})'),
              const SizedBox(height: 4),
              Text('Driver: ${order['driver']} (${order['driverPhone']})'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order['issueReason'] ?? 'Kendala pengantaran',
                  style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Pilih Tindakan Admin:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  order['status'] = 'cancelled';
                  order['statusLabel'] = 'Dibatalkan Admin';
                  order['isIssue'] = false;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ${order['id']} dibatalkan & dana direfund ke saldo pemesan.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Batalkan & Refund'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  order['status'] = 'on_trip';
                  order['statusLabel'] = 'Dipulihkan';
                  order['isIssue'] = false;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kendala order ${order['id']} diselesaikan.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.black),
              child: const Text('Tandai Selesai Kendala'),
            ),
          ],
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

    final filteredOrders = _orders.where((o) {
      final matchesSearch = o['id'].toString().toLowerCase().contains(_searchQuery) ||
          o['passenger'].toString().toLowerCase().contains(_searchQuery) ||
          o['driver'].toString().toLowerCase().contains(_searchQuery) ||
          o['destination'].toString().toLowerCase().contains(_searchQuery);

      if (!matchesSearch) return false;

      switch (_selectedFilter) {
        case 'Berjalan':
          return o['status'] == 'on_trip';
        case 'Bermasalah':
          return o['isIssue'] == true;
        case 'Selesai':
          return o['status'] == 'completed';
        case 'Batal':
          return o['status'] == 'cancelled';
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
                      Text('Monitoring Pesanan', style: TextStyle(color: textColorPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Pantau perjalanan aktif dan kendala rute kampus', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_orders.length} Order Hari Ini', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
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
                          hintText: 'Cari Order ID, pemesan, driver, tujuan...',
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
                    selectedColor: filter == 'Bermasalah' ? Colors.orange : kPrimary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : textColorPrimary,
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

            // Orders List
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          const Text('Tidak ada pesanan pada filter ini', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final bool isIssue = order['isIssue'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isIssue ? Colors.orange.withOpacity(0.6) : borderColor,
                              width: isIssue ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Top Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(order['serviceIcon'] as IconData, size: 18, color: kPrimary),
                                      const SizedBox(width: 6),
                                      Text(
                                        order['id'],
                                        style: TextStyle(
                                          color: textColorPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text('• ${order['time']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                  _buildOrderStatusBadge(order['status'], order['statusLabel']),
                                ],
                              ),

                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Route Details
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      const Icon(Icons.circle, color: Colors.green, size: 10),
                                      Container(width: 2, height: 20, color: Colors.grey.withOpacity(0.3)),
                                      const Icon(Icons.location_on, color: Colors.red, size: 12),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order['pickup'],
                                          style: TextStyle(color: textColorPrimary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          order['destination'],
                                          style: TextStyle(color: textColorPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // User & Driver info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Pemesan: ${order['passenger']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text('Driver: ${order['driver']} (${order['plate']})', style: TextStyle(color: textColorPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(order['fare'], style: TextStyle(color: textColorPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(order['payment'], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),

                              // Issue Alert Box
                              if (isIssue) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_rounded, color: Colors.orange, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          order['issueReason'],
                                          style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _showResolveIssueDialog(order),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Tindak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
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

  Widget _buildOrderStatusBadge(String status, String label) {
    Color bg;
    Color text;

    switch (status) {
      case 'on_trip':
        bg = Colors.blue.withOpacity(0.15);
        text = Colors.blue;
        break;
      case 'issue':
        bg = Colors.orange.withOpacity(0.15);
        text = Colors.orange;
        break;
      case 'completed':
        bg = Colors.green.withOpacity(0.15);
        text = Colors.green;
        break;
      case 'cancelled':
        bg = Colors.red.withOpacity(0.15);
        text = Colors.red;
        break;
      default:
        bg = Colors.grey.withOpacity(0.15);
        text = Colors.grey;
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
