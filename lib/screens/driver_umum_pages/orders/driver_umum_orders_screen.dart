import 'package:flutter/material.dart';
import 'driver_umum_navigation_screen.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

class DriverUmumOrdersScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DriverUmumOrdersScreen({super.key, required this.onBack});

  @override
  State<DriverUmumOrdersScreen> createState() => _DriverUmumOrdersScreenState();
}

class _DriverUmumOrdersScreenState extends State<DriverUmumOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF020617) : Colors.white; // slate-950 or white
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: widget.onBack,
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Icon(Icons.arrow_back, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Text(
                        'Riwayat Driver Umum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // TabBar
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: kPrimary,
                indicatorWeight: 3,
                labelColor: textColor,
                unselectedLabelColor: const Color(0xFF94A3B8), // slate-400
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Aktif'),
                  Tab(text: 'Selesai'),
                  Tab(text: 'Dibatalkan'),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active Tab
                  _buildActiveTab(isDark),
                  // Completed Tab
                  _buildCompletedTab(isDark),
                  // Cancelled Tab
                  _buildCancelledTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(bool isDark) {
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white; // slate-900 or white
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9); // slate-800 or slate-100
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B); // slate-400 or slate-500

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: NetworkImage(
                                "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Budi Santoso',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text('4.9', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMuted)),
                              const SizedBox(width: 4),
                              Text('• Pelanggan Umum', style: TextStyle(fontSize: 12, color: textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chat_bubble_outline, color: textMuted, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF68CD5C).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call, color: Color(0xFF3E8E34), size: 20),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Locations Map
              Stack(
                children: [
                  Positioned(
                    left: 11,
                    top: 24,
                    bottom: 24,
                    child: Container(
                      width: 2,
                      decoration: const BoxDecoration(),
                      child: CustomPaint(painter: DashedLinePainter(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: kPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PICKUP', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              Text('Stasiun Depok Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.location_on, color: Colors.red, size: 14),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DROPOFF', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              Text('Margonda Residence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Price and GOPAY
              Container(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, color: textMuted),
                        const SizedBox(width: 8),
                        Text('Rp 12.000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('TUNAI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                    ),
                  ],
                ),
              ),
              
              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DriverUmumNavigationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: const Color(0xFF0F172A), // slate-900
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('JALANKAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedTab(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('AKTIVITAS TERAKHIR', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        _buildHistoryCard(
          isDark: isDark,
          name: 'Andi Pratama',
          time: 'Hari Ini, 10:30',
          price: 'Rp 15.000',
          pickup: 'Margo City Mall',
          dropoff: 'Pesona Square',
          status: 'Selesai',
          imageUrl: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&q=80&w=200',
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          isDark: isDark,
          name: 'Rizky Pratama',
          time: 'Kemarin, 13:20',
          price: 'Rp 18.500',
          pickup: 'Dmall Depok',
          dropoff: 'ITC Depok',
          status: 'Selesai',
          imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
        ),
      ],
    );
  }

  Widget _buildCancelledTab(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('PERJALANAN BATAL', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        _buildHistoryCard(
          isDark: isDark,
          name: 'Siti Aminah',
          time: 'Kemarin, 16:15',
          price: 'Rp 12.000',
          pickup: 'Stasiun UI',
          dropoff: 'Pondok Cina',
          status: 'Batal',
          isCancelled: true,
          imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=200',
        ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required bool isDark,
    required String name,
    required String time,
    required String price,
    required String pickup,
    required String dropoff,
    required String status,
    required String imageUrl,
    bool isCancelled = false,
  }) {
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white; // slate-900 or white
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9); // slate-800 or slate-100
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B); // slate-400 or slate-500
    
    final Color badgeBg;
    final Color badgeText;
    final IconData badgeIcon;
    if (isCancelled) {
      badgeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      badgeText = textMuted;
      badgeIcon = Icons.cancel;
    } else {
      badgeBg = const Color(0xFF68CD5C).withOpacity(0.1);
      badgeText = const Color(0xFF68CD5C);
      badgeIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: isCancelled ? (isDark ? Colors.grey[800]! : Colors.grey[300]!) : kPrimary, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        colorFilter: isCancelled ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isCancelled ? textMuted : textColor)),
                      const SizedBox(height: 2),
                      Text(time, style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCancelled ? textMuted : kPrimary,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(badgeIcon, size: 12, color: badgeText),
                        const SizedBox(width: 4),
                        Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeText)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Opacity(
            opacity: isCancelled ? 0.5 : 1.0,
            child: Stack(
              children: [
                Positioned(
                  left: 11,
                  top: 24,
                  bottom: 24,
                  child: Container(
                    width: 2,
                    decoration: const BoxDecoration(),
                    child: CustomPaint(painter: DashedLinePainter(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF020617) : const Color(0xFFF7F8F5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(Icons.location_on, color: isCancelled ? textMuted : kPrimary, size: 16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pickup', style: TextStyle(fontSize: 12, color: textMuted)),
                            Text(pickup, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF020617) : const Color(0xFFF7F8F5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(Icons.outlined_flag, color: textMuted, size: 16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dropoff', style: TextStyle(fontSize: 12, color: textMuted)),
                            Text(dropoff, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
                          ],
                        ),
                      ],
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

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    var max = size.height;
    var dashWidth = 5.0;
    var dashSpace = 3.0;
    double startY = 0;
    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
