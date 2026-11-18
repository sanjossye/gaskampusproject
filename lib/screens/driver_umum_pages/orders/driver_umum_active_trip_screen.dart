import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_umum_trip_complete_screen.dart';
import '../../../services/trip_service.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kCampusDark = Color(0xFF1D2210);

class DriverUmumActiveTripScreen extends StatefulWidget {
  final String orderId;
  final String passengerName;
  final String passengerRole;
  final int fareAmount;
  final String dropoffAddress;
  final String paymentMethod;
  final String zone;

  const DriverUmumActiveTripScreen({
    super.key,
    this.orderId = 'order_live_01',
    this.passengerName = 'Andi Pratama',
    this.passengerRole = 'Mahasiswa · Fak. Teknik',
    this.fareAmount = 15000,
    this.dropoffAddress = 'Gedung C - Zona B (Fakultas Teknik)',
    this.paymentMethod = 'GasPay',
    this.zone = 'Zona B',
  });

  @override
  State<DriverUmumActiveTripScreen> createState() => _DriverUmumActiveTripScreenState();
}

class _DriverUmumActiveTripScreenState extends State<DriverUmumActiveTripScreen> with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openGoogleMaps() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membuka rute Google Maps menuju: ${widget.dropoffAddress}'),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Tombol Darurat (SOS)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Gunakan jika terjadi ancaman keamanan, kecelakaan, atau kondisi darurat di area kampus.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text('• Telepon Satpam Kampus: 021-7863456', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('• Layanan Darurat Polisi: 110', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('• Lapor Insiden Langsung ke Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sinyal SOS dan titik koordinat telah dikirim ke Pos Satpam Kampus!'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Kirim Sinyal Darurat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompleteTrip() async {
    setState(() => _isCompleting = true);
    final user = FirebaseAuth.instance.currentUser;
    final driverId = user?.uid ?? 'driveru_demo';

    try {
      // README Bagian 10: Eksekusi Keuangan & Bagi Hasil di Cloud Firestore
      final result = await _tripService.completeTripAndProcessFinancials(
        orderId: widget.orderId,
        driverId: driverId,
        fareAmount: widget.fareAmount,
        paymentMethod: widget.paymentMethod,
      );

      if (!mounted) return;

      final bool isCash = result['isCash'] as bool;
      final int commission = result['commission'] as int;
      final int netEarnings = result['netEarnings'] as int;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCash
                ? 'Trip Selesai! Terima Tunai Rp ${widget.fareAmount}. Komisi 15% (Rp $commission) dipotong dari saldo GasPay.'
                : 'Trip Selesai! Pendapatan bersih Rp $netEarnings telah masuk ke saldo GasPay kamu.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverUmumTripCompleteScreen(
            orderId: widget.orderId,
            passengerName: widget.passengerName,
            passengerRole: widget.passengerRole,
            fareAmount: widget.fareAmount,
            dropoffAddress: widget.dropoffAddress,
            paymentMethod: widget.paymentMethod,
            zone: widget.zone,
            commission: commission,
            netEarnings: netEarnings,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyelesaikan trip: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // 1. Map Background (Simulated)
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&q=80&w=1000',
              fit: BoxFit.cover,
            ),
          ),

          // 1.1 Current Location Dot (Driver)
          Align(
            alignment: const Alignment(0.1, 0.1),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.5),
                        blurRadius: 10 * _pulseAnimation.value,
                        spreadRadius: 5 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 1.2 Drop-off Destination Marker
          Align(
            alignment: const Alignment(0.6, -0.4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Text(
                    widget.zone,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),

          // 2. Top Navigation Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopNavButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.two_wheeler, color: Colors.green, size: 16),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Perjalanan Aktif',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol SOS Satpam
                      GestureDetector(
                        onTap: _showSosDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.warning, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildTopNavButton(
                        icon: Icons.map_outlined,
                        onTap: _openGoogleMaps,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Navigation Info Card (Bottom Sheet)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Destination and ETA
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.navigation, color: Colors.black87, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menuju Lokasi Tujuan (${widget.zone})',
                              style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.dropoffAddress,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tarif: Rp ${widget.fareAmount} · ${widget.paymentMethod}',
                              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('6 min', style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.w900)),
                          Text('ESTIMASI', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Passenger Info & Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.black87, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.passengerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text(widget.passengerRole, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildCircleAction(
                            icon: Icons.chat_bubble_outline,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Membuka chat penumpang...'), behavior: SnackBarBehavior.floating),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildCircleAction(
                            icon: Icons.phone_outlined,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Menghubungi telepon penumpang...'), behavior: SnackBarBehavior.floating),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Selesaikan Perjalanan Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.black,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isCompleting ? null : _handleCompleteTrip,
                      child: _isCompleting
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Selesaikan Perjalanan (Tiba di Tujuan)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildTopNavButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }

  Widget _buildCircleAction({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, color: Colors.black87, size: 18),
      ),
    );
  }
}
