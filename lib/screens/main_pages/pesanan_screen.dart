import 'package:flutter/material.dart';

const Color kPrimary        = Color(0xFFC0F637);
const Color kSecondaryGreen = Color(0xFF68cd5c);
const Color kBgDark         = Color(0xFF1D2210);
const Color kBgLight        = Color(0xFFF7F8F5);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

class OrderItem {
  final String driverName;
  final String driverPhoto;
  final String serviceType;
  final String dateLabel;
  final String from;
  final String to;
  final String price;
  final String status;

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

class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen>
    with SingleTickerProviderStateMixin {
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

class _FindDriverScreen extends StatefulWidget {
  final VoidCallback onFindDriver;
  final VoidCallback onShowHistory;

  const _FindDriverScreen({
    required this.onFindDriver,
    required this.onShowHistory,
  });

  @override
  State<_FindDriverScreen> createState() => _FindDriverScreenState();
}

class _FindDriverScreenState extends State<_FindDriverScreen> {
  int _selectedService = 0;
  int _selectedPayment = 0;

  static const _services = [
    {
      'label': 'Goride',
      'icon': Icons.motorcycle,
      'fare': 'Rp 12.000',
      'time': '6-8'
    },
    {
      'label': 'Gocar',
      'icon': Icons.directions_car_rounded,
      'fare': 'Rp 25.000',
      'time': '5-7'
    },
    {
      'label': 'Gobox',
      'icon': Icons.local_shipping_rounded,
      'fare': 'Rp 35.000',
      'time': '10-15'
    },
    {
      'label': 'Lainnya',
      'icon': Icons.more_horiz_rounded,
      'fare': 'Rp 35.000',
      'time': '10-15'
    },
  ];

  static const _paymentMethods = [
    {
      'label': 'Gopay Wallet',
      'sub': 'Rp 45.500',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF2B6CB0),
    },
    {
      'label': 'QRIS',
      'sub': 'Scan & Pay',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Color(0xFF7C3AED),
    },
    {
      'label': 'Tunai',
      'sub': 'Bayar di tempat',
      'icon': Icons.payments_rounded,
      'color': Color(0xFF059669),
    },
  ];

  void _showPaymentSheet(BuildContext context, bool isDark, Color textColorPrimary,
      Color textColorSecondary, Color cardBg, Color borderColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModal) => Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).padding.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text('Metode Pembayaran',
                    style: _body(textColorPrimary, 18, FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Pilih cara kamu membayar perjalanan',
                    style: _body(textColorSecondary, 13, FontWeight.normal)),
                const SizedBox(height: 20),
                ...List.generate(_paymentMethods.length, (i) {
                  final pm = _paymentMethods[i];
                  final isSelected = _selectedPayment == i;
                  final accentColor = pm['color'] as Color;

                  return GestureDetector(
                    onTap: () {
                      setModal(() {});
                      setState(() => _selectedPayment = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withOpacity(isDark ? 0.18 : 0.08)
                            : (isDark ? const Color(0xFF232A18) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? accentColor : borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(pm['icon'] as IconData,
                                color: accentColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pm['label'] as String,
                                    style: _body(textColorPrimary, 15, FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(pm['sub'] as String,
                                    style: _body(textColorSecondary, 12, FontWeight.normal)),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? accentColor : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? accentColor : borderColor,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 13)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Text('Konfirmasi',
                        textAlign: TextAlign.center,
                        style: _body(const Color(0xFF0F172A), 16, FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLainnyaSheet(BuildContext context, bool isDark, Color textColorPrimary,
      Color textColorSecondary, Color cardBg, Color borderColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text('Opsi Lainnya',
                style: _body(textColorPrimary, 18, FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Fitur tambahan untuk perjalananmu',
                style: _body(textColorSecondary, 13, FontWeight.normal)),
            const SizedBox(height: 20),
            _lainnyaItem(
              icon: Icons.note_alt_outlined,
              iconColor: const Color(0xFF2B6CB0),
              title: 'Catatan untuk Driver',
              subtitle: 'Tambahkan instruksi khusus',
              isDark: isDark,
              textColorPrimary: textColorPrimary,
              textColorSecondary: textColorSecondary,
              borderColor: borderColor,
            ),
            const SizedBox(height: 10),
            _lainnyaItem(
              icon: Icons.discount_outlined,
              iconColor: const Color(0xFFE53E3E),
              title: 'Gunakan Voucher',
              subtitle: 'Hemat lebih banyak',
              isDark: isDark,
              textColorPrimary: textColorPrimary,
              textColorSecondary: textColorSecondary,
              borderColor: borderColor,
            ),
            const SizedBox(height: 10),
            _lainnyaItem(
              icon: Icons.group_outlined,
              iconColor: const Color(0xFF7C3AED),
              title: 'Pesan untuk Orang Lain',
              subtitle: 'Kirim pesanan ke kontak',
              isDark: isDark,
              textColorPrimary: textColorPrimary,
              textColorSecondary: textColorSecondary,
              borderColor: borderColor,
            ),
            const SizedBox(height: 10),
            _lainnyaItem(
              icon: Icons.schedule_rounded,
              iconColor: const Color(0xFF059669),
              title: 'Jadwalkan Perjalanan',
              subtitle: 'Atur waktu penjemputan',
              isDark: isDark,
              textColorPrimary: textColorPrimary,
              textColorSecondary: textColorSecondary,
              borderColor: borderColor,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _lainnyaItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textColorPrimary,
    required Color textColorSecondary,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232A18) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: _body(textColorPrimary, 14, FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: _body(textColorSecondary, 12, FontWeight.normal)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: textColorSecondary, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kBgDark : kBgLight;
    final textColorPrimary   = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final inputBg    = isDark ? const Color(0xFF181E10) : Colors.white;
    final cardBg     = isDark ? const Color(0xFF1A2210) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    final svc = _services[_selectedService];
    final pm  = _paymentMethods[_selectedPayment];
    final pmColor = pm['color'] as Color;

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            const SizedBox(height: 20),
            Row(
              children: List.generate(_services.length, (i) {
                final s = _services[i];
                final isSel = _selectedService == i;
                final isLainnya = i == _services.length - 1;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isLainnya) {
                        _showLainnyaSheet(
                            context,
                            isDark,
                            textColorPrimary,
                            textColorSecondary,
                            cardBg,
                            borderColor);
                      } else {
                        setState(() => _selectedService = i);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < _services.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel
                            ? kPrimary
                            : (isDark
                                ? const Color(0xFF232A18)
                                : const Color(0xFFF1F5F0)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSel ? Colors.transparent : borderColor),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                    color: kPrimary.withOpacity(0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Icon(s['icon'] as IconData,
                              size: 26,
                              color: isSel
                                  ? const Color(0xFF0F172A)
                                  : (isDark ? Colors.white54 : Colors.black38)),
                          const SizedBox(height: 5),
                          Text(s['label'] as String,
                              style: _body(
                                isSel
                                    ? const Color(0xFF0F172A)
                                    : (isDark ? Colors.white54 : Colors.black38),
                                11,
                                isSel ? FontWeight.bold : FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ── Fare + Time strip ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, color: kPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    svc['fare'] as String,
                    style: _body(textColorPrimary, 16, FontWeight.bold),
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: borderColor,
                  ),
                  Icon(Icons.schedule_rounded, color: textColorSecondary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${svc['time']} mnt',
                    style: _body(textColorSecondary, 13, FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF6B35),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cepat!',
                    style: _body(const Color(0xFFFF6B35), 12, FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Payment selector row ──
            GestureDetector(
              onTap: () => _showPaymentSheet(
                  context, isDark, textColorPrimary, textColorSecondary, cardBg, borderColor),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: pmColor.withOpacity(isDark ? 0.12 : 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: pmColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: pmColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(pm['icon'] as IconData, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pm['label'] as String,
                            style: _body(textColorPrimary, 13, FontWeight.bold)),
                        Text(pm['sub'] as String,
                            style: _body(textColorSecondary, 11, FontWeight.normal)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pmColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(children: [
                        Text('Ganti', style: _body(pmColor, 11, FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, color: pmColor, size: 14),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

  
            const SizedBox(height: 24),

            GestureDetector(
              onTap: widget.onFindDriver,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF0F172A), size: 22),
                    const SizedBox(width: 8),
                    Text('Cari Driver',
                        style: _body(const Color(0xFF0F172A), 17, FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                     
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      onTap: widget.onShowHistory,
                      child: Icon(Icons.receipt_long_rounded, color: textColorPrimary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PICKUP LOCATION',
                        style: _body(textColorSecondary, 12, FontWeight.w600, ls: 1)),
                    const SizedBox(height: 12),
                    _locationField(
                      icon: Icons.my_location,
                      iconColor: kPrimary,
                      hint: 'Current Location',
                      prefilled: 'Fakultas Teknik, Gerbang 2',
                      inputBg: inputBg,
                      borderColor: borderColor,
                      textColorPrimary: textColorPrimary,
                      textColorSecondary: textColorSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text('DESTINATION',
                        style: _body(textColorSecondary, 12, FontWeight.w600, ls: 1)),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 8),
                    _historyItem(Icons.history, 'Engineering Faculty South Hall',
                        textColorSecondary, isDark),
                    _historyItem(Icons.history, 'Student Dormitory Block C',
                        textColorSecondary, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
      child: Row(
        children: [
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
        ],
      ),
    );
  }

  Widget _historyItem(IconData icon, String text, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Text(text,
              style: _body(
                isDark ? Colors.white70 : Colors.black87, 14, FontWeight.normal)),
        ],
      ),
    );
  }
}

class _ActiveOrderScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onShowHistory;

  const _ActiveOrderScreen({required this.onBack, required this.onShowHistory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorPrimary   = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final cardColor = isDark ? const Color(0xFF181E10) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: Stack(
        children: [
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
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.motorcycle_rounded, color: Colors.black87, size: 24),
            ),
          ),
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
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _floatingIcon(Icons.arrow_back_rounded, isDark, onTap: onBack),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF181E10) : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Gojek Kampus',
                      style: _body(textColorPrimary, 14, FontWeight.bold),
                    ),
                  ),
                  _floatingIcon(Icons.receipt_long_rounded, isDark, onTap: onShowHistory),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.3,
            child: Column(
              children: [
                _floatingIcon(Icons.add_rounded, isDark),
                const SizedBox(height: 8),
                _floatingIcon(Icons.remove_rounded, isDark),
                const SizedBox(height: 8),
                _floatingIcon(Icons.my_location_rounded, isDark, iconColor: kPrimary),
              ],
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48, height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Driver sedang menuju lokasimu',
                                    style: _body(textColorPrimary, 18, FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pesanan sedang diproses',
                                    style: _body(textColorSecondary, 14, FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '3 Menit',
                                style: _body(textColorPrimary, 14, FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF232A18)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 56, height: 56,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: cardColor, width: 2),
                                        image: const DecorationImage(
                                          image: NetworkImage(
                                            'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
                                          ),
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
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.star_rounded,
                                            color: Colors.amber, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Budi Santoso',
                                          style: _body(textColorPrimary, 16, FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.circle, size: 4, color: textColorSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                          '4.9',
                                          style: _body(textColorPrimary, 14, FontWeight.w600),
                                        ),
                                      ],
                                    ),
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
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _actionBtn(Icons.chat_bubble_outline_rounded,
                                      kSecondaryGreen, isDark),
                                  const SizedBox(width: 8),
                                  _actionBtn(Icons.call_outlined,
                                      kSecondaryGreen, isDark),
                                ],
                              ),
                            ],
                          ),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.share_location_rounded,
                                    color: Colors.black87),
                                const SizedBox(width: 8),
                                Text(
                                  'Bagikan Lokasi',
                                  style: _body(Colors.black87, 16, FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? (isDark ? Colors.white70 : const Color(0xFF334155)),
          size: 24,
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, bool isDark) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _RiwayatScreen extends StatefulWidget {
  final TabController tabController;
  final VoidCallback onBack;

  const _RiwayatScreen({required this.tabController, required this.onBack});

  @override
  State<_RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<_RiwayatScreen> {
  int _selectedTab = 0;

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
    final textColorPrimary   = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final bg          = isDark ? kBgDark : kBgLight;
    final cardBg      = isDark ? const Color(0xFF1A2210) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A3518) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: isDark
                  ? kBgDark.withOpacity(0.95)
                  : Colors.white.withOpacity(0.9),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onBack,
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF232A18) : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back_rounded,
                                color: textColorPrimary, size: 22),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Riwayat Pesanan',
                            textAlign: TextAlign.center,
                            style: _body(textColorPrimary, 18, FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Row(
                    children: [
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
                    ],
                  ),
                  Divider(height: 1, thickness: 1, color: borderColor),
                ],
              ),
            ),
            Expanded(
              child: _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: textColorSecondary.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada pesanan',
                            style: _body(textColorSecondary, 16, FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _filteredOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2210) : Colors.white,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8,
          top: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_outlined,          'Beranda', false, textColorSecondary),
            _navItem(Icons.local_offer_outlined,   'Promo',   false, textColorSecondary),
            _navItem(Icons.receipt_long_rounded,   'Pesanan', true,  kPrimary),
            _navItem(Icons.person_outline_rounded, 'Profil',  false, textColorSecondary),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: _body(color, 10, active ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}

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
          top:    BorderSide(color: borderColor),
          right:  BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
          left:   BorderSide(
            color: isProses ? kPrimary : borderColor,
            width: isProses ? 4 : 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimary.withOpacity(0.3), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        order.driverPhoto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.driverName,
                        style: _body(textColorPrimary, 14, FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.serviceType} • ${order.dateLabel}',
                        style: _body(textColorSecondary, 12, FontWeight.normal),
                      ),
                    ],
                  ),
                ],
              ),
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
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 2),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                  ),
                  Container(
                    width: 1, height: 16,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white38 : Colors.black26,
                        width: 2,
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
                    Text(
                      order.from,
                      style: _body(textColorSecondary, 12, FontWeight.normal),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.to,
                      style: _body(textColorSecondary, 12, FontWeight.normal),
                    ),
                  ],
                ),
              ),
              Text(
                order.price,
                style: _body(textColorPrimary, 14, FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),
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
                label: Text(
                  'Lacak Driver',
                  style: _body(Colors.black87, 14, FontWeight.bold),
                ),
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
                icon: Icon(Icons.replay_rounded, size: 18, color: textColorPrimary),
                label: Text(
                  'Pesan Lagi',
                  style: _body(textColorPrimary, 14, FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}