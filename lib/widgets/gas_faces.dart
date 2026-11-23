import 'package:flutter/material.dart';

/// Palet identitas GasKampus (sama dengan logo aplikasi: lime + hitam).
const Color _kLime = Color(0xFFC0F637);
const Color _kInk = Color(0xFF0A0F02);
const Color _kMuted = Color(0xFFB9BFAA);

enum GasMood { sad, neutral, happy }

/// Wajah ekspresi berbentuk logo GasKampus (kotak lime berbingkai hitam).
/// Dipakai untuk rating driver: sedih, biasa saja, senang. Tanpa teks.
class GasMoodFace extends StatelessWidget {
  final GasMood mood;
  final double size;
  final bool active;

  const GasMoodFace({
    super.key,
    required this.mood,
    this.size = 56,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MoodFacePainter(mood: mood, active: active),
    );
  }
}

class _MoodFacePainter extends CustomPainter {
  final GasMood mood;
  final bool active;

  _MoodFacePainter({required this.mood, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Bingkai hitam logo
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.27)),
      Paint()..color = _kInk,
    );

    // Bidang lime (abu-abu saat tidak dipilih)
    final inset = s * 0.075;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, s - inset * 2, s - inset * 2),
        Radius.circular(s * 0.2),
      ),
      Paint()..color = active ? _kLime : _kMuted,
    );

    final ink = Paint()
      ..color = _kInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;

    // Mata
    final eyeY = s * 0.42;
    canvas.drawLine(
      Offset(s * 0.34, eyeY - s * 0.045),
      Offset(s * 0.34, eyeY + s * 0.045),
      ink,
    );
    canvas.drawLine(
      Offset(s * 0.66, eyeY - s * 0.045),
      Offset(s * 0.66, eyeY + s * 0.045),
      ink,
    );

    // Mulut
    final mouth = Path();
    switch (mood) {
      case GasMood.happy:
        mouth.moveTo(s * 0.29, s * 0.58);
        mouth.quadraticBezierTo(s * 0.5, s * 0.82, s * 0.71, s * 0.58);
        break;
      case GasMood.neutral:
        mouth.moveTo(s * 0.34, s * 0.65);
        mouth.lineTo(s * 0.66, s * 0.65);
        break;
      case GasMood.sad:
        mouth.moveTo(s * 0.31, s * 0.71);
        mouth.quadraticBezierTo(s * 0.5, s * 0.52, s * 0.69, s * 0.71);
        break;
    }
    canvas.drawPath(mouth, ink);
  }

  @override
  bool shouldRepaint(covariant _MoodFacePainter old) =>
      old.mood != mood || old.active != active;
}

/// Avatar zodiak khas GasKampus: mahasiswa bertopi toga dengan rasi bintang
/// zodiak di latarnya. Disimpan di profil sebagai `gas-avatar:<id>`.
class GasZodiac {
  final String id;
  final String label;
  final Color background;
  final List<Offset> stars;

  const GasZodiac(this.id, this.label, this.background, this.stars);
}

const Color _zLime = Color(0xFFC0F637);
const Color _zPale = Color(0xFFDDF99B);
const Color _zMint = Color(0xFFA6E8A8);
const Color _zTeal = Color(0xFF86DCC8);

const List<GasZodiac> kGasZodiacs = [
  GasZodiac('aries', 'Aries', _zLime, [
    Offset(.12, .62), Offset(.34, .42), Offset(.58, .30), Offset(.84, .22),
  ]),
  GasZodiac('taurus', 'Taurus', _zMint, [
    Offset(.14, .22), Offset(.36, .46), Offset(.56, .56), Offset(.80, .44),
    Offset(.90, .18),
  ]),
  GasZodiac('gemini', 'Gemini', _zTeal, [
    Offset(.18, .14), Offset(.30, .50), Offset(.18, .86), Offset(.70, .80),
    Offset(.82, .46), Offset(.72, .12),
  ]),
  GasZodiac('cancer', 'Cancer', _zPale, [
    Offset(.18, .30), Offset(.42, .48), Offset(.66, .40), Offset(.84, .64),
    Offset(.50, .84),
  ]),
  GasZodiac('leo', 'Leo', _zLime, [
    Offset(.14, .64), Offset(.28, .40), Offset(.52, .22), Offset(.76, .30),
    Offset(.82, .56), Offset(.60, .70),
  ]),
  GasZodiac('virgo', 'Virgo', _zMint, [
    Offset(.12, .20), Offset(.32, .34), Offset(.46, .60), Offset(.64, .46),
    Offset(.86, .30), Offset(.74, .84),
  ]),
  GasZodiac('libra', 'Libra', _zTeal, [
    Offset(.14, .70), Offset(.36, .56), Offset(.60, .56), Offset(.86, .70),
    Offset(.50, .30),
  ]),
  GasZodiac('scorpio', 'Scorpio', _zPale, [
    Offset(.10, .28), Offset(.28, .40), Offset(.46, .54), Offset(.66, .66),
    Offset(.84, .60), Offset(.90, .42),
  ]),
  GasZodiac('sagitarius', 'Sagitarius', _zLime, [
    Offset(.16, .80), Offset(.38, .58), Offset(.60, .40), Offset(.86, .16),
    Offset(.64, .14), Offset(.84, .38),
  ]),
  GasZodiac('capricorn', 'Capricorn', _zMint, [
    Offset(.12, .30), Offset(.34, .24), Offset(.58, .44), Offset(.84, .40),
    Offset(.70, .78),
  ]),
  GasZodiac('aquarius', 'Aquarius', _zTeal, [
    Offset(.10, .40), Offset(.30, .28), Offset(.48, .42), Offset(.68, .30),
    Offset(.88, .44), Offset(.60, .76),
  ]),
  GasZodiac('pisces', 'Pisces', _zPale, [
    Offset(.14, .22), Offset(.34, .40), Offset(.56, .30), Offset(.80, .50),
    Offset(.58, .80), Offset(.32, .68),
  ]),
];

