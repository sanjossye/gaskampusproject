import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_services.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _phoneController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _facultyController = TextEditingController();

  XFile? _ktmImage;
  Uint8List? _ktmBytes;
  String? _ktmError;
  bool _loading = false;
  bool _obscurePassword = true;
  String _status = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

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
                  child: Form(
                    key: _formKey,
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

                          const SizedBox(height: 24),

                          // NIM Section (pengganti verifikasi OTP)
                          _buildInputField(
                            label: 'Nomor Induk Mahasiswa (NIM)',
                            hint: '12345678',
                            controller: _nimController,
                            bg: inputBg,
                            textColor: textPrimary,
                            border: borderColor,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final v = (value ?? '').trim();
                              if (v.isEmpty) return 'NIM wajib diisi.';
                              if (!RegExp(r'^\d{5,20}$').hasMatch(v)) {
                                return 'NIM hanya angka (5-20 digit).';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Kredensial akun
                          _buildInputField(
                            label: 'Email',
                            hint: 'nama@kampus.ac.id',
                            controller: _emailController,
                            bg: inputBg,
                            textColor: textPrimary,
                            border: borderColor,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final v = (value ?? '').trim();
                              if (v.isEmpty) return 'Email wajib diisi.';
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                                return 'Format email tidak valid.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          _buildInputField(
                            label: 'Password',
                            hint: 'Minimal 6 karakter',
                            controller: _passwordController,
                            bg: inputBg,
                            textColor: textPrimary,
                            border: borderColor,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                            validator: (value) {
                              final v = value ?? '';
                              if (v.isEmpty) return 'Password wajib diisi.';
                              if (v.length < 6) return 'Password minimal 6 karakter.';
                              return null;
                            },
                          ),

                          const Divider(height: 64, thickness: 1, color: Color(0xFFF1F5F9)),

                          // Student Info Section
                          Text(
                            'Informasi Mahasiswa',
                            style: TextStyle(
                                color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),

                          _buildInputField(
                            label: 'Nama Lengkap',
                            hint: 'Sesuai KTM',
                            controller: _nameController,
                            bg: inputBg,
                            textColor: textPrimary,
                            border: borderColor,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Nama lengkap wajib diisi.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          _buildInputField(
                            label: 'Fakultas',
                            hint: 'Teknik',
                            controller: _facultyController,
                            bg: inputBg,
                            textColor: textPrimary,
                            border: borderColor,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Fakultas wajib diisi.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // KTM Upload Section
                          _buildSectionLabel('Unggah Foto KTM', textPrimary),
                          const SizedBox(height: 12),
                          _buildKTMUploadBox(isDark, textSecondary, borderColor),
                          if (_ktmError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _ktmError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],

                          const SizedBox(height: 40),

                          // Submit Button
                          _buildSubmitButton(textPrimary),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Dengan mendaftar, kamu menyetujui Syarat & Ketentuan serta Kebijakan Privasi Gojek Kampus.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
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

  // ─── Firebase ───────────────────────────────────────────────────────────────

  Future<void> _pickKtmImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      _showSnack('Ukuran foto maksimal 5MB.', Colors.red);
      return;
    }

    setState(() {
      _ktmImage = picked;
      _ktmBytes = bytes;
      _ktmError = null;
    });
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    final bool formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _ktmError = _ktmImage == null ? 'Foto KTM wajib diunggah.' : null;
    });
    if (!formValid || _ktmImage == null) return;

    setState(() {
      _loading = true;
      _status = 'Memproses...';
    });

    try {
      // 1. Buat akun di Firebase Auth + profil di Firestore (users & login_index)
      final user = await _authService
          .register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            username: _nimController.text.trim(),
            role: 'mahasiswa',
            nim: _nimController.text.trim(),
            phone: _buildPhoneNumber(),
            faculty: _facultyController.text.trim(),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final extension = _ktmImage!.name.contains('.')
          ? _ktmImage!.name.split('.').last.toLowerCase()
          : 'jpg';
      final contentType = extension == 'jpg' ? 'image/jpeg' : 'image/$extension';
      final nowIso = DateTime.now().toIso8601String();

      // 2. Upload foto KTM ke Firebase Storage (dibatasi waktunya agar tidak menggantung)
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('ktm')
            .child(user.uid)
            .child('ktm_${DateTime.now().millisecondsSinceEpoch}.$extension');

        await storageRef
            .putData(_ktmBytes!, SettableMetadata(contentType: contentType))
            .timeout(const Duration(seconds: 20));
        final downloadUrl = await storageRef
            .getDownloadURL()
            .timeout(const Duration(seconds: 15));

        // 3. Simpan URL KTM ke dokumen user
        await userRef.update({
          'ktmUrl': downloadUrl,
          'ktmStorage': 'storage',
          'ktmUploadedAt': nowIso,
        }).timeout(const Duration(seconds: 20));
      } catch (_) {
        // Fallback: simpan foto langsung di Firestore (subkoleksi users/{uid}/documents)
        // supaya foto tetap tersimpan walau Firebase Storage belum aktif.
        try {
          if (_ktmBytes!.length <= 700 * 1024) {
            await userRef.collection('documents').doc('ktm').set({
              'fileName': _ktmImage!.name,
              'contentType': contentType,
              'base64': base64Encode(_ktmBytes!),
              'uploadedAt': nowIso,
            }).timeout(const Duration(seconds: 20));
            await userRef.update({
              'ktmStorage': 'firestore',
              'ktmUploadedAt': nowIso,
            }).timeout(const Duration(seconds: 20));
          }
        } catch (_) {}
      }

      if (!mounted) return;
      _showSnack('Pendaftaran berhasil', Colors.green);
      Navigator.pop(context, true);
    } catch (_) {
      _showSnack('Pendaftaran gagal', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _status = '';
        });
      }
    }
  }

  String _buildPhoneNumber() {
    var digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+62$digits';
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ─── Widgets ────────────────────────────────────────────────────────────────

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
      style: TextStyle(
          color: textColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
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
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: '81234567890',
                hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'Nomor WhatsApp wajib diisi.';
                if (digits.length < 9) return 'Nomor WhatsApp tidak valid.';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required Color bg,
    required Color textColor,
    required Color border,
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              TextStyle(color: textColor.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: EdgeInsets.only(left: 16, right: suffixIcon == null ? 16 : 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  validator: validator,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              ?suffixIcon,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKTMUploadBox(bool isDark, Color textSecondary, Color border) {
    return GestureDetector(
      onTap: _loading ? null : _pickKtmImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? kPrimary.withOpacity(0.03) : const Color(0xFFF1F5F9).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _ktmError != null ? Colors.red : border,
            style: BorderStyle.solid,
          ),
        ),
        child: _ktmBytes == null
            ? Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.add_a_photo_outlined, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text('Klik untuk ambil foto atau upload',
                      style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('JPG, PNG, atau HEIC (Maks. 5MB)',
                      style: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 12)),
                ],
              )
            : Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _ktmBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _ktmImage?.name ?? 'Foto KTM terpilih',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ganti',
                        style: TextStyle(
                            color: kPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton(Color textColor) {
    return InkWell(
      onTap: _loading ? null : _submitRegistration,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: kPrimary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: _loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _status,
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                'Daftar / Masuk',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
