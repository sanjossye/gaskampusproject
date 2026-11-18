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
  List<FareTier> _currentTiers = List.from(FarePricingService.defaultTiers);
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final stream = FarePricingService.streamFareTiers();
      final tiers = await stream.first.timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _currentTiers = List.from(tiers);
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
    _controllers.clear();
    for (final tier in _currentTiers) {
      _controllers[tier.id] = TextEditingController(text: tier.price.toString());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveTiers() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final updatedList = <FareTier>[];
      for (final tier in _currentTiers) {
        final text = _controllers[tier.id]?.text.trim() ?? '';
        final parsedPrice = int.tryParse(text) ?? tier.price;
        updatedList.add(FareTier(
          id: tier.id,
          minKm: tier.minKm,
          maxKm: tier.maxKm,
          price: parsedPrice,
        ));
      }

      await FarePricingService.saveFareTiers(updatedList);

      if (mounted) {
        setState(() {
          _currentTiers = updatedList;
          _isSaving = false;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✓ Tarif ojek berhasil diperbarui & sinkron ke seluruh pengguna!'),
            backgroundColor: Color(0xFF2E7D32),
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
          _syncControllers();
          _isSaving = false;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Tarif dikembalikan ke standar awal 10 tier')),
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
      height: MediaQuery.of(context).size.height * 0.88,
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
                        'Tabel penarifan berbasis jarak (Distance Tiered)',
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                            tier.label,
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
                            '* Untuk jarak di atas 30 km, sistem otomatis menambahkan Rp 1.500 per kilometer berikutnya.',
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
