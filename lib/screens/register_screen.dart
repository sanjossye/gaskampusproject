import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/merchant_model.dart';
import '../services/auth_services.dart';
import '../services/map_route_service.dart';
import '../services/merchant_service.dart';
import '../services/zone_service.dart';
import 'main_pages/jadwal_kuliah_screen.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

/// Hari yang didukung untuk input jadwal kuliah: Senin s.d. Jumat.
const List<String> kDayNames = [
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
];

/// Daftar pilihan Fakultas untuk dropdown yang juga mendukung pencarian/ketik manual.
const List<String> kFacultyOptions = [
  'Fakultas Teknik (FT)',
  'Fakultas Ilmu Komputer dan Teknologi Informasi (Fasilkom-TI)',
  'Fakultas Ekonomi dan Bisnis (FEB)',
  'Fakultas Kedokteran (FK)',
  'Fakultas Hukum (FH)',
  'Fakultas Pertanian (FP)',
  'Fakultas Ilmu Sosial dan Ilmu Politik (FISIP)',
  'Fakultas Matematika dan Ilmu Pengetahuan Alam (FMIPA)',
  'Fakultas Ilmu Budaya (FIB)',
  'Fakultas Kesehatan Masyarakat (FKM)',
  'Fakultas Farmasi (FF)',
  'Fakultas Psikologi (FPsi)',
  'Fakultas Keperawatan (FKep)',
  'Fakultas Kedokteran Gigi (FKG)',
  'Fakultas Kehutanan',
  'Fakultas Vokasi',
];

/// Daftar pilihan Jurusan wajib ketika Fakultas = Fakultas Teknik (FT).
const List<String> kTeknikMajorOptions = [
  'Arsitektur',
  'Teknik Sipil',
  'Teknik Kimia',
  'Teknik Lingkungan',
  'Teknik Elektro',
  'Teknik Mesin',
  'Teknik Industri',
];

/// Satu baris jadwal kuliah yang diisi saat pendaftaran.
class _CourseEntry {
  final String courseName;
  final String room;
  final String startTime; // HH:mm
  final String endTime; // HH:mm

