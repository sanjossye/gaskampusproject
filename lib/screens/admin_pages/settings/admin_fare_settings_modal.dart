import 'package:flutter/material.dart';
import '../../../services/fare_pricing_service.dart';

const Color kPrimary = Color(0xFF68CD5C);
const Color kBgDark = Color(0xFF1D2210);

/// Dialog / Modal Pengaturan Tarif Ojek Jarak Kampus khusus Admin
class AdminFareSettingsModal extends StatefulWidget {
  const AdminFareSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdminFareSettingsModal(),
    );
  }

  @override
  State<AdminFareSettingsModal> createState() => _AdminFareSettingsModalState();
}

class _AdminFareSettingsModalState extends State<AdminFareSettingsModal> {
  List<FareTier> _currentTiers = List.from(FarePricingService.currentTiers);
  final Map<int, TextEditingController> _controllers = {};
  late final TextEditingController _perKmController;
  late final TextEditingController _tier1DiscountController;
  bool _usePerKmPricing = FarePricingService.usePerKmPricing;
  bool _isLoading = true;
  bool _isSaving = false;

  int get _currentDiscountPercent =>
      ((1.0 - FarePricingService.tier1Multiplier) * 100).round().clamp(0, 90);

  @override
  void initState() {
    super.initState();
    _perKmController = TextEditingController(
      text: FarePricingService.pricePerKm.toString(),
    );
    _tier1DiscountController = TextEditingController(
      text: _currentDiscountPercent.toString(),
    );
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final stream = FarePricingService.streamFareTiers();
      final tiers = await stream.first.timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _currentTiers = List.from(tiers);
          _usePerKmPricing = FarePricingService.usePerKmPricing;
          _perKmController.text = FarePricingService.pricePerKm.toString();
          _tier1DiscountController.text = _currentDiscountPercent.toString();
          _syncControllers();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _syncControllers();
          _isLoading = false;
        });
      }
    }
  }

  void _syncControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    for (final tier in _currentTiers) {
      _controllers[tier.id] = TextEditingController(text: tier.price.toString());
    }
  }

  void _applyPerKmToTable() {
    final parsed = int.tryParse(_perKmController.text.trim()) ?? 5000;
    if (parsed <= 0) return;
    final generated = FarePricingService.buildTiersFromOneKmPrice(parsed);
    setState(() {
      _currentTiers = generated;
      for (final tier in _currentTiers) {
        _controllers[tier.id]?.text = tier.price.toString();
      }
    });
  }

  @override
  void dispose() {
    _perKmController.dispose();
    _tier1DiscountController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveTiers() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final rawDiscount = int.tryParse(_tier1DiscountController.text.trim());
      if (rawDiscount == null || rawDiscount < 0 || rawDiscount > 90) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Diskon Tier 1 (Searah) harus berupa angka antara 0–90%.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final tier1Mult =
          double.parse(((100 - rawDiscount) / 100.0).toStringAsFixed(2));

      final perKmVal =
          int.tryParse(_perKmController.text.trim()) ??
          FarePricingService.pricePerKm;

      final updatedList = <FareTier>[];
      for (final tier in _currentTiers) {
        final text = _controllers[tier.id]?.text.trim() ?? '';
        int parsedPrice = int.tryParse(text) ?? tier.price;
        if (tier.id == 1 && _usePerKmPricing && perKmVal > 0) {
          parsedPrice = perKmVal;
        }
        updatedList.add(FareTier(
          id: tier.id,
          minKm: tier.minKm,
          maxKm: tier.maxKm,
          price: parsedPrice,
        ));
      }

      await FarePricingService.saveFareTiers(
        updatedList,
        pricePerKm: perKmVal > 0 ? perKmVal : updatedList.first.price,
        usePerKmPricing: _usePerKmPricing,
        tier1Multiplier: tier1Mult,
      );

      if (mounted) {
        setState(() {
          _currentTiers = updatedList;
          _isSaving = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '✓ Tarif ojek (1 km = ${FarePricingService.formatRupiah(perKmVal)}) berhasil diterapkan ke seluruh akun!',
            ),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal menyimpan tarif: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetDefault() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      await FarePricingService.resetToDefault();
      if (mounted) {
        setState(() {
          _currentTiers = List.from(FarePricingService.defaultTiers);
          _perKmController.text = '5000';
          _tier1DiscountController.text = '30';
          _usePerKmPricing = true;
          _syncControllers();
          _isSaving = false;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Tarif dikembalikan ke standar awal (1 km = Rp 5.000)')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF161A0E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.price_change_rounded, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Tarif Ojek Kampus',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Atur harga saat 1 km & tabel tarif jarak seluruh akun',
                        style: TextStyle(color: subColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: textColor,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Card Utama: Pengaturan Harga 1 Km ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(isDark ? 0.14 : 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kPrimary.withOpacity(0.5), width: 1.4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.speed_rounded, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tarif Dasar 1 Kilometer (Saat 1 Km)',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tentukan berapa harga ojek untuk 1 km. Harga ini otomatis berlaku ke akun Mahasiswa & Driver.',
                                style: TextStyle(color: subColor, fontSize: 11.5),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: TextField(
                                        controller: _perKmController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          final parsed = int.tryParse(v.trim());
                                          if (parsed != null && parsed > 0) {
                                            _controllers[1]?.text = parsed.toString();
                                          }
                                        },
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        decoration: InputDecoration(
                                          prefixText: '1 Km = Rp ',
                                          prefixStyle: TextStyle(
                                            color: subColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          filled: true,
                                          fillColor: isDark ? Colors.black38 : Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: _applyPerKmToTable,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: Colors.black87,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                                    label: const Text(
                                      'Isi Tabel',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: Colors.green,
                                value: _usePerKmPricing,
                                onChanged: (val) => setState(() => _usePerKmPricing = val),
                                title: Text(
                                  'Hitung Proporsional per 1 Km (Jarak × Harga 1 Km)',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  _usePerKmPricing
                                      ? 'Aktif: Saat 1 km = harga di atas, > 1 km dikalikan jarak km.'
                                      : 'Nonaktif: Mengikuti rentang tabel 10 tier di bawah.',
                                  style: TextStyle(color: subColor, fontSize: 11),
                                ),
                              ),
                              const Divider(height: 18),
                              Row(
                                children: [
                                  const Icon(Icons.discount_outlined, color: Colors.green, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Diskon Tier 1 (Searah)',
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Default 30% (multiplier 0.70). Rentang valid: 0–90%.',
                                          style: TextStyle(color: subColor, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 96,
                                    height: 40,
                                    child: TextField(
                                      controller: _tier1DiscountController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        suffixText: ' %',
                                        suffixStyle: TextStyle(
                                          color: subColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: isDark ? Colors.black38 : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Header Tabel
                        Row(
                          children: [
                            Text(
                              'Daftar 10 Tingkat Jarak (Tabel Resmi)',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _isSaving ? null : _resetDefault,
                              icon: const Icon(Icons.restart_alt_rounded, size: 16),
                              label: const Text('Reset', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Tabel Tier
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2412) : const Color(0xFFF9FAF6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Header kolom
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        'No',
                                        style: TextStyle(
                                          color: subColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Rentang Jarak',
                                        style: TextStyle(
                                          color: subColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Tarif (Rp)',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: subColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // Baris list
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _currentTiers.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final tier = _currentTiers[index];
                                  final controller = _controllers[tier.id];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            '${tier.id}',
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            tier.id == 1 ? '${tier.label} (Termasuk 1 km)' : tier.label,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          height: 38,
                                          child: TextField(
                                            controller: controller,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.right,
                                            onChanged: (v) {
                                              if (tier.id == 1) {
                                                _perKmController.text = v.trim();
                                              }
                                            },
                                            style: TextStyle(
                                              color: isDark ? kPrimary : Colors.green[800],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                              prefixText: 'Rp ',
                                              prefixStyle: TextStyle(
                                                color: subColor,
                                                fontSize: 12,
                                              ),
                                              filled: true,
                                              fillColor: isDark
                                                  ? Colors.black26
                                                  : Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? Colors.white12
                                                      : Colors.black12,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '* Perubahan tarif di atas langsung aktif secara real-time di seluruh akun Mahasiswa dan Driver.',
                            style: TextStyle(color: subColor, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),

          // Tombol Simpan
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgCard,
                border: Border(
                  top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveTiers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan & Terapkan Tarif Baru',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
