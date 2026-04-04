import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);

class NotificationModel {
  final String id;
  final String title;
  final String desc;
  final String time;
  final DateTime date;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.time,
    required this.date,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'Bonus Berhasil Dicapai!',
      desc: 'Selamat! Anda mencapai target 5 trip hari ini. Bonus Rp 15.000 telah ditambahkan ke dompet.',
      time: '08:45',
      date: DateTime.now(),
      icon: Icons.celebration,
      iconColor: Colors.orange,
      isRead: false,
    ),
    NotificationModel(
      id: '2',
      title: 'Penutupan Jalur Kampus',
      desc: 'Informasi: Jalur utama Gerbatama ditutup sementara karena ada kegiatan wisuda. Silahkan gunakan jalur alternatif.',
      time: '07:30',
      date: DateTime.now(),
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.red,
      isRead: false,
    ),
    NotificationModel(
      id: '3',
      title: 'Tarik Tunai Berhasil',
      desc: 'Penarikan saldo sebesar Rp 100.000 ke rekening Bank Mandiri Anda telah berhasil diproses.',
      time: '15:20',
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.account_balance_wallet_outlined,
      iconColor: kPrimary,
      isRead: true,
    ),
    NotificationModel(
      id: '4',
      title: 'Review Bintang 5 Baru',
      desc: 'Pelanggan memberikan apresiasi: "Driver sangat sopan dan motor bersih. Terima kasih!"',
      time: '12:10',
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.feedback_outlined,
      iconColor: Colors.blue,
      isRead: true,
    ),
    NotificationModel(
      id: '5',
      title: 'Pembaruan Kebijakan Mitra',
      desc: 'Kami telah memperbarui kebijakan keselamatan mitra. Silahkan pelajari detailnya di menu bantuan.',
      time: '09:00',
      date: DateTime.now().subtract(const Duration(days: 2)),
      icon: Icons.security_outlined,
      iconColor: Colors.green,
      isRead: true,
    ),
    NotificationModel(
      id: '6',
      title: 'Promo Akhir Pekan',
      desc: 'Dapatkan tambahan pendapatan hingga Rp 50.000 dengan menyelesaikan 15 trip di hari Sabtu & Minggu.',
      time: '10:00',
      date: DateTime.now().subtract(const Duration(days: 30)),
      icon: Icons.local_offer_outlined,
      iconColor: Colors.purple,
      isRead: true,
    ),
  ];

  String _selectedMonth = 'Semua Bulan';
  
  // Helper to get month name from index
  String _getMonthName(int monthIndex) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[monthIndex];
  }

  // Generate last 4 months dynamically
  List<String> get _availableMonths {
    List<String> result = ['Semua Bulan'];
    DateTime now = DateTime.now();
    for (int i = 0; i < 4; i++) {
      int month = now.month - i;
      if (month <= 0) {
        month += 12;
      }
      result.add(_getMonthName(month));
    }
    return result;
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedMonth == 'Semua Bulan') return _notifications;
    
    return _notifications.where((n) => _getMonthName(n.date.month) == _selectedMonth).toList();
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _deleteAllRead() {
    setState(() {
      _notifications.removeWhere((n) => n.isRead);
    });
  }

  void _deleteAll() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1D2210) : Colors.white;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Informasi Terkini',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (value) {
              if (value == 'delete_read') _deleteAllRead();
              if (value == 'delete_all') _deleteAll();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete_read', child: Text('Hapus dibaca')),
              const PopupMenuItem(value: 'delete_all', child: Text('Hapus semua')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Simplified Month Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 16, color: kPrimary),
                    const SizedBox(width: 8),
                    Text(
                      _selectedMonth,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text('Pilih Bulan', style: TextStyle(color: isDark ? kPrimary : Colors.green[800], fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 16, color: isDark ? kPrimary : Colors.green[800]),
                      ],
                    ),
                  ),
                  onSelected: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                  itemBuilder: (context) => _availableMonths.map((month) => PopupMenuItem(value: month, child: Text(month))).toList(),
                ),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: textMutedColor),
                        const SizedBox(height: 16),
                        Text('Tidak ada notifikasi di $_selectedMonth', style: TextStyle(color: textMutedColor)),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredNotifications.length,
                    separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                    itemBuilder: (context, index) {
                      final item = _filteredNotifications[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (dir) => _deleteNotification(item.id),
                        child: _buildNotificationItem(
                          context,
                          item: item,
                          isDark: isDark,
                          textColor: textColor,
                          textMutedColor: textMutedColor,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required NotificationModel item,
    required bool isDark,
    required Color textColor,
    required Color textMutedColor,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          item.isRead = true;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.transparent : kPrimary.withOpacity(0.05),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 24),
                ),
                if (!item.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.time,
                        style: TextStyle(color: textMutedColor, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.desc,
                          style: TextStyle(
                            color: item.isRead ? textMutedColor : textColor.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 14, color: textMutedColor),
                        onPressed: () => _deleteNotification(item.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
