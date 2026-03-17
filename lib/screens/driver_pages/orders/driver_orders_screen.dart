import 'package:flutter/material.dart';
import 'driver_navigation_screen.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

class DriverOrdersScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DriverOrdersScreen({super.key, required this.onBack});

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen>
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
                        'Driver History',
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
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
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
                                "https://lh3.googleusercontent.com/aida-public/AB6AXuDWY_MnGB4nAPKOC7Wp52taNN2TiW9HZCSopMgvRtt-cMWSfKi3514RfMnZ8bB2kNh5OzZsDnZ_qzDtacdhnKbDiI1Y-yCnHrb5kOPewbGgRe42iAWOYl5qaNR-QZt1n6dQMPPlnScKar-9gfli2BkXqWjOmsLcmvlqCg1016P5nefRo_hy2d6zMa9-TsS6lgDMY3CRy__DNVrG5KHfqEm694oZCuVYKdzOZo4rGCXUSPycLL_3Ut7ZeZq-Lib8Cx2Bi9OWu2p41yo"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Andi Pratama',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text('4.9', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMuted)),
                              const SizedBox(width: 4),
                              Text('• Student Passenger', style: TextStyle(fontSize: 12, color: textMuted)),
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
                              Text('Fakultas Teknik UI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
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
                              Text('Perpustakaan Pusat UI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
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
                      child: Text('GOPAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
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
                      MaterialPageRoute(builder: (context) => const DriverNavigationScreen()),
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
                  child: const Text('GAS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          child: Text('RECENT ACTIVITY', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        _buildHistoryCard(
          isDark: isDark,
          name: 'Budi Santoso',
          time: 'Today, 10:30 AM',
          price: 'Rp 15.000',
          pickup: 'Fakultas Teknik - Lobby Utama',
          dropoff: 'Perpustakaan Pusat Kampus',
          status: 'Completed',
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBLeqSDoL_1A0kuFZ3OyHshyH-8UW38ra7KGmj1eiZgh5gCMCv1XVTYHeeS8mam1ZtiSPmoLDOixjqbM74MFX0XFvKp4-I7RG_bcsORMirN2a4-_ELvHAbKt9Z7RoqsyhjcD1rPL_uN0Nd9VH8zJ2tnxNf0Z3StDoeG5GVcbhyfbnbiSljUBMAJYwpPnPEumnvOdSGrKBYnkl1wwuMbl7PptK1OCkc20XZX5YjwLJ4K02RltzuUjIo2aHWe5GSM8FkEQsE0NVLlpnk',
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          isDark: isDark,
          name: 'Rizky Pratama',
          time: 'Yesterday, 01:20 PM',
          price: 'Rp 18.500',
          pickup: 'Asrama Mahasiswa Blok B',
          dropoff: 'Pusat Olahraga / Gym',
          status: 'Completed',
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCLCcNypDInDhrqloSpTkfk75wveJ-cOEH1gtAIg2lxmetGaNd3tov9VLRhW0s2watUP1XNGeHzo94wWdHM6qFsTmJBaNcjItfJ1ijNPEe7mKChsBtECTmlBFSuvHpCe_6XAgcJYNCS-XPAWyBXhOrMYYP1Z_3bJxxfwY_ILL3QpM5-dFArre0CD65Ag-VBp68ETVJ_EjBRAJ_HVgysajbj23GDPqWZ0pZ9g1EUnVlVMJyQ_OZNBXVLRT9F9pKq3Q3cRCB1gkAD8es',
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
          child: Text('ABORTED TRIPS', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        _buildHistoryCard(
          isDark: isDark,
          name: 'Siti Aminah',
          time: 'Yesterday, 04:15 PM',
          price: 'Rp 12.000',
          pickup: 'Gerbang Depan (Gate 1)',
          dropoff: 'Gedung Rektorat Lt. 1',
          status: 'Cancelled',
          isCancelled: true,
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBQKjuajXEb3NlzyBEZuurDEDcpKZS3jSMpoTENQrs5_Q1riKpOiq42ZcaCwiWkzix3Yd00-oM2eC4v-qtR415f3EZRZd3PRql5pN6HZbjQ_9AXHAZa4O-DNb4H9Lg-1o5S4C2N7liyKjtf8RpybTzXLluyUMuD_Q1ka3EQcXbotcWVDOyS64LWdo0CpPUpXPNjjWheNX0-dRku1JXTgPxub9oEEh1MOtKq4C3Pxge5Vj0cyJfa-RuUfUuUCp4RCF1zwUSP8ZfU9oo',
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
