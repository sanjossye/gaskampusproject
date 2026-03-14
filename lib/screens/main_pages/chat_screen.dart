import 'package:flutter/material.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color kPrimary       = Color(0xFFC0F637);
const Color kBgDark        = Color(0xFF1D2210);
const Color kBgLight       = Color(0xFFF7F8F5);
const Color kSurfaceDark   = Color(0xFF1E293B);
const Color kSurfaceLight  = Color(0xFFFFFFFF);
const Color kBorderDark    = Color(0xFF334155);
const Color kBorderLight   = Color(0xFFE2E8F0);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tp     = isDark ? Colors.white : const Color(0xFF0F172A);
    final ts     = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bg     = isDark ? kBgDark : kBgLight;
    final card   = isDark ? const Color(0xFF111827) : kSurfaceLight; // Header bg
    final border = isDark ? const Color(0xFF1E293B) : kBorderLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context, tp, ts, card, border, isDark),
      body: Column(
        children: [
          // ── Ruang Chat Utama ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSystemStatus('Today', isDark),
                const SizedBox(height: 24),
                _buildDriverMessage('Halo kak, saya sudah di depan gedung Perpustakaan ya. Pakai motor Beat Putih.', '10:15 AM', tp, isDark),
                const SizedBox(height: 24),
                _buildUserMessage('Oke Pak Budi, sebentar ya saya baru keluar kelas.', '10:16 AM • Read'),
                const SizedBox(height: 24),
                _buildDriverMessage('Siap kak, ditunggu. Saya parkir di dekat pos satpam.', '10:17 AM', tp, isDark),
                const SizedBox(height: 8),
                _buildLocationCard(tp, ts, border, isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // ── Quick Replies & Input Field ──
          _buildFooter(tp, ts, card, border, isDark),
        ],
      ),
    );
  }

  // 1. App Bar
  PreferredSizeWidget _buildAppBar(BuildContext context, Color tp, Color ts, Color card, Color border, bool isDark) {
    return AppBar(
      backgroundColor: card,
      elevation: 0,
      scrolledUnderElevation: 1, // Subtler shadow when scrolling
      shadowColor: Colors.black.withOpacity(0.1),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: border, height: 1.0),
      ),
      leadingWidth: 48,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ts),
          onPressed: () {}, // Akan dihandle oleh back button parent
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar + Online Indicator
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
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
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green[500],
                    shape: BoxShape.circle,
                    border: Border.all(color: card, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budi Santoso', style: _body(tp, 16, FontWeight.bold)),
                Row(
                  children: [
                    Text('Online', style: _body(ts, 11, FontWeight.w500)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('•', style: _body(ts.withOpacity(0.5), 11, FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text('Gojek Kampus ID: 8829', style: _body(ts, 11, FontWeight.w500), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? kSurfaceDark : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone_rounded, color: ts, size: 20),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 2. Chat Elements
  Widget _buildSystemStatus(String text, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text.toUpperCase(),
          style: _body(isDark ? Colors.white54 : Colors.black54, 10, FontWeight.bold, ls: 1.5),
        ),
      ),
    );
  }

  Widget _buildDriverMessage(String message, String time, Color tp, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(message, style: _body(tp, 14, FontWeight.normal, h: 1.4)),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(time, style: _body(isDark ? Colors.white38 : Colors.black38, 10, FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildUserMessage(String message, String statusInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(
            message,
            style: _body(const Color(0xFF0F172A), 14, FontWeight.w500, h: 1.4),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(statusInfo, style: _body(Colors.grey, 10, FontWeight.w500)),
        ),
      ],
    );
  }

  // 3. Live Location Placeholder
  Widget _buildLocationCard(Color tp, Color ts, Color border, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frame peta
            Container(
              height: 120,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?w=400&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
                ),
              ),
              child: Center(
                child: Icon(Icons.location_on_rounded, color: kPrimary, size: 36, shadows: [Shadow(color: Colors.black45, blurRadius: 8)]),
              ),
            ),
            // Info text
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DRIVER LOCATION', style: _body(ts, 10, FontWeight.bold, ls: 0.5)),
                  const SizedBox(height: 2),
                  Text('Gedung Perpustakaan Pusat', style: _body(tp, 13, FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Footer Input Message & Quick Replies
  Widget _buildFooter(Color tp, Color ts, Color card, Color border, bool isDark) {
    final replies = ['Sudah sampai?', 'Tunggu ya!', 'Otw kak', 'Posisi dimana?'];

    return Container(
      padding: EdgeInsets.only(bottom: 12 /* MediaQuery padding akan dihandle parent bottom nav */, top: 12),
      decoration: BoxDecoration(
        color: card,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          // Quick Replies
          SizedBox(
            height: 34,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: replies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Center(
                    child: Text(replies[i], style: _body(ts, 12, FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Input Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      children: [
                        // Plus Button
                        Container(
                          margin: const EdgeInsets.all(4),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                          ),
                          child: Icon(Icons.add_circle_outline_rounded, color: ts, size: 20),
                        ),
                        const SizedBox(width: 8),
                        // TextField
                        Expanded(
                          child: TextField(
                            style: _body(tp, 14, FontWeight.normal),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: _body(ts, 14, FontWeight.normal),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        // Send Button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.black87, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
