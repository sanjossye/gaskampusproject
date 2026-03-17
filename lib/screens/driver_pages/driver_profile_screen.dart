import 'package:flutter/material.dart';
import '../login_screen.dart';

const Color kPrimary = Color(0xFFC0F637);

class DriverProfileScreen extends StatelessWidget {
  final VoidCallback onBack;

  const DriverProfileScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1D2210) : Colors.white;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.arrow_back, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Profil Driver',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balances the back button
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    // Profile Hero
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? const Color(0xFF1D2210) : Colors.white, width: 4),
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                          "https://lh3.googleusercontent.com/aida-public/AB6AXuC1qY-oQKNzPMbEBWLqkDwamL_U7DqX_JmNnXrXf1GNWGR7wxWLIK6WZLEk7OTltAZHnndXUcGatEln4e6GJTRCM18XJ9kjYxlxXvuBU62r7zZsiWgshS8zvQXb2fwqSILtYw0ZqtxVWEKgliPiRrAAJmWCbmP5_pqCT6dgl2sLH2VfFd3aGJJG7EngniKOhLmsOfOoRd-9ynWjRWqeFZaqbgiE9jJPNv5f1o9q3emvgTSM87AAkCYygzFTgNdB1N5un08i9RfGxCA"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFF1D2210) : Colors.white, width: 2),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Budi Santoso',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.verified, color: Colors.blue, size: 20),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school, color: Colors.green[800], size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'STUDENT DRIVER',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'NIM: 12345678',
                            style: TextStyle(
                              color: textMutedColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fakultas Matematika dan IPA (FMIPA)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textMutedColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats Sub-section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Trips',
                              value: '142',
                              isDark: isDark,
                              textColor: textColor,
                              textMutedColor: textMutedColor,
                              cardBg: cardBg,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Rating',
                              value: '4.9',
                              icon: Icons.star,
                              iconColor: Colors.orange,
                              isDark: isDark,
                              textColor: textColor,
                              textMutedColor: textMutedColor,
                              cardBg: cardBg,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Member',
                              value: 'Oct 2023',
                              isDark: isDark,
                              textColor: textColor,
                              textMutedColor: textMutedColor,
                              cardBg: cardBg,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Menu List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'MENU UTAMA',
                              style: TextStyle(
                                color: textMutedColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'Edit Profil',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                          ),
                          _buildMenuItem(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Dompet & Tarik Tunai',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                          ),
                          _buildMenuItem(
                            icon: Icons.description_outlined,
                            title: 'Dokumen Kendaraan',
                            subtitle: 'KTM, SIM, STNK',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                          ),
                          _buildMenuItem(
                            icon: Icons.bar_chart,
                            title: 'Riwayat Performa',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                          ),
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            title: 'Bantuan',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                          ),
                          _buildMenuItem(
                            icon: Icons.settings_outlined,
                            title: 'Pengaturan',
                            isDark: isDark,
                            textColor: textColor,
                            textMutedColor: textMutedColor,
                          ),
                        ],
                      ),
                    ),

                    // Logout Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
                            borderRadius: BorderRadius.circular(16),
                            color: isDark ? Colors.red.withOpacity(0.05) : Colors.red.shade50,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.red[500]),
                              const SizedBox(width: 8),
                              Text(
                                'Keluar Sesi',
                                style: TextStyle(
                                  color: Colors.red[500],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    IconData? icon,
    Color? iconColor,
    required bool isDark,
    required Color textColor,
    required Color textMutedColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: textMutedColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, color: iconColor, size: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    required Color textColor,
    required Color textMutedColor,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textMutedColor,
                        fontSize: 10,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textMutedColor),
          ],
        ),
      ),
    );
  }
}