  const _CourseEntry({
    required this.courseName,
    required this.room,
    required this.startTime,
    required this.endTime,
  });
}

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
  final _nikController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _facultyController = TextEditingController();
  final _merchantUsernameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storeBannerHeadlineController = TextEditingController();

  /// mahasiswa | driver_kampus (driver mahasiswa) | driver_umum | merchant
  String _role = 'mahasiswa';

  String _storeCategory = kMerchantCategories.first;
  String _storeBannerTheme = 'lime';
  String _storeBannerData = '';
  double _storeLat = 3.5625;
  double _storeLng = 98.6565;
  final List<MerchantMenuItem> _merchantMenus = [];

  XFile? _docImage;
  Uint8List? _docBytes;
  String? _docError;
  String? _scheduleError;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _isFacultyDropdownOpen = false;
  String? _selectedTeknikMajor;
  String _status = '';

  bool get _isTeknikSelected =>
      normalizeFaculty(_facultyController.text) == 'FT';

  /// Jadwal kuliah per hari (1 = Senin ... 5 = Jumat).
  final Map<int, List<_CourseEntry>> _schedules = {
    1: [],
    2: [],
    3: [],
    4: [],
    5: [],
  };

  bool get _isMahasiswa => _role == 'mahasiswa';
  bool get _isDriverMahasiswa => _role == 'driver_kampus';
  bool get _isDriverUmum => _role == 'driver_umum';
  bool get _isMerchant => _role == 'merchant';
  bool get _isStudentRole => _isMahasiswa || _isDriverMahasiswa;
  String get _docLabel => _isDriverUmum
      ? 'KTP'
      : (_isMerchant ? 'KTP Pemilik / Foto Toko' : 'KTM');
  int get _totalSchedules =>
      _schedules.values.fold(0, (total, list) => total + list.length);

  @override
  void dispose() {
    _phoneController.dispose();
    _nimController.dispose();
    _nikController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _facultyController.dispose();
    _merchantUsernameController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storeBannerHeadlineController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    if (_role == role) return;
    setState(() {
      _role = role;
      _docImage = null;
      _docBytes = null;
      _docError = null;
      _scheduleError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? kBackgroundDark : Colors.white;
    final Color inputBg = isDark
        ? const Color(0xFF0F1405)
        : const Color(0xFFF1F5F9);
    final Color textPrimary = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final Color textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);
    final Color borderColor = isDark
        ? const Color(0xFF334110)
        : const Color(0xFFE2E8F0);

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
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
                            'Pilih jenis akun yang ingin kamu daftarkan, lalu lengkapi datanya.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Pilihan Peran ────────────────────────────────────
                          _buildSectionLabel('Daftar Sebagai', textPrimary),
                          const SizedBox(height: 12),
                          _buildRoleSelector(
                            isDark,
                            textPrimary,
                            textSecondary,
                            borderColor,
                          ),

                          const SizedBox(height: 24),

                          // WhatsApp Section
                          _buildSectionLabel(
                            'Nomor WhatsApp (+62)',
                            textPrimary,
                          ),
                          const SizedBox(height: 12),
                          _buildWhatsAppField(
                            inputBg,
                            textPrimary,
                            borderColor,
                          ),

                          const SizedBox(height: 24),

                          // NIM (mahasiswa & driver mahasiswa) / Username Toko (merchant) / NIK (driver umum)
                          if (_isStudentRole) ...[
                            _buildInputField(
                              label: 'Nomor Induk Mahasiswa (NIM)',
                              hint: 'Contoh: 12345678',
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
                          ] else if (_isMerchant) ...[
                            _buildInputField(
                              label: 'Username Toko (untuk Login)',
                              hint: 'Contoh: warungbunda (tanpa spasi)',
                              controller: _merchantUsernameController,
                              bg: inputBg,
                              textColor: textPrimary,
                              border: borderColor,
                              validator: (value) {
                                final v = (value ?? '').trim().toLowerCase();
                                if (v.isEmpty) {
                                  return 'Username toko wajib diisi.';
                                }
                                if (v.contains(' ') || v.length < 3) {
                                  return 'Minimal 3 karakter, tanpa spasi.';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            _buildInputField(
                              label: 'Nomor Induk Kependudukan (NIK KTP)',
                              hint: '16 digit sesuai KTP',
                              controller: _nikController,
                              bg: inputBg,
                              textColor: textPrimary,
                              border: borderColor,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final v = (value ?? '').trim();
                                if (v.isEmpty) return 'NIK KTP wajib diisi.';
                                if (!RegExp(r'^\d{8,20}$').hasMatch(v)) {
                                  return 'NIK KTP tidak valid (8-20 digit angka).';
                                }
                                return null;
                              },
                            ),
                          ],

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
                              if (!RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(v)) {
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
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
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
                              if (v.length < 6) {
                                return 'Password minimal 6 karakter.';
                              }
                              return null;
                            },
                          ),

                          const Divider(
                            height: 64,
                            thickness: 1,
                            color: Color(0xFFF1F5F9),
                          ),

                          // Info pribadi / toko
                          Text(
                            _isMerchant
                                ? 'Informasi Toko Makanan'
                                : (_isDriverUmum
                                      ? 'Informasi Driver Umum (KTP)'
                                      : (_isDriverMahasiswa
                                            ? 'Informasi Driver Mahasiswa (KTM)'
                                            : 'Informasi Mahasiswa (KTM)')),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildInputField(
                            label: _isMerchant ? 'Nama Pemilik Toko' : 'Nama Lengkap',
                            hint: _isMerchant
                                ? 'Nama pengelola / pemilik warung'
                                : (_isDriverUmum ? 'Sesuai KTP' : 'Sesuai KTM'),
                            controller: _nameController,
                            bg: inputBg,
                            textColor: textPrimary,
                            border: borderColor,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return _isMerchant
                                    ? 'Nama pemilik wajib diisi.'
                                    : 'Nama lengkap wajib diisi.';
                              }
                              return null;
                            },
                          ),

                          if (_isMerchant) ...[
                            const SizedBox(height: 20),
                            _buildMerchantSection(
                              isDark: isDark,
                              inputBg: inputBg,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              borderColor: borderColor,
                            ),
                          ],

                          if (_isStudentRole) ...[
                            const SizedBox(height: 20),
                            _buildFacultyField(
                              bg: inputBg,
                              textColor: textPrimary,
                              textSecondary: textSecondary,
                              border: borderColor,
                              isDark: isDark,
                            ),
                            if (_isTeknikSelected) ...[
                              const SizedBox(height: 20),
                              _buildTeknikMajorField(
                                bg: inputBg,
                                textColor: textPrimary,
                                textSecondary: textSecondary,
                                border: borderColor,
                                isDark: isDark,
                              ),
                            ],
                          ],

                          const SizedBox(height: 24),

                          // Upload KTM / KTP
                          _buildSectionLabel(
                            _isMerchant
                                ? 'Unggah Foto $_docLabel (Opsional)'
                                : 'Unggah Foto $_docLabel',
                            textPrimary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isMerchant
                                ? 'Boleh dilampirkan sebagai verifikasi pemilik/warung makanan.'
                                : (_isDriverUmum
                                      ? 'Driver umum wajib melampirkan foto KTP untuk verifikasi admin.'
                                      : 'KTM dipakai untuk verifikasi status mahasiswa.'),
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDocUploadBox(
                            isDark,
                            textSecondary,
                            borderColor,
                          ),
                          if (_docError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _docError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],

                          // Jadwal kuliah (mahasiswa & driver mahasiswa)
                          if (_isStudentRole) ...[
                            const Divider(
                              height: 64,
                              thickness: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            Text(
                              'Jadwal Kuliah (Senin – Jumat)',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Isi jadwal kuliahmu supaya driver dan admin tahu kapan kamu sibuk. '
                              'Minimal satu mata kuliah.',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(5, (i) {
                              final day = i + 1;
                              return _buildDayScheduleCard(
                                day: day,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                inputBg: inputBg,
                                borderColor: borderColor,
                              );
                            }),
                            if (_scheduleError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _scheduleError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                              style: TextStyle(
                                color: textSecondary.withOpacity(0.6),
                                fontSize: 12,
                              ),
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
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05),
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

  Future<void> _pickDocImage() async {
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
      _docImage = picked;
      _docBytes = bytes;
      _docError = null;
    });
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    final bool formValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _docError = (!_isMerchant && _docImage == null)
          ? 'Foto $_docLabel wajib diunggah.'
          : null;
      _scheduleError = (_isStudentRole && _totalSchedules == 0)
          ? 'Isi minimal satu jadwal kuliah.'
          : null;
    });
    if (!formValid || (!_isMerchant && _docImage == null)) return;
    if (_isStudentRole && _totalSchedules == 0) return;

    setState(() {
      _loading = true;
      _status = 'Memproses...';
    });

    try {
      final phone = _buildPhoneNumber();
      final username = _isStudentRole
          ? _nimController.text.trim()
          : (_isMerchant
                ? _merchantUsernameController.text.trim().toLowerCase()
                : _nikController.text.trim());

      // 1. Buat akun di Firebase Auth + profil di Firestore (users, wallets & login_index)
      final user = await _authService
          .register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            username: username,
            role: _role,
            nim: _isStudentRole ? _nimController.text.trim() : null,
            nik: _isDriverUmum ? _nikController.text.trim() : null,
            phone: phone,
            faculty: _isStudentRole ? _facultyController.text.trim() : null,
            jurusan: (_isStudentRole && _isTeknikSelected)
                ? _selectedTeknikMajor
                : null,
            storeName: _isMerchant ? _storeNameController.text.trim() : null,
            storeCategory: _isMerchant ? _storeCategory : null,
            storeAddress: _isMerchant ? _storeAddressController.text.trim() : null,
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final nowIso = DateTime.now().toIso8601String();

      // 1b. Jika Merchant, buat profil toko di koleksi `merchants/{uid}`
      if (_isMerchant) {
        final now = DateTime.now();
        final merchant = MerchantModel(
          id: user.uid,
          ownerUid: user.uid,
          name: _storeNameController.text.trim(),
          ownerName: _nameController.text.trim(),
          phone: phone,
          category: _storeCategory,
          address: _storeAddressController.text.trim(),
          latitude: _storeLat,
          longitude: _storeLng,
          bannerData: _storeBannerData,
          bannerHeadline: _storeBannerHeadlineController.text.trim(),
          bannerTheme: _storeBannerTheme,
          isOpen: true,
          menus: _merchantMenus,
          createdAt: now,
          updatedAt: now,
        );
        try {
          await MerchantService()
              .upsertMerchant(merchant)
              .timeout(const Duration(seconds: 20));
        } catch (_) {}
      }

      final extension = (_docImage?.name.contains('.') ?? false)
          ? _docImage!.name.split('.').last.toLowerCase()
          : 'jpg';
      final contentType = extension == 'jpg'
          ? 'image/jpeg'
          : 'image/$extension';
      final folder = _isDriverUmum || _isMerchant ? 'ktp' : 'ktm';
      final urlField = _isDriverUmum || _isMerchant ? 'ktpUrl' : 'ktmUrl';
      final storageField =
          _isDriverUmum || _isMerchant ? 'ktpStorage' : 'ktmStorage';

      // 2. Simpan jadwal kuliah Senin–Jumat ke StudentScheduleStore & users/{uid}/schedules
      if (_isStudentRole) {
        final localScheduleItems = <CourseScheduleItem>[];
        final rawScheduleMaps = <Map<String, dynamic>>[];
        int idxCounter = 0;
        _schedules.forEach((day, entries) {
          for (final entry in entries) {
            idxCounter++;
            localScheduleItems.add(
              CourseScheduleItem(
                id: 'reg_${DateTime.now().millisecondsSinceEpoch}_$idxCounter',
                courseName: entry.courseName,
                room: entry.room,
                dayOfWeek: day,
                startTime: entry.startTime,
                endTime: entry.endTime,
              ),
            );
            rawScheduleMaps.add({
              'userId': user.uid,
              'courseName': entry.courseName,
              'courseType': 'regular',
              'room': entry.room,
              'building': '',
              'dayOfWeek': day,
              'startTime': entry.startTime,
              'endTime': entry.endTime,
              'createdAt': nowIso,
            });
          }
        });
        StudentScheduleStore.setSchedules(localScheduleItems);

        try {
          final batch = FirebaseFirestore.instance.batch();
          batch.update(userRef, {
            'hasSchedule': true,
            'jadwalKuliah': rawScheduleMaps,
          });
          for (final sMap in rawScheduleMaps) {
            batch.set(userRef.collection('schedules').doc(), sMap);
          }
          await batch.commit().timeout(const Duration(seconds: 30));
        } catch (_) {}
      }

      // 3. Upload berkas identitas (KTM / KTP) ke Firebase Storage atau fallback ke Firestore
      if (_docImage != null && _docBytes != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child(folder)
              .child(user.uid)
              .child(
                '${folder}_${DateTime.now().millisecondsSinceEpoch}.$extension',
              );

          await storageRef
              .putData(_docBytes!, SettableMetadata(contentType: contentType))
              .timeout(const Duration(seconds: 15));
          final downloadUrl = await storageRef.getDownloadURL().timeout(
            const Duration(seconds: 12),
          );

          await userRef
              .update({
                urlField: downloadUrl,
                storageField: 'storage',
                '${folder}UploadedAt': nowIso,
              })
              .timeout(const Duration(seconds: 15));
        } catch (_) {
          // Fallback: simpan foto langsung di Firestore (subkoleksi users/{uid}/documents)
          try {
            if (_docBytes!.length <= 750 * 1024) {
              await userRef
                  .collection('documents')
                  .doc(folder)
                  .set({
                    'docType': folder,
                    'nik': _isDriverUmum ? _nikController.text.trim() : null,
                    'fileName': _docImage!.name,
                    'contentType': contentType,
                    'base64': base64Encode(_docBytes!),
                    'uploadedAt': nowIso,
                  })
                  .timeout(const Duration(seconds: 15));
            }
            await userRef
                .update({
                  storageField: 'firestore',
                  '${folder}UploadedAt': nowIso,
                })
                .timeout(const Duration(seconds: 15));
          } catch (_) {}
        }
      }

      if (!mounted) return;
      _showSnack('Pendaftaran berhasil! Silakan masuk.', Colors.green);
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack(AuthService.readableError(e), Colors.red);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ─── Jadwal Kuliah ──────────────────────────────────────────────────────────

  Future<void> _addCourse(int day) async {
    final entry = await showDialog<_CourseEntry>(
      context: context,
      builder: (_) => _AddCourseDialog(dayName: kDayNames[day]),
    );
    if (entry == null) return;
    setState(() {
      _schedules[day]!.add(entry);
      _scheduleError = null;
    });
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
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildRoleSelector(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    const roles = [
      {
        'role': 'mahasiswa',
        'label': 'Mahasiswa',
        'sub': 'Penumpang',
        'icon': Icons.school_outlined,
      },
      {
        'role': 'driver_kampus',
        'label': 'Driver Mahasiswa',
        'sub': 'KTM + jadwal',
        'icon': Icons.two_wheeler_outlined,
      },
      {
        'role': 'driver_umum',
        'label': 'Driver Umum',
        'sub': 'Pakai KTP',
        'icon': Icons.badge_outlined,
      },
      {
        'role': 'merchant',
        'label': 'Merchant',
        'sub': 'Toko Makanan',
        'icon': Icons.storefront_rounded,
      },
    ];

    Widget buildRoleCard(Map<String, Object> r) {
      final role = r['role'] as String;
      final selected = _role == role;
      return GestureDetector(
        onTap: _loading ? null : () => _selectRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? kPrimary.withOpacity(isDark ? 0.18 : 0.22)
                : (isDark ? const Color(0xFF0F1405) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? kPrimary : border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                r['icon'] as IconData,
                size: 22,
                color: selected ? textPrimary : textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12.5,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    Text(
                      r['sub'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textSecondary, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: buildRoleCard(roles[0])),
            const SizedBox(width: 10),
            Expanded(child: buildRoleCard(roles[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: buildRoleCard(roles[2])),
            const SizedBox(width: 10),
            Expanded(child: buildRoleCard(roles[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildMerchantSection({
    required bool isDark,
    required Color inputBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final previewStore = MerchantModel(
      id: 'preview',
      ownerUid: 'preview',
      name: _storeNameController.text.trim().isEmpty
          ? 'Nama Toko Makanan Anda'
          : _storeNameController.text.trim(),
      category: _storeCategory,
      address: _storeAddressController.text.trim().isEmpty
          ? 'Alamat toko akan tampil di sini'
          : _storeAddressController.text.trim(),
      bannerData: _storeBannerData,
      bannerHeadline: _storeBannerHeadlineController.text.trim().isEmpty
          ? 'Promo spesial mahasiswa!'
          : _storeBannerHeadlineController.text.trim(),
      bannerTheme: _storeBannerTheme,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Nama Toko / Warung Makanan',
          hint: 'Contoh: Warung Ayam Geprek Bunda USU',
          controller: _storeNameController,
          bg: inputBg,
          textColor: textPrimary,
          border: borderColor,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (_isMerchant && (value ?? '').trim().isEmpty) {
              return 'Nama toko makanan wajib diisi.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Kategori Makanan',
          style: TextStyle(
            color: textPrimary.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _storeCategory,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF151C0A) : Colors.white,
            style: TextStyle(color: textPrimary, fontSize: 14.5),
            decoration: const InputDecoration(border: InputBorder.none),
            items: kMerchantCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _storeCategory = v);
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alamat Toko Makanan',
              style: TextStyle(
                color: textPrimary.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final gps = await MapRouteService.getCurrentDriverPosition(
                  campusFallback: MapRouteService.defaultKampusCenter,
                );
                final addr = await MapRouteService.reverseGeocodePosition(
                  gps.position,
                );
                if (!mounted) return;
                setState(() {
                  _storeLat = gps.position.latitude;
                  _storeLng = gps.position.longitude;
                  _storeAddressController.text = addr;
                });
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: const Color(0xFF6B8E00),
              ),
              icon: const Icon(Icons.my_location_rounded, size: 15),
              label: const Text(
                'Deteksi GPS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        _buildInputField(
          label: '',
          hint: 'Contoh: Kantin Pusat USU Lt. 1, Jl. Universitas No. 9',
          controller: _storeAddressController,
          bg: inputBg,
          textColor: textPrimary,
          border: borderColor,
          validator: (value) {
            if (_isMerchant && (value ?? '').trim().isEmpty) {
              return 'Alamat toko makanan wajib diisi.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        _buildInputField(
          label: 'Teks Promo Banner Toko (Opsional)',
          hint: 'Contoh: Gratis Es Teh setiap pesan Paket Komplit!',
          controller: _storeBannerHeadlineController,
          bg: inputBg,
          textColor: textPrimary,
          border: borderColor,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        Text(
          'Banner Toko (Tampil di Mahasiswa)',
          style: TextStyle(
            color: textPrimary.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        MerchantBannerView(
          merchant: previewStore,
          height: 132,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kMerchantBannerThemes.map((t) {
              final selected = _storeBannerTheme == t.key;
              return GestureDetector(
                onTap: () => setState(() => _storeBannerTheme = t.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: t.gradient),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected ? textPrimary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    t.label,
                    style: TextStyle(
                      color: t.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 60,
                  maxWidth: 960,
                );
                if (picked == null) return;
                final bytes = await picked.readAsBytes();
                if (bytes.length > 500 * 1024) {
                  _showSnack('Ukuran foto banner maksimal 500 KB.', Colors.red);
                  return;
                }
                setState(() {
                  _storeBannerData = MerchantService.bytesToDataUri(
                    bytes,
                    picked.name,
                  );
                });
              },
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Upload Foto Banner'),
            ),
            if (_storeBannerData.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _storeBannerData = ''),
                child: const Text(
                  'Pakai Tema',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Menu Makanan Awal (${_merchantMenus.length})',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final item = await showDialog<MerchantMenuItem>(
                  context: context,
                  builder: (_) => const _AddStarterMenuDialog(),
                );
                if (item != null && mounted) {
                  setState(() => _merchantMenus.add(item));
                }
              },
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: Color(0xFF6B8E00),
              ),
              label: const Text(
                'Tambah Menu',
                style: TextStyle(
                  color: Color(0xFF6B8E00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (_merchantMenus.isEmpty)
          Text(
            'Opsional: Tambahkan daftar menu sekarang atau setelah masuk ke dashboard toko.',
            style: TextStyle(color: textSecondary, fontSize: 12),
          )
        else
          ...List.generate(_merchantMenus.length, (i) {
            final m = _merchantMenus[i];
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          '${m.category} · ${MerchantService.formatRupiah(m.price)}',
                          style: TextStyle(color: textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => setState(() => _merchantMenus.removeAt(i)),
                  ),
                ],
              ),
            );
          }),
      ],
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
            child: Text(
              '+62',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
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
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: EdgeInsets.only(
            left: 16,
            right: suffixIcon == null ? 16 : 4,
          ),
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
                  onChanged: onChanged,
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

  Widget _buildFacultyField({
    required Color bg,
    required Color textColor,
    required Color textSecondary,
    required Color border,
    required bool isDark,
  }) {
    final query = _facultyController.text.trim().toLowerCase();
    final filteredOptions = query.isEmpty
        ? kFacultyOptions
        : kFacultyOptions
            .where((f) => f.toLowerCase().contains(query))
            .toList();
    final displayOptions =
        filteredOptions.isNotEmpty ? filteredOptions : kFacultyOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fakultas',
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.only(left: 16, right: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFacultyDropdownOpen ? kPrimary : border,
              width: _isFacultyDropdownOpen ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _facultyController,
                  style: TextStyle(color: textColor, fontSize: 14.5),
                  onTap: () {
                    setState(() => _isFacultyDropdownOpen = true);
                  },
                  onChanged: (_) {
                    setState(() {
                      _isFacultyDropdownOpen = true;
                      if (!_isTeknikSelected) {
                        _selectedTeknikMajor = null;
                      }
                    });
                  },
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Fakultas wajib dipilih atau diketik.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Pilih dari dropdown atau ketik nama fakultas...',
                    hintStyle: TextStyle(
                      color: textColor.withOpacity(0.35),
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_facultyController.text.isNotEmpty)
                IconButton(
                  tooltip: 'Hapus pilihan',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _facultyController.clear();
                      _selectedTeknikMajor = null;
                      _isFacultyDropdownOpen = true;
                    });
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: textSecondary,
                  ),
                ),
              IconButton(
                tooltip: _isFacultyDropdownOpen
                    ? 'Tutup daftar fakultas'
                    : 'Buka pilihan fakultas',
                onPressed: () {
                  setState(
                    () => _isFacultyDropdownOpen = !_isFacultyDropdownOpen,
                  );
                },
                icon: Icon(
                  _isFacultyDropdownOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.arrow_drop_down_circle_outlined,
                  color: _isFacultyDropdownOpen ? kPrimary : textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        if (_isFacultyDropdownOpen) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151C0A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimary.withOpacity(0.6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        filteredOptions.isEmpty
                            ? 'Gunakan ketikan manual atau pilih di bawah:'
                            : 'Pilih Fakultas (${displayOptions.length} pilihan):',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isFacultyDropdownOpen = false),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            color: Color(0xFF6B8E00),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: displayOptions.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: border.withOpacity(0.4),
                    ),
                    itemBuilder: (context, index) {
                      final option = displayOptions[index];
                      final isSelected =
                          _facultyController.text.trim().toLowerCase() ==
                          option.toLowerCase();
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _facultyController.text = option;
                            if (!_isTeknikSelected) {
                              _selectedTeknikMajor = null;
                            }
                            _isFacultyDropdownOpen = false;
                          });
                          FocusScope.of(context).unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.school_outlined,
                                size: 17,
                                color: isSelected
                                    ? const Color(0xFF6B8E00)
                                    : textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTeknikMajorField({
    required Color bg,
    required Color textColor,
    required Color textSecondary,
    required Color border,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jurusan Fakultas Teknik (Wajib)',
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedTeknikMajor,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF151C0A) : Colors.white,
            style: TextStyle(color: textColor, fontSize: 14.5),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Pilih jurusan Teknik...',
              hintStyle: TextStyle(
                color: textColor.withOpacity(0.35),
                fontSize: 13.5,
              ),
            ),
            items: kTeknikMajorOptions
                .map(
                  (major) => DropdownMenuItem<String>(
                    value: major,
                    child: Text(major),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() => _selectedTeknikMajor = val);
            },
            validator: (value) {
              if (_isTeknikSelected && (value == null || value.trim().isEmpty)) {
                return 'Jurusan wajib dipilih untuk Fakultas Teknik.';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocUploadBox(bool isDark, Color textSecondary, Color border) {
    return GestureDetector(
      onTap: _loading ? null : _pickDocImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? kPrimary.withOpacity(0.03)
              : const Color(0xFFF1F5F9).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _docError != null ? Colors.red : border,
            style: BorderStyle.solid,
          ),
        ),
        child: _docBytes == null
            ? Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Klik untuk ambil foto atau upload $_docLabel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG, atau HEIC (Maks. 5MB)',
                    style: TextStyle(
                      color: textSecondary.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _docBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _docImage?.name ?? 'Foto $_docLabel terpilih',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ganti',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDayScheduleCard({
    required int day,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color inputBg,
    required Color borderColor,
  }) {
    final entries = _schedules[day] ?? const <_CourseEntry>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kDayNames[day],
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _loading ? null : () => _addCourse(day),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: Color(0xFF6B8E00),
                ),
                label: const Text(
                  'Tambah',
                  style: TextStyle(
                    color: Color(0xFF6B8E00),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Belum ada mata kuliah.',
                style: TextStyle(
                  color: textSecondary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            )
          else
            ...List.generate(entries.length, (i) {
              final e = entries[i];
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2410) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.courseName,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${e.startTime} - ${e.endTime}'
                            '${e.room.isEmpty ? '' : ' • ${e.room}'}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _schedules[day]!.removeAt(i)),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
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
              color: kPrimary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
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
                      strokeWidth: 2.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text(
                'Daftar / Masuk',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Dialog untuk menambah satu mata kuliah pada hari tertentu.
class _AddCourseDialog extends StatefulWidget {
  final String dayName;

  const _AddCourseDialog({required this.dayName});

  @override
  State<_AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<_AddCourseDialog> {
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();

  TimeOfDay? _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _end = const TimeOfDay(hour: 10, minute: 0);
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _start : _end) ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
      _error = null;
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama mata kuliah wajib diisi.');
      return;
    }
    if (_start == null || _end == null) {
      setState(() => _error = 'Jam mulai dan jam selesai wajib dipilih.');
      return;
    }
    final startMinutes = _start!.hour * 60 + _start!.minute;
    final endMinutes = _end!.hour * 60 + _end!.minute;
    if (endMinutes <= startMinutes) {
      setState(() => _error = 'Jam selesai harus setelah jam mulai.');
      return;
    }

    Navigator.pop(
      context,
      _CourseEntry(
        courseName: name,
        room: _roomController.text.trim(),
        startTime: _format(_start!),
        endTime: _format(_end!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);
    final fieldBg = isDark ? const Color(0xFF0F1405) : const Color(0xFFF1F5F9);
    final border = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);

    InputDecoration decoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 14),
      filled: true,
      fillColor: fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1D2210) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Jadwal ${widget.dayName}',
        style: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: textPrimary),
              decoration: decoration('Nama mata kuliah'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _timeButton(
                    label: 'Mulai',
                    value: _start == null ? '--:--' : _format(_start!),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timeButton(
                    label: 'Selesai',
                    value: _end == null ? '--:--' : _format(_end!),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomController,
              style: TextStyle(color: textPrimary),
              decoration: decoration('Ruang / gedung (opsional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: TextStyle(color: textSecondary)),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Simpan',
            style: TextStyle(
              color: Color(0xFF6B8E00),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeButton({
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: textSecondary, fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStarterMenuDialog extends StatefulWidget {
  const _AddStarterMenuDialog();

  @override
  State<_AddStarterMenuDialog> createState() => _AddStarterMenuDialogState();
}

class _AddStarterMenuDialogState extends State<_AddStarterMenuDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = kMenuCategories.first;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (name.isEmpty || price <= 0) {
      setState(() => _error = 'Nama menu dan harga (Rp) wajib diisi.');
      return;
    }
    Navigator.pop(
      context,
      MerchantMenuItem(
        id: 'menu_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        price: price,
        description: _descCtrl.text.trim(),
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1D2210) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Tambah Menu Toko',
        style: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nama Menu (cth: Ayam Geprek)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textPrimary),
              decoration: const InputDecoration(
                labelText: 'Harga (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: kMenuCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              style: TextStyle(color: textPrimary),
              decoration: const InputDecoration(
                labelText: 'Deskripsi Singkat (Opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: TextStyle(color: textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.black,
          ),
          onPressed: _save,
          child: const Text(
            'Simpan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
