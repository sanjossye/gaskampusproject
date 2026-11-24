import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/merchant_service.dart';

const Color _kPrimary = Color(0xFFC0F637);
const Color _kPrimaryDeep = Color(0xFF7EB50F);
const Color _kFoodAccent = Color(0xFFFF9F43);

/// Panel pesanan makanan GasMakan real-time untuk Driver Mahasiswa & Driver Umum.
/// Alur status:
/// 1. `pending`/`accepted`/`preparing` -> Driver klik `Menuju Merchant` (`going_to_merchant`)
/// 2. `going_to_merchant` -> Menunggu Merchant klik `Makanan Telah Diambil Driver` (`picked_up`)
/// 3. `picked_up` -> Driver klik `Antar ke Tempat Pemesan` (`onTrip`)
/// 4. `onTrip` -> Driver centang checkbox `Saya Sudah Sampai` (`completed`)
class DriverFoodOrdersSection extends StatefulWidget {
  final String driverName;

  const DriverFoodOrdersSection({
    super.key,
    required this.driverName,
  });

  @override
  State<DriverFoodOrdersSection> createState() =>
      _DriverFoodOrdersSectionState();
}

class _DriverFoodOrdersSectionState extends State<DriverFoodOrdersSection> {
  final MerchantService _merchantService = MerchantService();
  final Set<String> _busyIds = {};
  final Set<String> _checkedIds = {};

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
            content: Text('Gagal memperbarui status: $e'),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);
    final tp = isDark ? Colors.white : const Color(0xFF0F172A);
    final ts = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _merchantService.streamActiveFoodOrders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final activeDocs = snapshot.data!.docs.where((d) {
          final st = (d.data()['status'] ?? 'pending').toString();
          return st != 'completed' && st != 'cancelled';
        }).toList()
          ..sort((a, b) {
            final da = DateTime.tryParse(a.data()['createdAt']?.toString() ?? '');
            final db = DateTime.tryParse(b.data()['createdAt']?.toString() ?? '');
            return (db ?? DateTime.now()).compareTo(da ?? DateTime.now());
          });

        if (activeDocs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fastfood_rounded,
                    color: _kFoodAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pesanan Makanan Masuk (${activeDocs.length})',
                      style: TextStyle(
                        color: tp,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final doc in activeDocs)
                _buildFoodOrderCard(
                  doc: doc,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  tp: tp,
                  ts: ts,
                  isDark: isDark,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodOrderCard({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required Color cardBg,
    required Color borderColor,
    required Color tp,
    required Color ts,
    required bool isDark,
  }) {
    final data = doc.data();
    final status = (data['status'] ?? 'pending').toString();
    final merchantName = (data['merchantName'] ??
            data['originName'] ??
            'Merchant GasMakan')
        .toString();
    final originAddr = (data['originAddress'] ?? '').toString();
    final destAddr = (data['destinationAddress'] ?? '').toString();
    final items = (data['items'] ?? '').toString();
    final buyer = (data['passengerName'] ?? 'Mahasiswa').toString();
    final deliveryFare =
        (data['deliveryFare'] as num?)?.toInt() ??
        (data['fareAmount'] as num?)?.toInt() ??
        0;
    final paymentMethod = (data['paymentMethod'] ?? 'GasPay').toString();
    final isUnpaidCash =
        data['paymentStatus'] == 'unpaid' ||
        (paymentMethod.toLowerCase() == 'tunai' &&
            data['paymentStatus'] != 'paid');
    final busy = _busyIds.contains(doc.id);
    final isArrivedChecked = _checkedIds.contains(doc.id);

    final statusInfo = switch (status) {
      'going_to_merchant' => (
          label: 'Menuju Merchant',
          color: _kPrimaryDeep,
        ),
      'picked_up' => (
          label: 'Makanan Diambil',
          color: _kFoodAccent,
        ),
      'onTrip' => (
          label: 'Mengantar ke Pemesan',
          color: const Color(0xFF16A34A),
        ),
      _ => (
          label: 'Pesanan Baru',
          color: _kFoodAccent,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == 'picked_up' || status == 'onTrip'
              ? _kPrimary
              : borderColor,
          width: status == 'picked_up' || status == 'onTrip' ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchantName,
                      style: TextStyle(
                        color: tp,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pemesan: $buyer',
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
                statusInfo.label,
                style: TextStyle(
                  color: statusInfo.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              items,
              style: TextStyle(
                color: tp,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _addrRow(Icons.storefront_rounded, _kFoodAccent, originAddr, tp),
          const SizedBox(height: 4),
          _addrRow(Icons.location_on_rounded, _kPrimaryDeep, destAddr, tp),
          const SizedBox(height: 8),
          Text(
            'Ongkir / Tarif: ${MerchantService.formatRupiah(deliveryFare)} · ${isUnpaidCash ? '$paymentMethod (Belum Dibayar)' : '$paymentMethod (Lunas)'}',
            style: TextStyle(
              color: isUnpaidCash ? const Color(0xFFD97706) : ts,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (status == 'pending' ||
              status == 'accepted' ||
              status == 'preparing')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy
                    ? null
                    : () {
                        final uid =
                            FirebaseAuth.instance.currentUser?.uid ?? 'driver';
                        _runAction(
                          doc.id,
                          () => _merchantService.acceptFoodOrderToMerchant(
                            orderId: doc.id,
                            driverId: uid,
                            driverName: widget.driverName,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: const Color(0xFF0A0F02),
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                label: Text(
                  busy ? 'Memproses...' : 'Menuju Merchant',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (status == 'going_to_merchant')
            Text(
              'Sedang menuju toko merchant. Menunggu merchant klik "Makanan Telah Diambil Driver".',
              style: TextStyle(
                color: ts,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (status == 'picked_up')
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Merchant menandai makanan telah diambil. Antar sekarang ke tempat pemesan.',
                  style: TextStyle(
                    color: _kFoodAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: busy
                      ? null
                      : () => _runAction(
                            doc.id,
                            () => _merchantService
                                .startFoodDeliveryToCustomer(doc.id),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: const Color(0xFF0A0F02),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.delivery_dining_rounded, size: 18),
                  label: Text(
                    busy ? 'Memproses...' : 'Antar ke Tempat Pemesan',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          else if (status == 'onTrip')
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF15200B)
                    : const Color(0xFFF3FAE4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.7),
                ),
              ),
              child: CheckboxListTile(
                value: isArrivedChecked,
                activeColor: const Color(0xFF16A34A),
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                title: Text(
                  'Saya Sudah Sampai',
                  style: TextStyle(
                    color: tp,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  'Centang jika pesanan sudah diserahkan ke pemesan',
                  style: TextStyle(color: ts, fontSize: 11.5),
                ),
                onChanged: busy
                    ? null
                    : (val) {
                        if (val != true) return;
                        setState(() => _checkedIds.add(doc.id));
                        _runAction(
                          doc.id,
                          () => _merchantService
                              .confirmFoodArrivedByDriver(doc.id),
                        );
                      },
              ),
            ),
        ],
      ),
    );
  }

  Widget _addrRow(IconData icon, Color color, String text, Color tp) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: tp,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
