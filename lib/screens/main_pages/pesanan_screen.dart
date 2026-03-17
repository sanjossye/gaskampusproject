import 'package:flutter/material.dart';

const Color kPrimary        = Color(0xFFC0F637);
const Color kSecondaryGreen = Color(0xFF68cd5c);
const Color kBgDark         = Color(0xFF1D2210);
const Color kBgLight        = Color(0xFFF7F8F5);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────
class OrderItem {
  final String driverName;
  final String driverPhoto;
  final String serviceType;
  final String dateLabel;
  final String from;
  final String to;
  final String price;
  final String status; // 'proses' | 'selesai'

  const OrderItem({
    required this.driverName,
    required this.driverPhoto,
    required this.serviceType,
    required this.dateLabel,
    required this.from,
    required this.to,
    required this.price,
    required this.status,
  });
}

final List<OrderItem> _allOrders = [
  const OrderItem(
    driverName: 'Siti Aminah',
    driverPhoto: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    serviceType: 'Goride',
    dateLabel: 'Hari ini, 09:12',
    from: 'Asrama Mahasiswa',
    to: 'Gedung Rektorat',
    price: 'Rp10.000',
    status: 'proses',
  ),
  const OrderItem(
    driverName: 'Budi Santoso',
    driverPhoto: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    serviceType: 'Goride',
    dateLabel: '12 Okt 2023, 10:30',
    from: 'Kampus A',
    to: 'Kantin Pusat',
    price: 'Rp12.000',
    status: 'selesai',
  ),
  const OrderItem(
    driverName: 'Andi Wijaya',
    driverPhoto: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
    serviceType: 'Gocar',
    dateLabel: '11 Okt 2023, 15:45',
    from: 'Fakultas Teknik',
    to: 'Stasiun Kampus',
    price: 'Rp25.000',
    status: 'selesai',
  ),
];

