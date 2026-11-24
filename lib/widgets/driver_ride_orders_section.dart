import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../screens/main_pages/service_order_screen.dart';
import '../services/merchant_service.dart';
import '../services/ride_dispatch_service.dart';

const Color _kPrimary = Color(0xFFC0F637);
const Color _kPrimaryDeep = Color(0xFF7EB50F);

/// Wrapper pendengar real-time yang dipasang di root `DriverHomeScreen` dan
/// `DriverUmumHomeScreen`. Begitu ada pesanan antar masuk yang cocok (termasuk
/// dari laptop/perangkat mahasiswa lain), langsung memunculkan **popup notifikasi
/// penerimaan pesanan** (Setuju & Jemput / Tolak) di layar driver, bahkan jika
/// driver sedang berada di tab lain atau belum scroll ke bawah.
class DriverIncomingOrderListener extends StatefulWidget {
  final bool isOnline;
  final String driverName;
  final String driverRole; // 'driver_kampus' | 'driver_umum'
  final String vehicleBrand;
  final String vehiclePlate;
  final LatLng driverPosition;
  final VoidCallback? onOrderAccepted;
  final Widget child;

  const DriverIncomingOrderListener({
    super.key,
    required this.isOnline,
    required this.driverName,
    required this.driverRole,
    required this.vehicleBrand,
    required this.vehiclePlate,
    required this.driverPosition,
    this.onOrderAccepted,
    required this.child,
  });

  @override
  State<DriverIncomingOrderListener> createState() =>
      _DriverIncomingOrderListenerState();
}

