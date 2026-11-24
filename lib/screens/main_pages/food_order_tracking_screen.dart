import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFFC0F637);
const Color _kPrimaryDeep = Color(0xFF7EB50F);
const Color _kFoodAccent = Color(0xFFFF9F43);
const Color _kBgDark = Color(0xFF0E1009);
const Color _kBgLight = Color(0xFFF6F8F2);
const Color _kCardDark = Color(0xFF1A2211);
const Color _kBorderDark = Color(0xFF2B371C);
const Color _kBorderLight = Color(0xFFE5EAE0);

/// Halaman pelacakan khusus pesanan makanan GasMakan yang berbeda dengan Ojek:
/// 1. `pending` / `accepted` / `preparing` / `going_to_merchant`:
///    Animasi motor menuju toko merchant.
/// 2. `picked_up`:
///    Merchant klik "Makanan Telah Diambil Driver" -> animasi kurir ambil paket.
/// 3. `onTrip`:
///    Driver mengantar pesanan ke tempat mahasiswa -> animasi pengantaran kurir.
/// 4. `completed`:
///    Driver mencentang "Saya Sudah Sampai" -> pesanan selesai tiba.
class FoodOrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final String merchantName;
  final String merchantAddress;
  final String destinationAddress;
  final String itemsSummary;
  final String totalLabel;
  final String paymentMethod;
  final String initialPaymentStatus;
  final String initialStatus;
  final VoidCallback? onFinish;

  const FoodOrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.merchantName,
    required this.merchantAddress,
    required this.destinationAddress,
    required this.itemsSummary,
    required this.totalLabel,
    this.paymentMethod = 'GasPay',
    this.initialPaymentStatus = 'paid',
    this.initialStatus = 'pending',
    this.onFinish,
  });

  @override
  State<FoodOrderTrackingScreen> createState() =>
      _FoodOrderTrackingScreenState();
}