const String kGasAvatarPrefix = 'gas-avatar:';

String gasAvatarIdFor(GasZodiac z) => '$kGasAvatarPrefix${z.id}';

GasZodiac? gasZodiacFromValue(String value) {
  final v = value.trim();
  if (!v.startsWith(kGasAvatarPrefix)) return null;
  final id = v.substring(kGasAvatarPrefix.length);
  for (final z in kGasZodiacs) {
    if (z.id == id) return z;
  }
  return null;
}

/// Gambar profil universal: avatar zodiak GasKampus, foto jaringan, atau
/// avatar mahasiswa bawaan jika kosong.
class GasProfileImage extends StatelessWidget {
  final String photoUrl;
  final double size;

  const GasProfileImage({super.key, required this.photoUrl, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final v = photoUrl.trim();
    final zodiac = gasZodiacFromValue(v);
    if (zodiac != null) return GasStudentAvatar(size: size, zodiac: zodiac);
    if (v.isEmpty || v.startsWith(kGasAvatarPrefix)) {
      return GasStudentAvatar(size: size);
    }
    return ClipOval(
      child: Image.network(
        v,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => GasStudentAvatar(size: size),
      ),
    );
  }
}

/// Avatar mahasiswa khas GasKampus: topi toga, jaket hitam, latar lime.
/// Dipakai sebagai foto profil bawaan sebelum pengguna memilih avatar.
class GasStudentAvatar extends StatelessWidget {
  final double size;
  final bool round;
  final GasZodiac? zodiac;

  const GasStudentAvatar({
    super.key,
    this.size = 44,
    this.round = true,
    this.zodiac,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StudentAvatarPainter(round: round, zodiac: zodiac),
    );
  }
}

class _StudentAvatarPainter extends CustomPainter {
  final bool round;
  final GasZodiac? zodiac;
  _StudentAvatarPainter({required this.round, this.zodiac});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final bgPath = round
        ? (Path()..addOval(Offset.zero & size))
        : (Path()
            ..addRRect(
              RRect.fromRectAndRadius(
                Offset.zero & size,
                Radius.circular(s * 0.28),
              ),
            ));
    canvas.save();
    canvas.clipPath(bgPath);

    // Latar (warna khas tiap zodiak)
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = zodiac?.background ?? _kLime,
    );

    // Rasi bintang zodiak
    final z = zodiac;
    if (z != null) {
      final pts = z.stars.map((o) => Offset(o.dx * s, o.dy * s)).toList();
      final linePaint = Paint()
        ..color = _kInk.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, linePaint);
      for (final p in pts) {
        canvas.drawCircle(p, s * 0.032, Paint()..color = _kInk);
        canvas.drawCircle(p, s * 0.013, Paint()..color = Colors.white);
      }
    }

    final ink = Paint()..color = _kInk;
    const skinColor = Color(0xFFF1C59A);
    final skin = Paint()..color = skinColor;

    // Jaket / bahu
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 1.02),
        width: s * 0.86,
        height: s * 0.58,
      ),
      ink,
    );
    // Garis kerah lime
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.40, s * 0.74)
        ..lineTo(s * 0.5, s * 0.86)
        ..lineTo(s * 0.60, s * 0.74),
      Paint()
        ..color = _kLime
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Leher
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.44, s * 0.60, s * 0.12, s * 0.18),
        Radius.circular(s * 0.04),
      ),
      skin,
    );

    // Kepala
    canvas.drawCircle(Offset(s * 0.5, s * 0.48), s * 0.19, skin);

    // Rambut samping
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.5, s * 0.47), radius: s * 0.205),
      3.3,
      2.6,
      true,
      ink,
    );
    canvas.drawCircle(Offset(s * 0.5, s * 0.50), s * 0.17, skin);

    // Topi toga: alas + papan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.35, s * 0.31, s * 0.30, s * 0.11),
        Radius.circular(s * 0.03),
      ),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.17, s * 0.30)
        ..lineTo(s * 0.5, s * 0.18)
        ..lineTo(s * 0.83, s * 0.30)
        ..lineTo(s * 0.5, s * 0.42)
        ..close(),
      ink,
    );
    // Aksen lime di papan
    canvas.drawCircle(Offset(s * 0.5, s * 0.30), s * 0.018, Paint()..color = _kLime);
    // Tali kuncir
    canvas.drawLine(
      Offset(s * 0.83, s * 0.30),
      Offset(s * 0.83, s * 0.43),
      Paint()
        ..color = _kInk
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(s * 0.83, s * 0.45), s * 0.032, ink);

    // Mata & senyum
    canvas.drawCircle(Offset(s * 0.43, s * 0.52), s * 0.018, ink);
    canvas.drawCircle(Offset(s * 0.57, s * 0.52), s * 0.018, ink);
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.44, s * 0.585)
        ..quadraticBezierTo(s * 0.5, s * 0.635, s * 0.56, s * 0.585),
      Paint()
        ..color = _kInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.022
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StudentAvatarPainter old) =>
      old.round != round || old.zodiac != zodiac;
}
