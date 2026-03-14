import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';

// ─── Warna Tema ───────────────────────────────────────────────────────────────
const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Kirim & Antar Teman',
      'desc': 'Solusi mobilitas seru dan hemat khusus buat pejuang kampus.',
      'image': 'assets/images/onboarding_1.png',
      'icon': 'scooter',
    },
    {
      'title': 'Lacak Perjalananmu',
      'desc': 'Pantau posisi pengemudi secara real-time, aman sampai tujuan.',
      'image': 'assets/images/onboarding_2.png',
      'icon': 'map',
    },
    {
      'title': 'Bayar Mudah & Hemat',
      'desc': 'Tarif transparan khusus mahasiswa, bayar cashless tanpa ribet.',
      'image': 'assets/images/onboarding_3.png',
      'icon': 'wallet',
    },
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  // Skip → next page
  void _skip() {
    if (!_isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // Tombol utama → SELALU langsung ke Login
  void _onPrimaryTap() {
    _goToLogin();
  }

  // Navigasi ke LoginScreen
  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // Navigasi ke RegisterScreen
  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? kBackgroundDark : kBackgroundLight;
    final Color textPrimary =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final Color dotInactive =
        isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final Color secondaryBtnBg =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              children: [
                // ── Top Nav — Skip hanya muncul bukan di halaman terakhir ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!_isLastPage)
                        _SkipButton(isDark: isDark, onSkip: _skip),
                    ],
                  ),
                ),

                // ── PageView ─────────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) => _OnboardingPage(
                      data: _pages[index],
                      isDark: isDark,
                    ),
                  ),
                ),

                // ── Bottom Section ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Column(
                    children: [
                      // Pagination Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (index) {
                          final bool isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            height: 10,
                            width: isActive ? 32 : 10,
                            decoration: BoxDecoration(
                              color: isActive ? kPrimary : dotInactive,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: kPrimary.withOpacity(0.40),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 28),

                      // Tombol Utama — Masuk dengan Nomor Mahasiswa
                      _PrimaryButton(onTap: _onPrimaryTap),

                      const SizedBox(height: 16),

                      // Tombol Sekunder — Daftar
                      _SecondaryButton(
                        isDark: isDark,
                        bgColor: secondaryBtnBg,
                        textColor: textPrimary,
                        onTap: _goToRegister,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Satu Halaman Onboarding
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final Map<String, String> data;
  final bool isDark;

  const _OnboardingPage({required this.data, required this.isDark});

  IconData get _fallbackIcon {
    switch (data['icon']) {
      case 'map':
        return Icons.map_rounded;
      case 'wallet':
        return Icons.wallet_rounded;
      default:
        return Icons.electric_scooter_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textPrimary =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final Color textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Gambar ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: isDark
                  ? kPrimary.withOpacity(0.05)
                  : kPrimary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                data['image']!,
                fit: BoxFit.contain,
                errorBuilder: (context, _, __) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _fallbackIcon,
                        size: 100,
                        color: kPrimary.withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'GasKampus',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Judul ─────────────────────────────────────────────────────────
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 14),

          // ── Deskripsi ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              data['desc']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Skip Button
// ─────────────────────────────────────────────────────────────────────────────
class _SkipButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onSkip;

  const _SkipButton({required this.isDark, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onSkip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            'Skip',
            style: TextStyle(
              color:
                  isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
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
// Widget: Primary Button — dengan scale animation
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  final VoidCallback onTap;

  const _PrimaryButton({required this.onTap});

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
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_rounded,
                color: Color(0xFF0F172A),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
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
// Widget: Secondary Button — Daftar
// ─────────────────────────────────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final bool isDark;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.isDark,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
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