// ─────────────────────────────────────────────
// MAIN PESANAN SCREEN (wrapper with tabs)
// ─────────────────────────────────────────────
class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen>
    with SingleTickerProviderStateMixin {
  // 0 = Find Driver, 1 = Active Order, 2 = Riwayat
  int _mainStep = 0;

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
    switch (_mainStep) {
      case 0:
        return _FindDriverScreen(
          onFindDriver: () => setState(() => _mainStep = 1),
          onShowHistory: () => setState(() => _mainStep = 2),
        );
      case 1:
        return _ActiveOrderScreen(
          onBack: () => setState(() => _mainStep = 0),
          onShowHistory: () => setState(() => _mainStep = 2),
        );
      case 2:
        return _RiwayatScreen(
          tabController: _tabController,
          onBack: () => setState(() => _mainStep = 0),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────
// 1. FIND DRIVER SCREEN
// ─────────────────────────────────────────────
class _FindDriverScreen extends StatelessWidget {
  final VoidCallback onFindDriver;
  final VoidCallback onShowHistory;

  const _FindDriverScreen({
    required this.onFindDriver,
    required this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF181E10) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        'Gojek Kampus',
                        textAlign: TextAlign.center,
                        style: _body(textColorPrimary, 18, FontWeight.bold),
                      ),
                    ),
                    GestureDetector(
                      onTap: onShowHistory,
                      child: Icon(Icons.receipt_long_rounded, color: textColorPrimary),
                    ),
                  ],
                ),
              ),

              // Map Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    image: const DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        top: 40, left: 80,
                        child: Icon(Icons.location_on, color: kPrimary, size: 36),
                      ),
                      Positioned(
                        bottom: 60, right: 80,
                        child: Icon(Icons.trip_origin,
                            color: isDark ? Colors.white : const Color(0xFF0F172A), size: 36),
                      ),
                    ],
                  ),
                ),
              ),

              // Location Selection
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PICKUP LOCATION',
                        style: _body(textColorSecondary, 12, FontWeight.w600, ls: 1)),
                    const SizedBox(height: 8),
                    _locationField(
                      icon: Icons.my_location,
                      iconColor: kPrimary,
                      hint: 'Current Location',
                      prefilled: 'Central Library, Gate 2',
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textColorPrimary: textColorPrimary,
                      textColorSecondary: textColorSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text('DESTINATION',
                        style: _body(textColorSecondary, 12, FontWeight.w600, ls: 1)),
                    const SizedBox(height: 8),
                    _locationField(
                      icon: Icons.location_on_outlined,
                      iconColor: textColorSecondary,
                      hint: 'Where to? (e.g. Faculty of Engineering)',
                      prefilled: null,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textColorPrimary: textColorPrimary,
                      textColorSecondary: textColorSecondary,
                    ),
                    const SizedBox(height: 12),
                    _historyItem(Icons.history, 'Engineering Faculty South Hall',
                        textColorSecondary, isDark),
                    _historyItem(Icons.history, 'Student Dormitory Block C',
                        textColorSecondary, isDark),
                  ],
                ),
              ),

              // Service Category
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service Category',
                        style: _body(textColorPrimary, 16, FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _serviceItem('Goride', Icons.motorcycle, true,
                            inputBg, borderColor, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _serviceItem('Gocar',
                            Icons.directions_car_outlined, false, inputBg, borderColor, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _serviceItem('Gobox',
                            Icons.local_shipping_outlined, false, inputBg, borderColor, isDark)),
                      ],
                    ),
                  ],
                ),
              ),

              // Estimation
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.payments_outlined, color: kPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('ESTIMATED FARE',
                              style: _body(textColorSecondary, 10, FontWeight.w600, ls: 1)),
                          Text('Rp 12.000',
                              style: _body(textColorPrimary, 18, FontWeight.bold)),
                        ]),
                      ]),
                      Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('TIME',
                              style: _body(textColorSecondary, 10, FontWeight.w600, ls: 1)),
                          Text('6-8 mins',
                              style: _body(textColorPrimary, 18, FontWeight.bold)),
                        ]),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF232A18) : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.schedule, color: textColorSecondary, size: 24),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              // Payment + CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withOpacity(0.5)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B6CB0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_wallet,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text('Gopay',
                                style: _body(textColorPrimary, 14, FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text('Rp 45.500',
                                style: _body(textColorSecondary, 12, FontWeight.w500)),
                          ]),
                          Icon(Icons.chevron_right, color: textColorSecondary, size: 20),
                        ]),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.info, color: kPrimary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prices may vary depending on traffic conditions and demand.',
                        style: _body(textColorSecondary, 10, FontWeight.normal)
                            .copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onFindDriver,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search,
                                color: Color(0xFF0F172A), size: 24),
                            const SizedBox(width: 8),
                            Text('Cari Driver',
                                style: _body(
                                    const Color(0xFF0F172A), 18, FontWeight.bold)),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationField({
    required IconData icon,
    required Color iconColor,
    required String hint,
    required String? prefilled,
    required Color inputBg,
    required Color borderColor,
    required Color textColorPrimary,
    required Color textColorSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: _body(textColorSecondary, 14, FontWeight.w500),
            ),
            controller: prefilled != null
                ? TextEditingController(text: prefilled)
                : null,
            style: _body(textColorPrimary, 14, FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _historyItem(
      IconData icon, String text, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Text(text,
            style: _body(
                isDark ? Colors.white70 : Colors.black87, 14, FontWeight.normal)),
      ]),
    );
  }

  Widget _serviceItem(String label, IconData icon, bool isSelected, Color inputBg,
      Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? kPrimary : inputBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isSelected ? Colors.transparent : borderColor),
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: kPrimary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      child: Column(children: [
        Icon(icon,
            color: isSelected
                ? const Color(0xFF0F172A)
                : (isDark ? Colors.white54 : Colors.black45),
            size: 28),
        const SizedBox(height: 4),
        Text(label,
            style: _body(
                isSelected
                    ? const Color(0xFF0F172A)
                    : (isDark ? Colors.white54 : Colors.black45),
                12,
                isSelected ? FontWeight.bold : FontWeight.w500)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// 2. ACTIVE ORDER SCREEN
// ─────────────────────────────────────────────
class _ActiveOrderScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onShowHistory;

  const _ActiveOrderScreen({required this.onBack, required this.onShowHistory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final cardColor = isDark ? const Color(0xFF181E10) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: Stack(children: [
        // Map Background
        Positioned.fill(
          child: Container(
            color: isDark ? Colors.black87 : Colors.grey[200],
            child: Image.network(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
              fit: BoxFit.cover,
              color: isDark ? Colors.black54 : Colors.white24,
              colorBlendMode:
                  isDark ? BlendMode.darken : BlendMode.lighten,
            ),
          ),
        ),

        // Driver Marker
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: MediaQuery.of(context).size.width * 0.4,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.motorcycle_rounded,
                color: Colors.black87, size: 24),
          ),
        ),

        // Top Navigation
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 16, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.black : Colors.white).withOpacity(0.8),
                  Colors.transparent
                ],
              ),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _floatingIcon(Icons.arrow_back_rounded, isDark,
                      onTap: onBack),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF181E10)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text('Gojek Kampus',
                        style: _body(textColorPrimary, 14, FontWeight.bold)),
                  ),
                  _floatingIcon(Icons.receipt_long_rounded, isDark,
                      onTap: onShowHistory),
                ]),
          ),
        ),

        // Map Controls
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height * 0.3,
          child: Column(children: [
            _floatingIcon(Icons.add_rounded, isDark),
            const SizedBox(height: 8),
            _floatingIcon(Icons.remove_rounded, isDark),
            const SizedBox(height: 8),
            _floatingIcon(Icons.my_location_rounded, isDark,
                iconColor: kPrimary),
          ]),
        ),

        // Bottom Sheet
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, -8))
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 12),
              Container(
                width: 48, height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Driver sedang menuju lokasimu',
                                        style: _body(textColorPrimary, 18,
                                            FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Pesanan sedang diproses',
                                        style: _body(textColorSecondary,
                                            14, FontWeight.normal)),
                                  ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text('3 Menit',
                                  style: _body(textColorPrimary, 14,
                                      FontWeight.bold)),
                            ),
                          ]),
                      const SizedBox(height: 24),

                      // Driver Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF232A18)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(children: [
                          SizedBox(
                            width: 56, height: 56,
                            child: Stack(children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: cardColor, width: 2),
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                        'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.1),
                                          blurRadius: 2)
                                    ],
                                  ),
                                  child: const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 14),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text('Budi Santoso',
                                        style: _body(textColorPrimary,
                                            16, FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.circle,
                                        size: 4,
                                        color: textColorSecondary),
                                    const SizedBox(width: 8),
                                    Text('4.9',
                                        style: _body(textColorPrimary,
                                            14, FontWeight.w600)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    'B 1234 GJK',
                                    style: TextStyle(
                                      color: textColorSecondary,
                                      fontSize: 14,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ]),
                          ),
                          Row(children: [
                            _actionBtn(Icons.chat_bubble_outline_rounded,
                                kSecondaryGreen, isDark),
                            const SizedBox(width: 8),
                            _actionBtn(Icons.call_outlined,
                                kSecondaryGreen, isDark),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.share_location_rounded,
                                    color: Colors.black87),
                                const SizedBox(width: 8),
                                Text('Bagikan Lokasi',
                                    style: _body(Colors.black87, 16,
                                        FontWeight.bold)),
                              ]),
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(context).padding.bottom + 16),
                    ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _floatingIcon(IconData icon, bool isDark,
      {Color? iconColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181E10) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon,
            color: iconColor ??
                (isDark ? Colors.white70 : const Color(0xFF334155)),
            size: 24),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, bool isDark) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
            color: color.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─────────────────────────────────────────────
