import 'package:flutter/material.dart';

// ─── Warna Tema ───────────────────────────────────────────────────────────────
const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? kBackgroundDark : kBackgroundLight;
    final Color textPrimary =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final Color textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final Color dotInactive =
        isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final Color secondaryBtnBg =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Mirip max-w-md di HTML
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              children: [
                // ── Top Navigation (Skip Button) ───────────────────────────
                _buildTopNav(isDark),

                // ── Hero Illustration ──────────────────────────────────────
                _buildHeroIllustration(isDark),

                // ── Content Section ────────────────────────────────────────
                Expanded(
                  child: _buildContentSection(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dotInactive: dotInactive,
                    secondaryBtnBg: secondaryBtnBg,
                  ),
                ),

                // Safe area spacer
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Top Navigation — Tombol Skip
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopNav(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _SkipButton(isDark: isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Hero Illustration
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroIllustration(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            color: isDark
                ? kPrimary.withOpacity(0.05)
                : kPrimary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Dekorasi lingkaran blur kanan atas
              Positioned(
                top: 30,
                right: 30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimary.withOpacity(0.20),
                  ),
                ),
              ),
              // Dekorasi lingkaran blur kiri bawah
              Positioned(
                bottom: 30,
                left: 30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimary.withOpacity(0.30),
                  ),
                ),
              ),
              // Gambar utama
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCB1mF0lGLm6lgd5GY_uX7HZNcqGn5FrZa5rnIsPjPFFxhWw_7MDfs9OfT70PQ6uJCQ-vpRIInHcQzmcbIIDlip7dN1nSKJXaTj7DohROMxT1Xz7-nXGhUUUc6dLJtpb66D3aHal77Jzr-j-Q7QgWUQT9nf5de-MxM3NElTHI85ZrynMTDD-FJdxSoGlLytMq3kvjUKwDsp-CSRDqTR9oUZ7qqLFC--hPukDZKR3xJ0YcxGhCBbcAXOAVXwqvUa8HYbs-wNMrtsK0g',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.electric_scooter_rounded,
                            size: 100,
                            color: kPrimary.withOpacity(0.7),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'GasKampus',
                            style: TextStyle(
                              color: kPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: kPrimary,
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Content Section
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContentSection({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color dotInactive,
    required Color secondaryBtnBg,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          // Judul
          Text(
            'Kirim & Antar Teman',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Deskripsi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Solusi mobilitas seru dan hemat khusus buat pejuang kampus.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
            ),
          ),

          // Pagination Dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dot aktif (lebih lebar)
                Container(
                  width: 32,
                  height: 10,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.40),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Dot tidak aktif 1
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotInactive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                // Dot tidak aktif 2
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotInactive,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Action Buttons ───────────────────────────────────────────
          Column(
            children: [
              // Tombol Utama — Login
              _PrimaryButton(isDark: isDark),
              const SizedBox(height: 16),
              // Tombol Sekunder — Daftar
              _SecondaryButton(
                isDark: isDark,
                bgColor: secondaryBtnBg,
                textColor: textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Skip Button
// ─────────────────────────────────────────────────────────────────────────────
class _SkipButton extends StatefulWidget {
  final bool isDark;
  const _SkipButton({required this.isDark});

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            'Skip',
            style: TextStyle(
              color: widget.isDark
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Primary Button (Login)
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  final bool isDark;
  const _PrimaryButton({required this.isDark});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {},
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.30),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school_rounded,
                color: Color(0xFF0F172A),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Masuk dengan Nomor Mahasiswa',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Secondary Button (Daftar)
// ─────────────────────────────────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final bool isDark;
  final Color bgColor;
  final Color textColor;

  const _SecondaryButton({
    required this.isDark,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            'Belum punya akun? Daftar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
