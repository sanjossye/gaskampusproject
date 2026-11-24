import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/gas_faces.dart';

const Color _lime = Color(0xFFC0F637);
const Color _limeDeep = Color(0xFF8DBF1A);
const Color _ink = Color(0xFF0A0F02);
const Color _success = Color(0xFF22A559);
const Color _unpaidAmber = Color(0xFFD97706);

/// Halaman khusus "Pembayaran Berhasil" / "Pesanan Berhasil" (dipakai untuk top up GasPay dan
/// pembayaran perjalanan / makanan: GasPay, QRIS, maupun tunai).
class PaymentSuccessScreen extends StatefulWidget {
  final String title;
  final String receiverName;
  final String receiverSub;
  final String amountLabel;
  final String amountCaption;
  final bool isPaid;
  final String? paymentStatusNote;
  final List<MapEntry<String, String>> details;
  final VoidCallback? onDone;

  const PaymentSuccessScreen({
    super.key,
    this.title = 'Pembayaran Berhasil!',
    required this.receiverName,
    required this.receiverSub,
    required this.amountLabel,
    this.amountCaption = 'Nominal Transaksi',
    this.isPaid = true,
    this.paymentStatusNote,
    this.details = const [],
    this.onDone,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final DateTime _paidAt;

  @override
  void initState() {
    super.initState();
    _paidAt = DateTime.now();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final d = _paidAt;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} • ${two(d.hour)}:${two(d.minute)}:${two(d.second)} WIB';
  }

  String get _receiptText {
    final buf = StringBuffer()
      ..writeln('GasKampus • ${widget.title}')
      ..writeln(_dateLabel)
      ..writeln('Penerima: ${widget.receiverName}')
      ..writeln(widget.receiverSub)
      ..writeln('${widget.amountCaption}: ${widget.amountLabel}');
    for (final e in widget.details) {
      buf.writeln('${e.key}: ${e.value}');
    }
    return buf.toString().trim();
  }

  void _finish() {
    Navigator.of(context).pop();
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E1009) : const Color(0xFFF5F7F0);
    final card = isDark ? const Color(0xFF1C2414) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF0F1A02);
    final ts = isDark ? const Color(0xFF8A9E70) : const Color(0xFF6B7A5A);
    final line = isDark ? const Color(0xFF2A3518) : const Color(0xFFE8EDE0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: widget.isPaid ? _success : _unpaidAmber,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.isPaid
                                ? Icons.check_rounded
                                : Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _ctrl,
                        child: Column(
                          children: [
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: tp,
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.paymentStatusNote != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.paymentStatusNote!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _unpaidAmber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              _dateLabel,
                              style: TextStyle(color: ts, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _ctrl,
                        child: const GasMoodFace(
                          mood: GasMood.happy,
                          size: 92,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.of(context).padding.bottom + 18,
                ),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(top: BorderSide(color: line)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penerima', style: TextStyle(color: ts, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      widget.receiverName,
                      style: TextStyle(
                        color: tp,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.receiverSub,
                      style: TextStyle(color: ts, fontSize: 12.5),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.amountCaption,
                      style: TextStyle(color: ts, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.amountLabel,
                      style: TextStyle(
                        color: tp,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.details.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Divider(color: line, height: 1),
                      const SizedBox(height: 10),
                      ...widget.details.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 92,
                                child: Text(
                                  e.key,
                                  style: TextStyle(color: ts, fontSize: 12.5),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.value,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: tp,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _finish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lime,
                          foregroundColor: _ink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _receiptText));
                        },
                        icon: const Icon(
                          Icons.ios_share_rounded,
                          size: 18,
                          color: _limeDeep,
                        ),
                        label: const Text(
                          'Salin Resi',
                          style: TextStyle(
                            color: _limeDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