// 3. RIWAYAT PESANAN SCREEN
// ─────────────────────────────────────────────
class _RiwayatScreen extends StatefulWidget {
  final TabController tabController;
  final VoidCallback onBack;

  const _RiwayatScreen(
      {required this.tabController, required this.onBack});

  @override
  State<_RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<_RiwayatScreen> {
  int _selectedTab = 0; // 0=Semua, 1=Proses, 2=Selesai

  List<OrderItem> get _filteredOrders {
    switch (_selectedTab) {
      case 1:
        return _allOrders.where((o) => o.status == 'proses').toList();
      case 2:
        return _allOrders.where((o) => o.status == 'selesai').toList();
      default:
        return _allOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final bg = isDark ? kBgDark : kBgLight;
    final cardBg = isDark ? const Color(0xFF1A2210) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ──
          Container(
            color: isDark
                ? kBgDark.withOpacity(0.95)
                : Colors.white.withOpacity(0.9),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF232A18)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: textColorPrimary, size: 22),
                    ),
                  ),
                  Expanded(
                    child: Text('Riwayat Pesanan',
                        textAlign: TextAlign.center,
                        style: _body(textColorPrimary, 18, FontWeight.bold)),
                  ),
                  const SizedBox(width: 40),
                ]),
              ),

              // Tabs
              Row(children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 12, top: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == i
                                  ? kPrimary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          ['Semua', 'Proses', 'Selesai'][i],
                          textAlign: TextAlign.center,
                          style: _body(
                            _selectedTab == i
                                ? textColorPrimary
                                : textColorSecondary,
                            14,
                            _selectedTab == i
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),

              Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor),
            ]),
          ),

          // ── Order List ──
          Expanded(
            child: _filteredOrders.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64,
                              color: textColorSecondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('Tidak ada pesanan',
                              style: _body(textColorSecondary, 16,
                                  FontWeight.w500)),
                        ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _filteredOrders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _OrderCard(
                        order: order,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColorPrimary: textColorPrimary,
                        textColorSecondary: textColorSecondary,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ]),
      ),

      // Bottom Nav
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2210) : Colors.white,
          border: Border(
              top: BorderSide(color: borderColor, width: 1)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 8,
            top: 8),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, 'Beranda', false,
                  textColorSecondary),
              _navItem(Icons.local_offer_outlined, 'Promo', false,
                  textColorSecondary),
              _navItem(Icons.receipt_long_rounded, 'Pesanan', true,
                  kPrimary),
              _navItem(Icons.person_outline_rounded, 'Profil', false,
                  textColorSecondary),
            ]),
      ),
    );
  }

  Widget _navItem(
      IconData icon, String label, bool active, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 2),
      Text(label,
          style: _body(color, 10,
              active ? FontWeight.bold : FontWeight.normal)),
    ]);
  }
}