class _FoodOrderTrackingScreenState extends State<FoodOrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  bool get _isRemoteOrder =>
      !widget.orderId.startsWith('local_') &&
      !widget.orderId.startsWith('food_');

  int _phaseForStatus(String status) {
    return switch (status) {
      'picked_up' => 1,
      'onTrip' => 2,
      'completed' => 3,
      'cancelled' => -1,
      _ => 0, // pending, accepted, preparing, going_to_merchant
    };
  }

  void _handleExit() {
    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _kBgDark : _kBgLight;

    if (!_isRemoteOrder) {
      return Scaffold(
        backgroundColor: bg,
        body: _buildTrackingBody(
          context: context,
          isDark: isDark,
          status: widget.initialStatus,
          driverName: '',
          arrivedChecked: widget.initialStatus == 'completed',
          merchantName: widget.merchantName,
          merchantAddress: widget.merchantAddress,
          destinationAddress: widget.destinationAddress,
          itemsSummary: widget.itemsSummary,
          paymentMethod: widget.paymentMethod,
          paymentStatus: widget.initialPaymentStatus,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final status = (data?['status'] ?? widget.initialStatus).toString();
          final driverName = (data?['driverName'] ?? '').toString().trim();
          final arrivedChecked = data?['arrivedCheckedByDriver'] == true;
          final merchantName = (data?['merchantName'] ??
                  data?['originName'] ??
                  widget.merchantName)
              .toString();
          final merchantAddr =
              (data?['originAddress'] ?? widget.merchantAddress).toString();
          final destAddr =
              (data?['destinationAddress'] ?? widget.destinationAddress)
                  .toString();
          final items = (data?['items'] ?? widget.itemsSummary).toString();
          final payMethod =
              (data?['paymentMethod'] ?? widget.paymentMethod).toString();
          final payStatus = (data?['paymentStatus'] ??
                  (payMethod.toLowerCase() == 'tunai'
                      ? 'unpaid'
                      : widget.initialPaymentStatus))
              .toString();

          return _buildTrackingBody(
            context: context,
            isDark: isDark,
            status: status,
            driverName: driverName,
            arrivedChecked: arrivedChecked,
            merchantName: merchantName,
            merchantAddress: merchantAddr,
            destinationAddress: destAddr,
            itemsSummary: items,
            paymentMethod: payMethod,
            paymentStatus: payStatus,
          );
        },
      ),
    );
  }

  Widget _buildTrackingBody({
    required BuildContext context,
    required bool isDark,
    required String status,
    required String driverName,
    required bool arrivedChecked,
    required String merchantName,
    required String merchantAddress,
    required String destinationAddress,
    required String itemsSummary,
    required String paymentMethod,
    required String paymentStatus,
  }) {
    final cardBg = isDark ? _kCardDark : Colors.white;
    final border = isDark ? _kBorderDark : _kBorderLight;
    final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts = isDark ? const Color(0xFF94A87B) : const Color(0xFF5D6C4D);

    final phase = _phaseForStatus(status);
    final meta = _phaseCopy(
      status: status,
      phase: phase,
      merchantName: merchantName,
      destinationAddress: destinationAddress,
      driverName: driverName,
    );

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: _handleExit,
                  icon: Icon(Icons.arrow_back_rounded, color: tp),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lacak Pesanan Makanan',
                        style: TextStyle(
                          color: tp,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        merchantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ts,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  meta.badge,
                  style: TextStyle(
                    color: phase == -1
                        ? Colors.redAccent
                        : (phase == 3 ? const Color(0xFF16A34A) : _kFoodAccent),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // Area Animasi Khusus Proses Makanan
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _FoodDeliveryStagePainter(
                            progress: _animCtrl.value,
                            phase: phase,
                            isDark: isDark,
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Headline status tahap aktif
                Text(
                  meta.title,
                  style: TextStyle(
                    color: tp,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meta.subtitle,
                  style: TextStyle(
                    color: ts,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                if (driverName.isNotEmpty && phase >= 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_motorsports_rounded,
                        size: 18,
                        color: _kPrimaryDeep,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Driver: $driverName',
                        style: TextStyle(
                          color: tp,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                if (phase == 3 && arrivedChecked) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 19,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Driver mencentang "Saya Sudah Sampai"',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFF15803D),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 22),

                // Timeline 4 Tahap GasMakan
                if (phase >= 0) _buildFoodStepTimeline(phase, cardBg, border, tp, ts),

                const SizedBox(height: 18),

                // Ringkasan pesanan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rincian Pengantaran',
                        style: TextStyle(
                          color: tp,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoLine(
                        Icons.storefront_rounded,
                        'Merchant',
                        '$merchantName${merchantAddress.isNotEmpty ? ' • $merchantAddress' : ''}',
                        tp,
                        ts,
                      ),
                      const SizedBox(height: 10),
                      _infoLine(
                        Icons.fastfood_rounded,
                        'Menu Dipesan',
                        itemsSummary,
                        tp,
                        ts,
                      ),
                      const SizedBox(height: 10),
                      _infoLine(
                        Icons.location_on_rounded,
                        'Antar ke Tempat Anda',
                        destinationAddress,
                        tp,
                        ts,
                      ),
                      if (widget.totalLabel.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(color: border, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total ($paymentMethod)',
                              style: TextStyle(
                                color: ts,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.totalLabel,
                              style: TextStyle(
                                color: tp,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status Pembayaran',
                              style: TextStyle(
                                color: ts,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              paymentStatus == 'unpaid'
                                  ? 'Belum Dibayar (Bayar Tunai)'
                                  : 'Lunas',
                              style: TextStyle(
                                color: paymentStatus == 'unpaid'
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF16A34A),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: const Color(0xFF0A0F02),
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  phase == 3 || phase == -1 ? 'Selesai' : 'Kembali ke Beranda',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodStepTimeline(
    int currentPhase,
    Color cardBg,
    Color border,
    Color tp,
    Color ts,
  ) {
    final steps = const [
      (
        title: 'Menuju Merchant',
        desc: 'Driver berkendara ke toko merchant',
        icon: Icons.two_wheeler_rounded,
      ),
      (
        title: 'Makanan Telah Diambil Driver',
        desc: 'Dikonfirmasi merchant · kurir mengambil paket',
        icon: Icons.inventory_2_rounded,
      ),
      (
        title: 'Diantar ke Tempat Anda',
        desc: 'Kurir sedang dalam perjalanan mengantar',
        icon: Icons.local_shipping_rounded,
      ),
      (
        title: 'Saya Sudah Sampai',
        desc: 'Driver mencentang tanda kedatangan pesanan',
        icon: Icons.check_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= currentPhase
                            ? (i == 3 && currentPhase == 3
                                ? const Color(0xFF16A34A)
                                : _kPrimary)
                            : border.withValues(alpha: 0.45),
                      ),
                      child: Icon(
                        i < currentPhase ? Icons.check_rounded : steps[i].icon,
                        size: 16,
                        color: i <= currentPhase
                            ? (i == 3 && currentPhase == 3
                                ? Colors.white
                                : const Color(0xFF0A0F02))
                            : ts,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 26,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: i < currentPhase ? _kPrimary : border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: TextStyle(
                            color: i <= currentPhase ? tp : ts,
                            fontSize: 13.5,
                            fontWeight: i == currentPhase
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].desc,
                          style: TextStyle(
                            color: ts,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoLine(
    IconData icon,
    String label,
    String value,
    Color tp,
    Color ts,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _kFoodAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: ts,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  color: tp,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ({String badge, String title, String subtitle}) _phaseCopy({
    required String status,
    required int phase,
    required String merchantName,
    required String destinationAddress,
    required String driverName,
  }) {
    if (phase == -1) {
      return (
        badge: 'Dibatalkan',
        title: 'Pesanan Dibatalkan',
        subtitle:
            'Maaf, pesanan di $merchantName tidak dapat dilanjutkan.',
      );
    }
    if (phase == 0) {
      if (status == 'going_to_merchant') {
        return (
          badge: 'Ke Merchant',
          title: 'Driver Menuju Merchant',
          subtitle:
              '${driverName.isNotEmpty ? driverName : 'Driver'} sedang menuju $merchantName untuk mengambil pesanan makananmu.',
        );
      }
      return (
        badge: 'Menunggu Driver',
        title: 'Menunggu Driver Menuju Merchant',
        subtitle:
            'Pesanan sedang diproses oleh $merchantName sambil driver menuju lokasi toko.',
      );
    }
    if (phase == 1) {
      return (
        badge: 'Diambil Driver',
        title: 'Makanan Telah Diambil Driver',
        subtitle:
            '$merchantName mengonfirmasi makanan sudah diambil kurir. Sebentar lagi driver berangkat ke tempatmu.',
      );
    }
    if (phase == 2) {
      return (
        badge: 'Sedang Diantar',
        title: 'Driver Mengantar ke Tempat Anda',
        subtitle:
            'Pesananmu sedang dibawa menuju $destinationAddress.',
      );
    }
    return (
      badge: 'Sudah Sampai',
      title: 'Pesanan Telah Sampai!',
      subtitle:
          'Driver sudah tiba di $destinationAddress dan mencentang "Saya Sudah Sampai". Selamat menikmati!',
    );
  }
}

/// CustomPainter 4 fase animasi makanan:
/// - Phase 0: Animasi motor melaju ke arah bangunan merchant.
/// - Phase 1: Animasi kurir mengambil / mengangkat paket makanan di toko.
/// - Phase 2: Animasi kurir motor membawa paket menuju pin lokasi pemesan.
/// - Phase 3: Paket telah tiba di lokasi pemesan dengan tanda centang bersih.
class _FoodDeliveryStagePainter extends CustomPainter {
  final double progress;
  final int phase;
  final bool isDark;

  _FoodDeliveryStagePainter({
    required this.progress,
    required this.phase,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Langit lembut & bukit kampus halus
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1F2B13), const Color(0xFF141B0D)]
            : [const Color(0xFFF3FAE4), const Color(0xFFFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    final roadY = h * 0.74;
    // Jalan beraspal bersih + garis putus-putus
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF28331D) : const Color(0xFFE7EDE1)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(28, roadY), Offset(w - 28, roadY), roadPaint);

    final dashPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (double x = 36; x < w - 42; x += 22) {
      canvas.drawLine(Offset(x, roadY), Offset(x + 10, roadY), dashPaint);
    }

    if (phase == 0) {
      _paintMotoToMerchant(canvas, size, roadY);
    } else if (phase == 1) {
      _paintCourierPickPackage(canvas, size, roadY);
    } else if (phase == 2) {
      _paintDeliverToCustomer(canvas, size, roadY);
    } else if (phase == 3) {
      _paintArrivedAtCustomer(canvas, size, roadY);
    } else {
      _paintCancelled(canvas, size);
    }
  }

  void _paintMotoToMerchant(Canvas canvas, Size size, double roadY) {
    final w = size.width;
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2);

    // Toko Merchant di kanan
    final storeX = w - 64.0;
    _drawMerchantStore(canvas, Offset(storeX, roadY - 6), pulse);

    // Titik start di kiri & gerak motor berulang menuju toko merchant
    final t = Curves.easeInOut.transform(progress);
    final motoX = 48.0 + (storeX - 108.0) * t;
    final bounce = math.sin(progress * math.pi * 10) * 1.8;

    // Jejak arah ke merchant
    final guidePaint = Paint()
      ..color = _kPrimary.withValues(alpha: 0.75)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(motoX + 24, roadY - 12),
      Offset(storeX - 38, roadY - 12),
      guidePaint,
    );

    _drawMotorcycleRider(
      canvas,
      Offset(motoX, roadY - 6 + bounce),
      hasFoodBox: false,
      wheelSpin: progress * math.pi * 8,
    );
  }

  void _paintCourierPickPackage(Canvas canvas, Size size, double roadY) {
    final w = size.width;
    final centerX = w * 0.5;
    final lift = math.sin(progress * math.pi) * 26.0;
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2);

    // Toko merchant di kiri tengah
    _drawMerchantStore(canvas, Offset(centerX - 66, roadY - 6), pulse * 0.6);

    // Kurir berdiri di kanan tengah mengambil paket
    final courierX = centerX + 54;
    final bodyPaint = Paint()..color = _kPrimary;
    final darkPaint = Paint()..color = const Color(0xFF0E1405);

    // Kaki & badan kurir
    canvas.drawLine(
      Offset(courierX - 5, roadY - 4),
      Offset(courierX - 5, roadY - 24),
      Paint()
        ..color = darkPaint.color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(courierX + 6, roadY - 4),
      Offset(courierX + 6, roadY - 24),
      Paint()
        ..color = darkPaint.color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(courierX, roadY - 37),
          width: 22,
          height: 26,
        ),
        const Radius.circular(8),
      ),
      bodyPaint,
    );
    // Kepala & helm kurir
    canvas.drawCircle(
      Offset(courierX, roadY - 58),
      11,
      Paint()..color = const Color(0xFF1B270A),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(courierX, roadY - 60), radius: 11.5),
      math.pi,
      math.pi,
      true,
      bodyPaint,
    );

    // Paket makanan bergerak dari meja merchant ke tangan kurir
    final pkgT = Curves.easeInOut.transform(
      (progress < 0.5 ? progress * 2 : (1 - (progress - 0.5) * 0.25)),
    );
    final pkgX = (centerX - 24) + (courierX - (centerX - 24) - 16) * pkgT;
    final pkgY = roadY - 30 - lift;

    // Tangan kurir menggapai paket
    canvas.drawLine(
      Offset(courierX - 8, roadY - 41),
      Offset(pkgX + 8, pkgY + 2),
      Paint()
        ..color = const Color(0xFF1F2A10)
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round,
    );

    _drawFoodPackage(canvas, Offset(pkgX, pkgY), scale: 1.05);
  }

  void _paintDeliverToCustomer(Canvas canvas, Size size, double roadY) {
    final w = size.width;
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2);

    // Merchant di kiri & pin tempat pemesan di kanan
    _drawMerchantStore(canvas, Offset(48, roadY - 6), 0.2);
    final customerX = w - 58.0;
    _drawCustomerPin(canvas, Offset(customerX, roadY - 6), pulse);

    // Motor pembawa paket makanan melaju ke tempat pemesan
    final t = Curves.easeInOut.transform(progress);
    final motoX = 96.0 + (customerX - 156.0) * t;
    final bounce = math.sin(progress * math.pi * 10) * 1.8;

    _drawMotorcycleRider(
      canvas,
      Offset(motoX, roadY - 6 + bounce),
      hasFoodBox: true,
      wheelSpin: progress * math.pi * 8,
    );
  }

  void _paintArrivedAtCustomer(Canvas canvas, Size size, double roadY) {
    final centerX = size.width * 0.5;
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2);

    _drawCustomerPin(canvas, Offset(centerX - 28, roadY - 6), pulse);
    _drawFoodPackage(canvas, Offset(centerX + 26, roadY - 18), scale: 1.15);

    // Centang bersih tanpa kotak berlebihan
    final checkCenter = Offset(centerX + 26, roadY - 56);
    canvas.drawCircle(
      checkCenter,
      15 + pulse * 2.5,
      Paint()..color = const Color(0xFF16A34A).withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      checkCenter,
      12,
      Paint()..color = const Color(0xFF16A34A),
    );
    final checkPath = Path()
      ..moveTo(checkCenter.dx - 5, checkCenter.dy + 0.5)
      ..lineTo(checkCenter.dx - 1, checkCenter.dy + 4.5)
      ..lineTo(checkCenter.dx + 6, checkCenter.dy - 4);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintCancelled(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    canvas.drawCircle(
      center,
      26,
      Paint()..color = Colors.redAccent.withValues(alpha: 0.16),
    );
    final p = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - 10, center.dy - 10),
      Offset(center.dx + 10, center.dy + 10),
      p,
    );
    canvas.drawLine(
      Offset(center.dx + 10, center.dy - 10),
      Offset(center.dx - 10, center.dy + 10),
      p,
    );
  }

  void _drawMerchantStore(Canvas canvas, Offset bottomCenter, double pulse) {
    final x = bottomCenter.dx;
    final y = bottomCenter.dy;

    // Halo halus
    canvas.drawCircle(
      Offset(x, y - 34),
      28 + pulse * 6,
      Paint()..color = _kFoodAccent.withValues(alpha: 0.14),
    );

    // Dinding toko
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 24, y - 42, x + 24, y),
        const Radius.circular(8),
      ),
      Paint()..color = isDark ? const Color(0xFF2D3A1F) : Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 24, y - 42, x + 24, y),
        const Radius.circular(8),
      ),
      Paint()
        ..color = _kFoodAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Kanopi warung
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 28, y - 50, x + 28, y - 36),
        const Radius.circular(6),
      ),
      Paint()..color = _kFoodAccent,
    );

    // Jendela / pintu toko
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 10, y - 24, x + 10, y),
        const Radius.circular(4),
      ),
      Paint()..color = _kPrimary.withValues(alpha: 0.85),
    );
  }

  void _drawCustomerPin(Canvas canvas, Offset bottomCenter, double pulse) {
    final x = bottomCenter.dx;
    final y = bottomCenter.dy;

    canvas.drawCircle(
      Offset(x, y - 28),
      24 + pulse * 7,
      Paint()..color = _kPrimary.withValues(alpha: 0.2),
    );

    // Rumah / lokasi tujuan pemesan
    final housePaint = Paint()..color = _kPrimary;
    final roof = Path()
      ..moveTo(x, y - 52)
      ..lineTo(x + 22, y - 32)
      ..lineTo(x - 22, y - 32)
      ..close();
    canvas.drawPath(roof, housePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 16, y - 33, x + 16, y),
        const Radius.circular(5),
      ),
      Paint()..color = isDark ? const Color(0xFF2E3B1F) : Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 6, y - 19, x + 6, y),
        const Radius.circular(3),
      ),
      Paint()..color = _kPrimaryDeep,
    );
  }

  void _drawFoodPackage(Canvas canvas, Offset center, {double scale = 1.0}) {
    final w = 24 * scale;
    final h = 22 * scale;
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(5 * scale)),
      Paint()..color = _kFoodAccent,
    );
    // Pita segel lime GasKampus
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 2 * scale),
        width: w,
        height: 4 * scale,
      ),
      Paint()..color = _kPrimary,
    );
  }

  void _drawMotorcycleRider(
    Canvas canvas,
    Offset pos, {
    required bool hasFoodBox,
    required double wheelSpin,
  }) {
    final x = pos.dx;
    final y = pos.dy;

    // Roda depan & belakang
    for (final wx in [x - 16, x + 16]) {
      canvas.drawCircle(
        Offset(wx, y - 9),
        9,
        Paint()..color = const Color(0xFF151C0A),
      );
      canvas.drawCircle(
        Offset(wx, y - 9),
        4.2,
        Paint()..color = _kPrimary,
      );
      canvas.drawLine(
        Offset(wx, y - 9),
        Offset(wx + math.cos(wheelSpin) * 6, y - 9 + math.sin(wheelSpin) * 6),
        Paint()
          ..color = Colors.white70
          ..strokeWidth = 1.4,
      );
    }

    // Rangka motor
    final body = Path()
      ..moveTo(x - 18, y - 12)
      ..lineTo(x + 14, y - 12)
      ..lineTo(x + 20, y - 24)
      ..lineTo(x + 9, y - 26)
      ..lineTo(x + 4, y - 17)
      ..lineTo(x - 13, y - 18)
      ..close();
    canvas.drawPath(body, Paint()..color = _kPrimary);

    // Box makanan di belakang motor saat mengantar
    if (hasFoodBox) {
      _drawFoodPackage(canvas, Offset(x - 15, y - 26), scale: 0.72);
    }

    // Pengemudi & helm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x - 1, y - 29), width: 13, height: 18),
        const Radius.circular(6),
      ),
      Paint()..color = isDark ? Colors.white : const Color(0xFF19220A),
    );
    canvas.drawCircle(
      Offset(x + 1, y - 43),
      7.5,
      Paint()..color = _kPrimary,
    );
    // Visor
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2, y - 46, 6.5, 4.5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF0E1405),
    );
  }

  @override
  bool shouldRepaint(covariant _FoodDeliveryStagePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.isDark != isDark;
  }
}
