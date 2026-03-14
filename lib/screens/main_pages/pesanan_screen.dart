import 'package:flutter/material.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color kPrimary       = Color(0xFFC0F637);
const Color kSecondaryGreen = Color(0xFF68cd5c);
const Color kBgDark        = Color(0xFF1D2210);
const Color kBgLight       = Color(0xFFF7F8F5);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

class PesananScreen extends StatelessWidget {
  const PesananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final cardColor = isDark ? const Color(0xFF181E10) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: Stack(
        children: [
          // ── 1. Map Background ──
          Positioned.fill(
            child: Container(
              color: isDark ? Colors.black87 : Colors.grey[200],
              child: Image.network(
                'https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', // Placeholder map texture
                fit: BoxFit.cover,
                color: isDark ? Colors.black54 : Colors.white24,
                colorBlendMode: isDark ? BlendMode.darken : BlendMode.lighten,
              ),
            ),
          ),
          
          // Map Marker Placeholder
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

          // ── 2. Top Navigation Overlay ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
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
                  _buildFloatingIcon(Icons.arrow_back_rounded, isDark, onTap: () {
                    // Tindakan default: kembali jika ini di-push, atau ganti nav index di parent
                  }),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? kCardColorDark : Colors.white,
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
                  _buildFloatingIcon(Icons.help_outline_rounded, isDark),
                ],
              ),
            ),
          ),

          // ── 3. Floating Map Controls ──
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.3,
            child: Column(
              children: [
                _buildFloatingIcon(Icons.add_rounded, isDark),
                const SizedBox(height: 8),
                _buildFloatingIcon(Icons.remove_rounded, isDark),
                const SizedBox(height: 8),
                _buildFloatingIcon(Icons.my_location_rounded, isDark, iconColor: kPrimary),
              ],
            ),
          ),

          // ── 4. Bottom Sheet Card (Realtime Status) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
                  // Drag Handle
                  Container(
                    width: 48,
                    height: 6,
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
                        // Status & Time
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

                        const SizedBox(height: 24),

                        // Driver Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF232A18) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: cardColor, width: 2),
                                        image: const DecorationImage(
                                          image: NetworkImage('https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2),
                                          ],
                                        ),
                                        child: const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Budi Santoso', style: _body(textColorPrimary, 16, FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        Icon(Icons.circle, size: 4, color: textColorSecondary),
                                        const SizedBox(width: 8),
                                        Text('4.9', style: _body(textColorPrimary, 14, FontWeight.w600)),
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
                              
                              // Actions
                              Row(
                                children: [
                                  _buildActionBtn(Icons.chat_bubble_outline_rounded, kSecondaryGreen, isDark),
                                  const SizedBox(width: 8),
                                  _buildActionBtn(Icons.call_outlined, kSecondaryGreen, isDark),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action Button (Bagikan Lokasi)
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
                                const Icon(Icons.share_location_rounded, color: Colors.black87),
                                const SizedBox(width: 8),
                                Text(
                                  'Bagikan Lokasi',
                                  style: _body(Colors.black87, 16, FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Safe area for bottom
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

  // Helper untuk Floating Icon Button
  Color get kCardColorDark => const Color(0xFF181E10);

  Widget _buildFloatingIcon(IconData icon, bool isDark, {Color? iconColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? kCardColorDark : Colors.white,
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

  // Helper untuk Chat / Call Button
  Widget _buildActionBtn(IconData icon, Color color, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