// ─────────────────────────────────────────────
// ORDER CARD
// ─────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final Color cardBg;
  final Color borderColor;
  final Color textColorPrimary;
  final Color textColorSecondary;
  final bool isDark;

  const _OrderCard({
    required this.order,
    required this.cardBg,
    required this.borderColor,
    required this.textColorPrimary,
    required this.textColorSecondary,
    required this.isDark,
  });

  bool get isProses => order.status == 'proses';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border(
          top: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
          left: BorderSide(
              color: isProses ? kPrimary : borderColor, width: isProses ? 4 : 1),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Driver row + status badge
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            // Avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: kPrimary.withOpacity(0.3), width: 2),
              ),
              child: ClipOval(
                child: Image.network(order.driverPhoto,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person))),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.driverName,
                  style: _body(textColorPrimary, 14, FontWeight.bold)),
              Text('${order.serviceType} • ${order.dateLabel}',
                  style: _body(textColorSecondary, 12, FontWeight.normal)),
            ]),
          ]),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isProses
                  ? kPrimary.withOpacity(0.2)
                  : kSecondaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              isProses ? 'Proses' : 'Selesai',
              style: _body(
                isProses ? textColorPrimary : kSecondaryGreen,
                12,
                FontWeight.bold,
              ),
            ),
          ),
        ]),

        const SizedBox(height: 12),

        // Route
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            const SizedBox(height: 2),
            Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: kPrimary, shape: BoxShape.circle)),
            Container(
                width: 1, height: 16,
                color: isDark
                    ? Colors.white24
                    : Colors.black12),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDark ? Colors.white38 : Colors.black26,
                    width: 2),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.from,
                      style: _body(textColorSecondary, 12, FontWeight.normal)),
                  const SizedBox(height: 8),
                  Text(order.to,
                      style: _body(textColorSecondary, 12, FontWeight.normal)),
                ]),
          ),
          Text(order.price,
              style: _body(textColorPrimary, 14, FontWeight.bold)),
        ]),

        const SizedBox(height: 12),
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 12),

        // Action Button
        if (isProses)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.black87,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              icon: const Icon(Icons.location_on_rounded, size: 18),
              label: Text('Lacak Driver',
                  style: _body(Colors.black87, 14, FontWeight.bold)),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: textColorPrimary,
                side: const BorderSide(color: kPrimary, width: 2),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(Icons.replay_rounded,
                  size: 18, color: textColorPrimary),
              label: Text('Pesan Lagi',
                  style: _body(textColorPrimary, 14, FontWeight.bold)),
            ),
          ),
      ]),
    );
  }
}