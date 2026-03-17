import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFC0F637);

class DriverJadwalScreen extends StatefulWidget {
  final VoidCallback onBack;

  const DriverJadwalScreen({super.key, required this.onBack});

  @override
  State<DriverJadwalScreen> createState() => _DriverJadwalScreenState();
}

class _DriverJadwalScreenState extends State<DriverJadwalScreen> {
  int _selectedDay = 5; // Kamis tanggal 5 sebagai default aktif
  int _currentMonth = 10; // Oktober
  int _currentYear = 2023;
  bool _isCalendarExpanded = false;

  // Nama bulan
  static const List<String> _monthNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  // Nama hari singkat untuk kalender penuh
  static const List<String> _dayHeaders = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  // Hari pertama bulan (0=Minggu, 1=Senin, dst.)
  int _getFirstDayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday % 7; // Minggu=0
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
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
        final isActive = d['date'] == '$_selectedDay' &&
            _currentMonth == 10 &&
            _currentYear == 2023;
        return _buildDayItem(d['name'], d['date'], isActive, textColor);
      }).toList(),
    );
  }

  Widget _buildFullCalendarGrid(bool isDark, Color textColor) {
    final int firstDay = _getFirstDayOfMonth(_currentYear, _currentMonth);
    final int daysInMonth = _getDaysInMonth(_currentYear, _currentMonth);
    final Set<int> scheduledDays = {3, 5, 10, 12, 17, 19, 24, 26};

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildNavButton(
              icon: Icons.chevron_left,
              isDark: isDark,
              textColor: textColor,
              onTap: () {
                setState(() {
                  if (_currentMonth == 1) {
                    _currentMonth = 12;
                    _currentYear--;
                  } else {
                    _currentMonth--;
                  }
                });
              },
            ),
            const SizedBox(width: 16),
            _buildNavButton(
              icon: Icons.chevron_right,
              isDark: isDark,
              textColor: textColor,
              onTap: () {
                setState(() {
                  if (_currentMonth == 12) {
                    _currentMonth = 1;
                    _currentYear++;
                  } else {
                    _currentMonth++;
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: _dayHeaders.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: day == 'Min'
                        ? Colors.redAccent
                        : (isDark ? const Color(0xFF94A3B8) : Colors.grey[500]),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            mainAxisSpacing: 6,
            crossAxisSpacing: 0,
          ),
          itemCount: firstDay + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstDay) {
              return const SizedBox.shrink();
            }
            final day = index - firstDay + 1;
            final isSelected = day == _selectedDay;
            final hasSchedule = scheduledDays.contains(day);
            final isToday = day == 5 &&
                _currentMonth == 10 &&
                _currentYear == 2023; // contoh hari ini
            final colIndex = index % 7;
            final isSunday = colIndex == 0;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? kPrimary
                      : (isToday && !isSelected
                          ? kPrimary.withOpacity(0.15)
                          : Colors.transparent),
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : (isSunday
                                ? Colors.redAccent
                                : textColor),
                        fontSize: 13,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    if (hasSchedule)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black54 : kPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Ada jadwal kuliah',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: textColor, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final mutedBg = isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFF8FAFC);
    final dividerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);



    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: widget.onBack,
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
                  Text(
                    'Jadwal Kuliah',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Icon(Icons.search, color: textColor),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 120),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact Calendar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: mutedBg,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isCalendarExpanded = !_isCalendarExpanded;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      '${_monthNames[_currentMonth]} $_currentYear',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AnimatedRotation(
                                      turns: _isCalendarExpanded ? 0.5 : 0.0,
                                      duration: const Duration(milliseconds: 300),
                                      child: const Icon(Icons.expand_more, color: Colors.grey, size: 24),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            firstChild: _buildCompactWeek(textColor),
                            secondChild: _buildFullCalendarGrid(isDark, textColor),
                            crossFadeState: _isCalendarExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Kelas Hari Ini Section Header
                    Row(
                      children: [
                        Text(
                          'Kelas Hari Ini',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(height: 2, color: dividerColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Cards
                    _buildClassCard(
                      isDark: isDark,
                      title: 'Kalkulus II',
                      status: 'Ongoing',
                      time: '10:00 - 12:00',
                      location: 'Gedung A-101',
                      isOngoing: true,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      textMuted: Colors.grey,
                    ),

                    const SizedBox(height: 16),

                    _buildClassCard(
                      isDark: isDark,
                      title: 'Fisika Dasar',
                      status: 'Upcoming',
                      time: '13:30 - 15:30',
                      location: 'Gedung B-204',
                      isOngoing: false,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      textMuted: Colors.grey,
                    ),

                    const SizedBox(height: 16),

                    _buildPracticumCard(
                      isDark: isDark,
                      title: 'Praktikum Fisika',
                      subtitle: 'MATA KULIAH PRAKTIKUM',
                      status: 'Upcoming',
                      time: '15:45 - 17:45',
                      location: 'Lab Fisika 1',
                      cardBg: mutedBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      textMuted: Colors.grey,
                    ),

                    const SizedBox(height: 16),

                    _buildClassCard(
                      isDark: isDark,
                      title: 'Algoritma Pemrograman',
                      status: 'Upcoming',
                      time: '16:00 - 18:00',
                      location: 'Lab Komputer 2',
                      isOngoing: false,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      textMuted: Colors.grey,
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

  Widget _buildDayItem(String dayName, String date, bool isActive, Color textColor) {
    return Column(
      children: [
        Text(
          dayName.toUpperCase(),
          style: TextStyle(
            color: isActive ? kPrimary : Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? kPrimary : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            date,
            style: TextStyle(
              color: isActive ? Colors.black : textColor,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard({
    required bool isDark,
    required String title,
    required String status,
    required String time,
    required String location,
    required bool isOngoing,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? kPrimary.withOpacity(0.2)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isOngoing
                        ? (isDark ? kPrimary : Colors.green[800])
                        : textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: textMuted),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: textMuted),
                  const SizedBox(width: 8),
                  Text(
                    location,
                    style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPracticumCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required String status,
    required String time,
    required String location,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? []
                      : [const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: textMuted),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: textMuted),
                  const SizedBox(width: 8),
                  Text(
                    location,
                    style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}