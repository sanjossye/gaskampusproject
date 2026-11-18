import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);
const Color kBackgroundLight = Color(0xFFF7F8F5);
const Color kBackgroundDark = Color(0xFF1D2210);

class DriverUmumJadwalScreen extends StatefulWidget {
  final VoidCallback onBack;

  const DriverUmumJadwalScreen({super.key, required this.onBack});

  @override
  State<DriverUmumJadwalScreen> createState() => _DriverUmumJadwalScreenState();
}

class _DriverUmumJadwalScreenState extends State<DriverUmumJadwalScreen> {
  int _selectedDay = 5;
  final int _currentMonth = 11;
  final int _currentYear = 2026;
  bool _isCalendarExpanded = false;

  static const List<String> _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _dayHeaders = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  int _getFirstDayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday % 7;
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kBackgroundDark : kBackgroundLight;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334110) : const Color(0xFFE2E8F0);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: widget.onBack,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Icon(Icons.arrow_back, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Shift & Jadwal Operasional',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calendar Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_monthNames[_currentMonth]} $_currentYear',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Target: 40 Jam Kerja / Minggu',
                                      style: TextStyle(color: textMutedColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isCalendarExpanded
                                        ? Icons.calendar_view_week
                                        : Icons.calendar_month,
                                    color: kPrimary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isCalendarExpanded = !_isCalendarExpanded;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isCalendarExpanded)
                              _buildFullCalendarGrid(isDark, textColor)
                            else
                              _buildCompactWeek(textColor),
                          ],
                        ),
                      ),
                    ),

                    // Target Jam Kerja Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.timer_outlined, color: kPrimary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Jam Online Minggu Ini',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        '28 / 40 Jam',
                                        style: TextStyle(
                                          color: kPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: 28 / 40,
                                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                      color: kPrimary,
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Shift Hari Ini Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled, color: kPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Shift Operasional Hari Ini',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List Shift
                    _buildShiftCard(
                      isDark: isDark,
                      title: 'Shift Pagi · Jam Sibuk Kuliah Masuk',
                      time: '06:30 - 11:30',
                      zone: 'Zona A & B (Fak. Teknik & Vokasi USU)',
                      status: 'Selesai',
                      statusColor: Colors.grey,
                      icon: Icons.wb_sunny_outlined,
                      textColor: textColor,
                      textMutedColor: textMutedColor,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildShiftCard(
                      isDark: isDark,
                      title: 'Shift Siang · Jam Makan & Pindah Kelas',
                      time: '11:30 - 15:30',
                      zone: 'Zona B & C (Dr. Mansyur & Biro Rektor USU)',
                      status: 'Aktif Narik',
                      statusColor: kPrimary,
                      icon: Icons.electric_bike,
                      textColor: textColor,
                      textMutedColor: textMutedColor,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                    _buildShiftCard(
                      isDark: isDark,
                      title: 'Shift Sore/Malam · Jam Bubar Kampus',
                      time: '16:00 - 21:00',
                      zone: 'Seluruh Zona Kampus (Stasiun Medan & Kosan Sumber)',
                      status: 'Mendatang',
                      statusColor: Colors.blueAccent,
                      icon: Icons.nightlight_round,
                      textColor: textColor,
                      textMutedColor: textMutedColor,
                      cardBg: cardBg,
                      borderColor: borderColor,
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

  Widget _buildCompactWeek(Color textColor) {
    final List<Map<String, dynamic>> weekDays = [
      {'name': 'Sen', 'date': '2'},
      {'name': 'Sel', 'date': '3'},
      {'name': 'Rab', 'date': '4'},
      {'name': 'Kam', 'date': '5'},
      {'name': 'Jum', 'date': '6'},
      {'name': 'Sab', 'date': '7'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((d) {
        final isActive = d['date'] == '$_selectedDay';
        return GestureDetector(
          onTap: () => setState(() => _selectedDay = int.parse(d['date'])),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  d['name'],
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  d['date'],
                  style: TextStyle(
                    color: isActive ? Colors.black : textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFullCalendarGrid(bool isDark, Color textColor) {
    final int firstDay = _getFirstDayOfMonth(_currentYear, _currentMonth);
    final int daysInMonth = _getDaysInMonth(_currentYear, _currentMonth);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _dayHeaders
              .map((h) => Text(h, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)))
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: 35,
          itemBuilder: (context, index) {
            final dayNumber = index - firstDay + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }
            final isSelected = dayNumber == _selectedDay;
            return GestureDetector(
              onTap: () => setState(() => _selectedDay = dayNumber),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: isSelected ? Colors.black : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShiftCard({
    required bool isDark,
    required String title,
    required String time,
    required String zone,
    required String status,
    required Color statusColor,
    required IconData icon,
    required Color textColor,
    required Color textMutedColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(zone, style: TextStyle(color: textMutedColor, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
