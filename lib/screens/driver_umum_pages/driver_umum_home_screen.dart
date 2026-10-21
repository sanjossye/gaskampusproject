import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'orders/driver_umum_orders_screen.dart';
import 'driver_umum_profile_screen.dart';
import '../notifications_screen.dart';
import '../wallet_screen.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

class DriverUmumHomeScreen extends StatefulWidget {
  const DriverUmumHomeScreen({super.key});

  @override
  State<DriverUmumHomeScreen> createState() => _DriverUmumHomeScreenState();
}

class _DriverUmumHomeScreenState extends State<DriverUmumHomeScreen> {
  bool _isWorking = true;
  int _navIndex = 0;
  bool _isLeaderboardExpanded = false;

  // Modified: Using a non-final list initialized in initState
  List<Map<String, dynamic>> _activeOrders = [];

  @override
  void initState() {
    super.initState();
    _activeOrders = [
      {
        'name': 'Andi Pratama',
        'price': 'Rp 12.000',
        'from': 'Stasiun Depok Baru',
        'to': 'Margonda Residence',
        'isPrimary': true,
      },
      {
        'name': 'Siti Aisyah',
        'price': 'Rp 18.500',
        'from': 'Margo City Mall',
        'to': 'Pesona Square',
        'isPrimary': false,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kBackgroundDark : kBackgroundLight;

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: _buildBodyContent(isDark),
      bottomNavigationBar: _buildBottomNav(isDark),
      floatingActionButton: null,
    );
  }

  Widget _buildBodyContent(bool isDark) {
    if (_navIndex == 1) {
      return DriverUmumOrdersScreen(
        onBack: () => setState(() => _navIndex = 0),
      );
    }
    
    if (_navIndex == 2) {
      return WalletScreen(
        onBack: () => setState(() => _navIndex = 0),
      );
    }
    
    if (_navIndex == 3) {
      return DriverUmumProfileScreen(
        onBack: () => setState(() => _navIndex = 0),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            if (_isLeaderboardExpanded) _buildLeaderboardSection(isDark),
            _buildEarningsCard(isDark),
            _buildOrdersSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(color: kPrimary, width: 2),
                          image: const DecorationImage(
                            image: NetworkImage(
                                "https://images.unsplash.com/photo-1543132220-3ce99c5ae93b?auto=format&fit=crop&q=80&w=200"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.black, weight: 700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Rizky Pratama',
                              style: TextStyle(color: textColorPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'GENERAL DRIVER',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: textColorSecondary),
                          const SizedBox(width: 4),
                          Text('Depok, Jawa Barat',
                              style: TextStyle(color: textColorSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLeaderboardExpanded = !_isLeaderboardExpanded;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isLeaderboardExpanded ? kPrimary.withOpacity(0.2) : cardBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Icon(Icons.emoji_events_outlined, color: _isLeaderboardExpanded ? kPrimary : textColorSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Icon(Icons.notifications_outlined, color: textColorSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Availability Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.electric_bolt, color: kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Pekerjaan',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          _isWorking ? 'Mode: Aktif' : 'Mode: Istirahat',
                          style: TextStyle(
                            color: _isWorking ? kPrimary : textColorPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _isWorking,
                  onChanged: (val) {
                    setState(() {
                      _isWorking = val;
                    });
                  },
                  activeColor: kPrimary,
                  activeTrackColor: kPrimary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _navIndex = 2), // Navigasi ke tab Dompet
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                bottom: -30,
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 140,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PENDAPATAN HARI INI',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Rp',
                        style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '85.000',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up, color: kPrimary, size: 14),
                            const SizedBox(width: 4),
                            const Text('+15% vs Sebelumnya',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.moped, color: kPrimary, size: 14),
                            const SizedBox(width: 4),
                            const Text('5 Terkirim',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersSection(bool isDark) {
    if (_activeOrders.isEmpty) return const SizedBox.shrink(); // Hide section if no orders

    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: kPrimary, size: 20),
              const SizedBox(width: 8),
              Text('Order',
                  style: TextStyle(color: textColorPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_activeOrders.length, (index) {
            final order = _activeOrders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(
                isDark: isDark,
                name: order['name'],
                desc: 'Regular Customer',
                price: order['price'],
                from: order['from'],
                to: order['to'],
                isPrimary: order['isPrimary'],
                onDelete: () {
                  setState(() {
                    _activeOrders.removeAt(index);
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required bool isDark,
    required String name,
    required String desc,
    required String price,
    required String from,
    required String to,
    required bool isPrimary,
    required VoidCallback onDelete,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: kPrimary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: kPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(color: textColorPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  price,
                  style: const TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildActionCircle(
            icon: Icons.remove_red_eye_rounded,
            color: kPrimary,
            onTap: () {
              setState(() => _navIndex = 1); // Langsung masuk ke orders
            },
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildActionCircle(
            icon: Icons.close_rounded,
            color: Colors.redAccent,
            onTap: onDelete, // Otomatis terhapus
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon, 
          color: color, 
          size: icon == Icons.close_rounded ? 26 : 24, 
          weight: 900,
        ),
      ),
    );
  }

  Widget _buildLeaderboardSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9); 
    final borderColor = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Leaderboard Driver Umum',
                  style: TextStyle(
                    color: textColorPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLeaderboardItem(1, 'Rizky Pratama', 'Rp 1.250.000', isDark, true),
            const Divider(height: 12),
            _buildLeaderboardItem(2, 'Andi Wijaya', 'Rp 1.100.000', isDark, false),
            const Divider(height: 12),
            _buildLeaderboardItem(3, 'Budi Santoso', 'Rp 950.000', isDark, false),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, String amount, bool isDark, bool isMe) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    
    return Row(
      children: [
        Container(
          width: 24,
          alignment: Alignment.center,
          child: Text(
            rank.toString(),
            style: TextStyle(
              color: rank == 1 ? Colors.amber : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name + (isMe ? ' (Anda)' : ''),
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: kPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey[100]!)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.grid_view_rounded, 'Home', 0, isDark, _navIndex == 0),
            _buildNavItem(Icons.moped, 'Orders', 1, isDark, _navIndex == 1),
            _buildNavItem(Icons.account_balance_wallet, 'Dompet', 2, isDark, _navIndex == 2),
            _buildNavItem(Icons.person_outline, 'Profil', 3, isDark, _navIndex == 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark, bool isActive) {
    final activeColor = kPrimary;
    final inactiveColor = isDark ? Colors.grey[500] : Colors.grey[400];
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _navIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Opacity(
            opacity: isActive ? 1.0 : 0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: isActive ? (isDark ? Colors.white : Colors.black) : color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
