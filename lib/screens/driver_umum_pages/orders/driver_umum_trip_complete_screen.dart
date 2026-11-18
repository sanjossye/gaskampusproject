import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_umum_receipt_screen.dart';
import '../../../services/trip_service.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kCampusDark = Color(0xFF1D2210);

class DriverUmumTripCompleteScreen extends StatefulWidget {
  final String orderId;
  final String passengerName;
  final String passengerRole;
  final int fareAmount;
  final String dropoffAddress;
  final String paymentMethod;
  final String zone;
  final int commission;
  final int netEarnings;

  const DriverUmumTripCompleteScreen({
    super.key,
    this.orderId = 'order_live_01',
    this.passengerName = 'Andi Pratama',
    this.passengerRole = 'Mahasiswa · Fak. Teknik USU',
    this.fareAmount = 15000,
    this.dropoffAddress = 'Gedung C - Zona B (Fakultas Teknik USU)',
    this.paymentMethod = 'GasPay',
    this.zone = 'Zona B',
    this.commission = 2250,
    this.netEarnings = 12750,
  });

  @override
  State<DriverUmumTripCompleteScreen> createState() => _DriverUmumTripCompleteScreenState();
}

class _DriverUmumTripCompleteScreenState extends State<DriverUmumTripCompleteScreen> with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _rating = 5;
  final Set<String> _selectedTags = {'Tepat Waktu', 'Ramah & Sopan'};

  final List<String> _availableTags = [
    'Titik Jemput Sesuai',
    'Tepat Waktu',
    'Ramah & Sopan',
    'Pembayaran Lancar',
    'Komunikatif',
  ];

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

  Future<void> _handleSubmitRatingAndReceipt() async {
    final user = FirebaseAuth.instance.currentUser;
    final driverId = user?.uid ?? 'driveru_demo';

    try {
      // README Bagian 11: Rating 2 Arah setelah completed
      await _tripService.submitPassengerReview(
        orderId: widget.orderId,
        driverId: driverId,
        passengerName: widget.passengerName,
        rating: _rating.toDouble(),
        tags: _selectedTags.toList(),
      );
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DriverUmumReceiptScreen(
          orderId: widget.orderId,
          passengerName: widget.passengerName,
          passengerRole: widget.passengerRole,
          fareAmount: widget.fareAmount,
          dropoffAddress: widget.dropoffAddress,
          paymentMethod: widget.paymentMethod,
          zone: widget.zone,
          commission: widget.commission,
          netEarnings: widget.netEarnings,
        ),
      ),
    );
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

          // 1.1 Map Blur Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),

          // 1.2 Arrival Marker
          Align(
            alignment: const Alignment(0.6, -0.4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 48 * _pulseAnimation.value,
                      height: 48 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 24),
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
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Perjalanan Selesai',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // 3. Complete Info & Rating Sheet
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

                  // Header Success
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Penumpang Tiba dengan Selamat',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              '${widget.dropoffAddress} (${widget.zone})',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Financial summary card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PENDAPATAN BERSIH (85%)',
                              style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${widget.netEarnings}',
                              style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Metode: ${widget.paymentMethod}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rating Section (README Bagian 11: Rating 2 Arah Wajib)
                  Column(
                    children: [
                      Text(
                        'Beri Penilaian untuk ${widget.passengerName}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setState(() => _rating = index + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                index < _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),

                      // Quick Tag Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _availableTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.black87)),
                            selected: isSelected,
                            selectedColor: kPrimary,
                            backgroundColor: Colors.grey[100],
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Button
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
                      onPressed: _handleSubmitRatingAndReceipt,
                      child: const Text(
                        'Kirim Penilaian & Lihat Struk Rincian',
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
}