class _DriverIncomingOrderListenerState
    extends State<DriverIncomingOrderListener> {
  final RideDispatchService _dispatch = RideDispatchService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Timer? _recheckTimer;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _latestDocs = const [];

  final Set<String> _alertedOrderIds = {};
  String? _openDialogOrderId;
  BuildContext? _dialogCtx;

  @override
  void initState() {
    super.initState();
    _sub = _dispatch.streamRideOrders().listen((snap) {
      _latestDocs = snap.docs;
      _evaluateIncomingOffers();
    });
    // Periksa ulang tiap 3 detik agar order yang baru melewati timeout 15 detik
    // langsung memunculkan notifikasi popup ke driver aktif ini.
    _recheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _evaluateIncomingOffers(),
    );
  }

  @override
  void didUpdateWidget(covariant DriverIncomingOrderListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && !oldWidget.isOnline) {
      _evaluateIncomingOffers();
    }
  }

  @override
  void dispose() {
    _recheckTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _evaluateIncomingOffers() {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    // Jika dialog sedang terbuka tetapi pesanan sudah diambil driver lain / batal -> tutup otomatis
    if (_openDialogOrderId != null) {
      final match = _latestDocs.where((d) => d.id == _openDialogOrderId);
      final stillOpen = match.isNotEmpty &&
          RideDispatchService.isOfferOpenForDriver(match.first.data(), uid);
      if (!stillOpen && _dialogCtx != null && _dialogCtx!.mounted) {
        Navigator.of(_dialogCtx!).pop();
      }
      return;
    }

    if (!widget.isOnline) return;

    // Jangan tampilkan popup baru jika driver sedang membawa order aktif
    final hasActiveTrip = _latestDocs.any((d) {
      final data = d.data();
      final st = (data['status'] ?? '').toString();
      return (data['driverId'] ?? '').toString() == uid &&
          (st == 'accepted' ||
              st == 'onPickup' ||
              st == 'arrived' ||
              st == 'onTrip');
    });
    if (hasActiveTrip) return;

    final eligible = _latestDocs
        .where((d) => RideDispatchService.isOfferOpenForDriver(d.data(), uid))
        .toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a.data()['createdAt']?.toString() ?? '');
        final db = DateTime.tryParse(b.data()['createdAt']?.toString() ?? '');
        return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
      });

    for (final doc in eligible) {
      if (_alertedOrderIds.contains(doc.id)) continue;
      _alertedOrderIds.add(doc.id);
      _showIncomingOrderDialog(doc, uid);
      break;
    }
  }

  Future<void> _showIncomingOrderDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String uid,
  ) async {
    if (!mounted) return;
    final data = doc.data();
    final passengerName = (data['passengerName'] ?? 'Mahasiswa').toString();
    final pickup = (data['originAddress'] ?? '-').toString();
    final dest = (data['destinationAddress'] ?? '-').toString();
    final items = (data['items'] ?? 'Layanan Antar').toString();
    final fare = (data['fareAmount'] as num?)?.toInt() ?? 0;
    final method = (data['paymentMethod'] ?? 'GasPay').toString();
    final tierLabel =
        (data['dispatchTierLabel'] ?? 'Orderan Antar Masuk').toString();

    HapticFeedback.heavyImpact();
    AppNotificationStore.add(
      title: 'Orderan Antar Masuk!',
      message: '$passengerName · $pickup → $dest (${MerchantService.formatRupiah(fare)})',
      icon: Icons.two_wheeler_rounded,
      color: _kPrimaryDeep,
    );

    _openDialogOrderId = doc.id;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        _dialogCtx = ctx;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF171E0F) : Colors.white;
        final tp = isDark ? Colors.white : const Color(0xFF0F172A);
        final ts = isDark ? const Color(0xFF94A87B) : const Color(0xFF64748B);
        final border =
            isDark ? const Color(0xFF2B371C) : const Color(0xFFE2E8F0);

        return StatefulBuilder(
          builder: (dCtx, setDlg) {
            return Dialog(
              backgroundColor: cardBg,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: _kPrimary, width: 1.8),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: _kPrimaryDeep,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Orderan Antar Masuk!',
                            style: TextStyle(
                              color: tp,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          MerchantService.formatRupiah(fare),
                          style: TextStyle(
                            color: tp,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$tierLabel · $method',
                      style: const TextStyle(
                        color: _kPrimaryDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(color: border, height: 1),
                    const SizedBox(height: 12),
                    Text(
                      '$passengerName · $items',
                      style: TextStyle(
                        color: tp,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _popupLocRow(
                      Icons.my_location_rounded,
                      _kPrimaryDeep,
                      'Jemput',
                      pickup,
                      tp,
                    ),
                    const SizedBox(height: 8),
                    _popupLocRow(
                      Icons.location_on_rounded,
                      const Color(0xFFEF4444),
                      'Tujuan',
                      dest,
                      tp,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    setDlg(() => submitting = true);
                                    try {
                                      await _dispatch.declineRideOrder(
                                        orderId: doc.id,
                                        driverId: uid,
                                      );
                                    } finally {
                                      if (dCtx.mounted) Navigator.pop(dCtx);
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Tolak',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: submitting
                                ? null
                                : () async {
                                    setDlg(() => submitting = true);
                                    bool ok = false;
                                    try {
                                      ok = await _dispatch.acceptRideOrder(
                                        orderId: doc.id,
                                        driverId: uid,
                                        driverName: widget.driverName,
                                        driverRole: widget.driverRole,
                                        vehicleBrand: widget.vehicleBrand,
                                        vehiclePlate: widget.vehiclePlate,
                                        driverPos: widget.driverPosition,
                                      );
                                    } finally {
                                      if (dCtx.mounted) Navigator.pop(dCtx);
                                    }
                                    if (ok) {
                                      widget.onOrderAccepted?.call();
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          backgroundColor:
                                              const Color(0xFF1E293B),
                                          content: const Text(
                                            'Order sudah diambil oleh driver lain.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: const Color(0xFF0A0F02),
                              elevation: 0,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                              submitting ? 'Memproses...' : 'Setuju & Jemput',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Tutup jendela ini jika ingin melihatnya di daftar order.',
                        style: TextStyle(color: ts, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    _openDialogOrderId = null;
    _dialogCtx = null;
  }

  Widget _popupLocRow(
    IconData icon,
    Color iconColor,
    String label,
    String addr,
    Color tp,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $addr',
            style: TextStyle(
              color: tp,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Panel orderan antar (GasRide / GasCar) real-time tanpa data dummy
/// untuk Driver Mahasiswa (`driver_kampus`) & Driver Umum (`driver_umum`).
/// - Menampilkan order yang ditawarkan ke driver ini (atau order terbuka saat tidak ada driver dekat / timeout 15s).
/// - Menyediakan sistem **Setuju** dan **Tolak**.
/// - Jika **Setuju**: Driver menjemput dulu (`onPickup` -> `arrived`), lalu mengantar ke tujuan (`onTrip` -> `completed`).
class DriverRideOrdersSection extends StatefulWidget {
  final bool isOnline;
  final String driverName;
  final String driverRole; // 'driver_kampus' | 'driver_umum'
  final String vehicleBrand;
  final String vehiclePlate;
  final LatLng driverPosition;

  const DriverRideOrdersSection({
    super.key,
    required this.isOnline,
    required this.driverName,
    required this.driverRole,
    required this.vehicleBrand,
    required this.vehiclePlate,
    required this.driverPosition,
  });

  @override
  State<DriverRideOrdersSection> createState() =>
      _DriverRideOrdersSectionState();
}

class _DriverRideOrdersSectionState extends State<DriverRideOrdersSection> {
  final RideDispatchService _dispatch = RideDispatchService();
  final Set<String> _busyIds = {};
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    // Refresh tampilan tiap 4 detik agar order yang baru melewati timeout 15s otomatis tampil
    _tickTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _runAction(String orderId, Future<void> Function() task) async {
    if (_busyIds.contains(orderId)) return;
    setState(() => _busyIds.add(orderId));
    try {
      await task();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: const Color(0xFF1E293B),
            content: Text('Gagal memproses order: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);
    final tp = isDark ? Colors.white : const Color(0xFF0F172A);
    final ts = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _dispatch.streamRideOrders(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        // 1. Order aktif yang sedang dijalankan oleh driver ini
        final myActiveTrips = docs.where((d) {
          final data = d.data();
          final st = (data['status'] ?? '').toString();
          return (data['driverId'] ?? '').toString() == uid &&
              (st == 'accepted' ||
                  st == 'onPickup' ||
                  st == 'arrived' ||
                  st == 'onTrip');
        }).toList();

        // 2. Tawaran order baru (hanya jika driver sedang online & tidak sedang membawa order)
        final incomingOffers = (!widget.isOnline || myActiveTrips.isNotEmpty)
            ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
            : docs
                .where(
                  (d) => RideDispatchService.isOfferOpenForDriver(d.data(), uid),
                )
                .toList()
          ..sort((a, b) {
            final da = DateTime.tryParse(a.data()['createdAt']?.toString() ?? '');
            final db = DateTime.tryParse(b.data()['createdAt']?.toString() ?? '');
            return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
          });

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: _kPrimaryDeep, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      myActiveTrips.isNotEmpty
                          ? 'Perjalanan Antar Aktif'
                          : 'Orderan Antar Masuk (${incomingOffers.length})',
                      style: TextStyle(
                        color: tp,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (myActiveTrips.isNotEmpty)
                for (final doc in myActiveTrips)
                  _buildActiveTripCard(
                    doc: doc,
                    uid: uid,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    tp: tp,
                    ts: ts,
                  )
              else if (!widget.isOnline)
                _buildEmptyBox(
                  cardBg: cardBg,
                  borderColor: borderColor,
                  tp: tp,
                  ts: ts,
                  icon: Icons.bedtime_outlined,
                  title: 'Mode Istirahat',
                  subtitle:
                      'Aktifkan "Mode: Siap Narik" agar orderan antar terdekat bisa masuk ke akunmu.',
                )
              else if (incomingOffers.isEmpty)
                _buildEmptyBox(
                  cardBg: cardBg,
                  borderColor: borderColor,
                  tp: tp,
                  ts: ts,
                  icon: Icons.radar_rounded,
                  title: 'Menunggu Orderan Masuk',
                  subtitle:
                      'Lokasi & status aktifmu sudah online. Orderan antar terdekat akan langsung tampil & muncul notifikasi di sini.',
                )
              else
                for (final doc in incomingOffers)
                  _buildIncomingOfferCard(
                    doc: doc,
                    uid: uid,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    tp: tp,
                    ts: ts,
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomingOfferCard({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String uid,
    required Color cardBg,
    required Color borderColor,
    required Color tp,
    required Color ts,
  }) {
    final data = doc.data();
    final passengerName = (data['passengerName'] ?? 'Mahasiswa').toString();
    final pickup = (data['originAddress'] ?? '-').toString();
    final dest = (data['destinationAddress'] ?? '-').toString();
    final items = (data['items'] ?? 'GasRide').toString();
    final fare = (data['fareAmount'] as num?)?.toInt() ?? 0;
    final method = (data['paymentMethod'] ?? 'GasPay').toString();
    final tierLabel =
        (data['dispatchTierLabel'] ?? 'Order Masuk Driver Aktif').toString();
    final distKm = (data['offeredDistanceKm'] as num?)?.toDouble();
    final busy = _busyIds.contains(doc.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kPrimary, width: 1.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  distKm != null
                      ? '$tierLabel · ${distKm.toStringAsFixed(1)} km'
                      : tierLabel,
                  style: const TextStyle(
                    color: _kPrimaryDeep,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                MerchantService.formatRupiah(fare),
                style: TextStyle(
                  color: tp,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$passengerName · $items',
            style: TextStyle(
              color: tp,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _locRow(
            Icons.my_location_rounded,
            _kPrimaryDeep,
            'Jemput',
            pickup,
            tp,
            ts,
          ),
          const SizedBox(height: 6),
          _locRow(
            Icons.location_on_rounded,
            const Color(0xFFEF4444),
            'Tujuan',
            dest,
            tp,
            ts,
          ),
          const SizedBox(height: 8),
          Text(
            'Pembayaran: $method',
            style: TextStyle(
              color: ts,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _runAction(
                            doc.id,
                            () => _dispatch.declineRideOrder(
                              orderId: doc.id,
                              driverId: uid,
                            ),
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text(
                    'Tolak',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: busy
                      ? null
                      : () => _runAction(doc.id, () async {
                            final ok = await _dispatch.acceptRideOrder(
                              orderId: doc.id,
                              driverId: uid,
                              driverName: widget.driverName,
                              driverRole: widget.driverRole,
                              vehicleBrand: widget.vehicleBrand,
                              vehiclePlate: widget.vehiclePlate,
                              driverPos: widget.driverPosition,
                            );
                            if (!ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: const Color(0xFF1E293B),
                                  content: const Text(
                                    'Order sudah diambil oleh driver lain.',
                                  ),
                                ),
                              );
                            }
                          }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: const Color(0xFF0A0F02),
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    busy ? 'Memproses...' : 'Setuju & Jemput',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripCard({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String uid,
    required Color cardBg,
    required Color borderColor,
    required Color tp,
    required Color ts,
  }) {
    final data = doc.data();
    final status = (data['status'] ?? 'onPickup').toString();
    final passengerName = (data['passengerName'] ?? 'Mahasiswa').toString();
    final pickup = (data['originAddress'] ?? '-').toString();
    final dest = (data['destinationAddress'] ?? '-').toString();
    final fare = (data['fareAmount'] as num?)?.toInt() ?? 0;
    final method = (data['paymentMethod'] ?? 'GasPay').toString();
    final busy = _busyIds.contains(doc.id);

    final stageText = switch (status) {
      'accepted' || 'onPickup' => 'Tahap 1: Menjemput Penumpang',
      'arrived' => 'Tahap 2: Sudah Tiba di Titik Jemput',
      'onTrip' => 'Tahap 3: Mengantar ke Tujuan',
      _ => status,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kPrimary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stageText,
                  style: const TextStyle(
                    color: _kPrimaryDeep,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                MerchantService.formatRupiah(fare),
                style: TextStyle(
                  color: tp,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            passengerName,
            style: TextStyle(
              color: tp,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _locRow(
            Icons.my_location_rounded,
            _kPrimaryDeep,
            'Jemput',
            pickup,
            tp,
            ts,
          ),
          const SizedBox(height: 6),
          _locRow(
            Icons.location_on_rounded,
            const Color(0xFFEF4444),
            'Tujuan',
            dest,
            tp,
            ts,
          ),
          const SizedBox(height: 8),
          Text(
            'Pembayaran: $method',
            style: TextStyle(
              color: ts,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (status == 'accepted' || status == 'onPickup')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy
                    ? null
                    : () => _runAction(
                          doc.id,
                          () => _dispatch.markArrivedAtPickup(doc.id),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: const Color(0xFF0A0F02),
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.location_on_rounded, size: 18),
                label: Text(
                  busy ? 'Memproses...' : 'Saya Sudah Tiba di Titik Jemput',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (status == 'arrived')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy
                    ? null
                    : () => _runAction(
                          doc.id,
                          () => _dispatch.startRideToDestination(doc.id),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: const Color(0xFF0A0F02),
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                label: Text(
                  busy ? 'Memproses...' : 'Mulai Antar ke Tujuan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (status == 'onTrip')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy
                    ? null
                    : () => _runAction(
                          doc.id,
                          () => _dispatch.completeRideOrder(
                            orderId: doc.id,
                            driverId: uid,
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  busy ? 'Memproses...' : 'Selesai · Sudah Sampai Tujuan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox({
    required Color cardBg,
    required Color borderColor,
    required Color tp,
    required Color ts,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kPrimaryDeep, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tp,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: ts, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locRow(
    IconData icon,
    Color iconColor,
    String label,
    String addr,
    Color tp,
    Color ts,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $addr',
            style: TextStyle(
              color: tp,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
