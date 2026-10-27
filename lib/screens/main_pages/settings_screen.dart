import 'package:flutter/material.dart';
import '../../main.dart';

const Color kPrimary       = Color(0xFFC0F637);
const Color kPrimaryDeep   = Color(0xFF8DBF1A);
const Color kBgDark        = Color(0xFF0F172A);
const Color kCardDark      = Color(0xFF1E293B);
const Color kBorderDark    = Color(0xFF334155);
const Color kBorderLight   = Color(0xFFE2E8F0);
const Color kTextOnPrimary = Color(0xFF0A0F02);

TextStyle _body(Color c, double sz, FontWeight w, {double? ls, double? h}) =>
    TextStyle(color: c, fontSize: sz, fontWeight: w, letterSpacing: ls, height: h);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Data Profil Mahasiswa
  String _name = 'Ahmad Zaki';
  String _nim = '12345678';
  String _prodi = 'Sistem Informasi • Fasilkom';
  String _phone = '+62 812-3456-7890';
  String _email = 'ahmad.zaki@ui.ac.id';

  // Toggle Preferensi Notifikasi
  bool _notifOrder = true;
  bool _notifPromo = true;
  bool _notifSound = true;

  // Keamanan
  bool _biometricLock = false;

  // Cache
  String _cacheSize = '14.8 MB';

  void _showEditDialog({
    required String title,
    required String currentValue,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: currentValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F172A);
    final border = isDark ? kBorderDark : kBorderLight;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        title: Text(title, style: _body(tp, 16, FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: tp, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                onSave(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1D2210),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: kPrimary),
                    ),
                    content: Text(
                      '$title berhasil diperbarui!',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: kTextOnPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F172A);
    final border = isDark ? kBorderDark : kBorderLight;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        title: Text('Ganti Password Akun', style: _body(tp, 16, FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPassField(oldPass, 'Password Saat Ini', tp, border),
            const SizedBox(height: 10),
            _buildPassField(newPass, 'Password Baru', tp, border),
            const SizedBox(height: 10),
            _buildPassField(confirmPass, 'Konfirmasi Password Baru', tp, border),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPass.text.isNotEmpty && newPass.text == confirmPass.text) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF1D2210),
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Password akun berhasil diubah! 🔒',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    content: Text('Konfirmasi password tidak cocok!'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: kTextOnPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ubah Password', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPassField(TextEditingController ctrl, String hint, Color tp, Color border) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: TextStyle(color: tp, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? kBgDark : Colors.white;
    final cardBg = isDark ? kCardDark : const Color(0xFFF8FAFC);
    final tp     = isDark ? Colors.white : const Color(0xFF0F172A);
    final ts     = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? kBorderDark : kBorderLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan Akun',
          style: _body(tp, 18, FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: border, height: 1.0),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // ── SECTION 1: TAMPILAN & TEMA (DARK MODE) ──
          _buildSectionHeader('TAMPILAN & MODE GELAP', tp),
          _buildThemeSelectorCard(cardBg, border, tp, ts, isDark),

          const SizedBox(height: 24),

          // ── SECTION 2: DATA MAHASISWA ──
          _buildSectionHeader('INFORMASI AKUN MAHASISWA', tp),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Nama Lengkap',
                  value: _name,
                  tp: tp,
                  ts: ts,
                  border: border,
                  onTap: () => _showEditDialog(
                    title: 'Ubah Nama Lengkap',
                    currentValue: _name,
                    onSave: (val) => setState(() => _name = val),
                  ),
                ),
                _buildInfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Nomor Induk Mahasiswa (NIM)',
                  value: _nim,
                  tp: tp,
                  ts: ts,
                  border: border,
                  onTap: () => _showEditDialog(
                    title: 'Ubah NIM',
                    currentValue: _nim,
                    onSave: (val) => setState(() => _nim = val),
                  ),
                ),
                _buildInfoTile(
                  icon: Icons.school_outlined,
                  label: 'Program Studi & Fakultas',
                  value: _prodi,
                  tp: tp,
                  ts: ts,
                  border: border,
                  onTap: () => _showEditDialog(
                    title: 'Ubah Program Studi',
                    currentValue: _prodi,
                    onSave: (val) => setState(() => _prodi = val),
                  ),
                ),
                _buildInfoTile(
                  icon: Icons.phone_android_rounded,
                  label: 'Nomor WhatsApp / HP',
                  value: _phone,
                  tp: tp,
                  ts: ts,
                  border: border,
                  onTap: () => _showEditDialog(
                    title: 'Ubah Nomor HP',
                    currentValue: _phone,
                    onSave: (val) => setState(() => _phone = val),
                  ),
                ),
                _buildInfoTile(
                  icon: Icons.alternate_email_rounded,
                  label: 'Email Kampus',
                  value: _email,
                  tp: tp,
                  ts: ts,
                  border: null,
                  onTap: () => _showEditDialog(
                    title: 'Ubah Email Kampus',
                    currentValue: _email,
                    onSave: (val) => setState(() => _email = val),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── SECTION 3: NOTIFIKASI ──
          _buildSectionHeader('NOTIFIKASI KAMPUS', tp),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifikasi Order & Driver',
                  subtitle: 'Update status jemputan, pesanan tiba & chat',
                  value: _notifOrder,
                  tp: tp,
                  ts: ts,
                  border: border,
                  onChanged: (val) => setState(() => _notifOrder = val),
                ),
                _buildSwitchTile(
                  icon: Icons.discount_outlined,
                  title: 'Info Promo & Voucher Kampus',
                  subtitle: 'Pemberitahuan diskon kantin & gratis ongkir',
                  value: _notifPromo,
                  tp: tp,
                  ts: ts,
                  border: border,
                  onChanged: (val) => setState(() => _notifPromo = val),
                ),
                _buildSwitchTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Suara & Getar Notifikasi',
                  subtitle: 'Bunyikan nada saat driver mendekat ke lokasimu',
                  value: _notifSound,
                  tp: tp,
                  ts: ts,
                  border: null,
                  onChanged: (val) => setState(() => _notifSound = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── SECTION 4: KEAMANAN & PRIVASI ──
          _buildSectionHeader('KEAMANAN & PRIVASI', tp),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Kunci Aplikasi (Biometrik)',
                  subtitle: 'Minta sidik jari / Face ID saat membuka GasKam',
                  value: _biometricLock,
                  tp: tp,
                  ts: ts,
                  border: border,
                  onChanged: (val) => setState(() => _biometricLock = val),
                ),
                _buildActionTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Ubah Password Akun',
                  subtitle: 'Perbarui kata sandi secara berkala',
                  tp: tp,
                  ts: ts,
                  border: border,
                  onTap: _showChangePasswordDialog,
                ),
                _buildActionTile(
                  icon: Icons.my_location_rounded,
                  title: 'Izin Akses Lokasi (GPS)',
                  subtitle: 'Status: Selalu Diizinkan di Area Kampus',
                  tp: tp,
                  ts: ts,
                  border: null,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Izin GPS Kampus aktif & akurat.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── SECTION 5: DATA & PENYIMPANAN ──
          _buildSectionHeader('DATA & PENYIMPANAN', tp),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.cleaning_services_rounded,
                  title: 'Hapus Cache Aplikasi',
                  subtitle: 'Ukuran cache saat ini: $_cacheSize',
                  trailingText: 'Bersihkan',
                  tp: tp,
                  ts: ts,
                  border: border,
                  onTap: () {
                    setState(() => _cacheSize = '0 KB');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1D2210),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: kPrimary),
                        ),
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: kPrimary, size: 20),
                            SizedBox(width: 10),
                            Text('Cache 14.8 MB berhasil dibersihkan! 🧹',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.language_rounded,
                  title: 'Bahasa Aplikasi',
                  subtitle: 'Bahasa Indonesia (ID)',
                  tp: tp,
                  ts: ts,
                  border: null,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Saat ini Bahasa Indonesia adalah default.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Footer Versi ──
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school_rounded, color: kPrimaryDeep, size: 16),
                    const SizedBox(width: 6),
                    Text('GasKampus Super-App', style: _body(tp, 13, FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Versi 1.0.0+1 • Solusi Mobilitas Mahasiswa',
                    style: _body(ts, 11, FontWeight.w400)),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color tp) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: _body(kPrimaryDeep, 11, FontWeight.bold, ls: 1.0),
      ),
    );
  }

  // Card Pengaturan Tema / Dark Mode
  Widget _buildThemeSelectorCard(
      Color cardBg, Color border, Color tp, Color ts, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? kPrimary : Colors.amber[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mode Gelap (Dark Mode)',
                        style: _body(tp, 14, FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      themeNotifier.value == ThemeMode.dark
                          ? 'Aktif • Mode gelap ramah di mata & hemat daya'
                          : 'Ikuti Sistem • Menyesuaikan tema perangkat',
                      style: _body(ts, 11, FontWeight.w400),
                    ),
                  ],
                ),
              ),
              Switch(
                value: themeNotifier.value == ThemeMode.dark,
                activeThumbColor: kPrimary,
                activeTrackColor: kPrimaryDeep.withValues(alpha: 0.5),
                onChanged: (val) {
                  setState(() {
                    themeNotifier.value =
                        val ? ThemeMode.dark : ThemeMode.system;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: border, height: 1),
          const SizedBox(height: 12),

          // Pilihan 2 Mode: Gelap & Sistem
          Row(
            children: [
              _buildThemePill(
                label: 'Mode Gelap',
                icon: Icons.dark_mode_rounded,
                selected: themeNotifier.value == ThemeMode.dark,
                onTap: () {
                  setState(() => themeNotifier.value = ThemeMode.dark);
                },
                border: border,
                tp: tp,
              ),
              const SizedBox(width: 10),
              _buildThemePill(
                label: 'Ikuti Sistem',
                icon: Icons.settings_brightness_rounded,
                selected: themeNotifier.value == ThemeMode.system,
                onTap: () {
                  setState(() => themeNotifier.value = ThemeMode.system);
                },
                border: border,
                tp: tp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemePill({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Color border,
    required Color tp,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? kPrimary : border,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? kTextOnPrimary : tp.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: _body(
                  selected ? kTextOnPrimary : tp,
                  12,
                  selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color tp,
    required Color ts,
    required Color? border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: border != null ? Border(bottom: BorderSide(color: border)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: kPrimaryDeep, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _body(ts, 11, FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(value, style: _body(tp, 14, FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, color: ts.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color tp,
    required Color ts,
    required Color? border,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: border != null ? Border(bottom: BorderSide(color: border)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryDeep, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _body(tp, 13, FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: _body(ts, 11, FontWeight.w400)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: kPrimary,
            activeTrackColor: kPrimaryDeep.withValues(alpha: 0.5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailingText,
    required Color tp,
    required Color ts,
    required Color? border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: border != null ? Border(bottom: BorderSide(color: border)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: kPrimaryDeep, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _body(tp, 13, FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _body(ts, 11, FontWeight.w400)),
                ],
              ),
            ),
            if (trailingText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingText,
                  style: _body(kPrimaryDeep, 11, FontWeight.bold),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: ts.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
