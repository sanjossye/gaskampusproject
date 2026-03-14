import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? kBackgroundDark : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF0F1405) : const Color(0xFFF1F5F9);
    final Color textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final Color textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final Color borderColor = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────────────
                _buildTopBar(context, textPrimary),

                // ── Content Area (Scrollable) ──────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Daftar atau Masuk',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lengkapi data diri kamu untuk mulai menggunakan layanan khusus mahasiswa.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // WhatsApp Section
                        _buildSectionLabel('Nomor WhatsApp (+62)', textPrimary),
                        const SizedBox(height: 12),
                        _buildWhatsAppField(inputBg, textPrimary, borderColor),

                        const SizedBox(height: 32),

                        // OTP Section
                        _buildSectionLabel('Verifikasi OTP', textPrimary),
                        const SizedBox(height: 16),
                        _buildOTPFields(inputBg, textPrimary, borderColor),
                        const SizedBox(height: 12),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: textSecondary, fontSize: 13),
                              children: [
                                const TextSpan(text: 'Tidak menerima kode? '),
                                TextSpan(
                                  text: 'Kirim ulang (45s)',
                                  style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Divider(height: 64, thickness: 1, color: Color(0xFFF1F5F9)),

                        // Student Info Section
                        Text(
                          'Informasi Mahasiswa',
                          style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),

                        _buildInputField('Nama Lengkap', 'Sesuai KTM', inputBg, textPrimary, borderColor),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(child: _buildInputField('NIM', '12345678', inputBg, textPrimary, borderColor)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInputField('Fakultas', 'Teknik', inputBg, textPrimary, borderColor)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // KTM Upload Section
                        _buildSectionLabel('Unggah Foto KTM', textPrimary),
                        const SizedBox(height: 12),
                        _buildKTMUploadBox(isDark, textSecondary, borderColor),

                        const SizedBox(height: 40),

                        // Submit Button
                        _buildSubmitButton(),
                        
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Dengan mendaftar, kamu menyetujui Syarat & Ketentuan serta Kebijakan Privasi Gojek Kampus.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Indicator (Styling)
                Container(
                  height: 4,
                  width: 120,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 48),
                child: Text(
                  'Gojek Kampus',
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color textColor) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
    );
  }

  Widget _buildWhatsAppField(Color bg, Color textColor, Color border) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('+62', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: '81234567890',
                hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPFields(Color bg, Color textColor, Color border) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: const TextField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(counterText: '', border: InputBorder.none),
          ),
        );
      }),
    );
  }

  Widget _buildInputField(String label, String hint, Color bg, Color textColor, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKTMUploadBox(bool isDark, Color textSecondary, Color border) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? kPrimary.withOpacity(0.03) : const Color(0xFFF1F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, style: BorderStyle.none), // Custom painter could be used for dashed
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.add_a_photo_outlined, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Text('Klik untuk ambil foto atau upload', style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('JPG, PNG, atau HEIC (Maks. 5MB)', style: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: const Text(
          'Daftar / Masuk',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
