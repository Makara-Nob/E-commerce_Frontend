import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';

// ── Isolated timer widget — only THIS rebuilds every second ─────────────────
class _CountdownBadge extends StatefulWidget {
  final int initialSeconds;
  const _CountdownBadge({required this.initialSeconds});

  @override
  State<_CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<_CountdownBadge>
    with SingleTickerProviderStateMixin {
  late int _secondsLeft;
  late Timer _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    if (_secondsLeft > 120) return const Color(0xFF00C853);
    if (_secondsLeft > 60) return const Color(0xFFFF9100);
    return const Color(0xFFD32F2F);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _timerColor.withOpacity(0.08 + _pulseController.value * 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _timerColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: _timerColor),
            const SizedBox(width: 4),
            Text(
              _formattedTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _timerColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Painter for the KHQR header with "tab" effect ─────────────────────
class _KhqrHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE21A1A)
      ..style = PaintingStyle.fill;

    const cornerRadius = 28.0;
    const tabWidth = 28.0;
    const tabTailHeight = 8.0;

    final path = Path();
    
    // Top Left
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    
    // Top Edge
    path.lineTo(size.width, 0);
    
    // Right Edge including downward tab
    path.lineTo(size.width, size.height); // Down to bottom of tab
    path.lineTo(size.width - tabWidth, size.height - tabTailHeight); // Diagonally up
    
    // Bottom Edge of red bar
    path.lineTo(0, size.height - tabTailHeight);
    
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Main screen — StatelessWidget, never rebuilds ────────────────────────────
class AbaKhqrScreen extends StatelessWidget {
  final String qrImage;
  final String qrString;
  final String amount;
  final String tranId;
  final VoidCallback onVerify;

  const AbaKhqrScreen({
    super.key,
    required this.qrImage,
    required this.qrString,
    required this.amount,
    required this.tranId,
    required this.onVerify,
  });


  @override
  Widget build(BuildContext context) {
    final String cleanBase64 =
    qrImage.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
    final imageBytes = base64Decode(cleanBase64);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Shop Icon ──
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF67C2A3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_basket_outlined, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 30),

            // ── The Ticket Card ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Red Header
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: CustomPaint(
                        painter: _KhqrHeaderPainter(),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/khqr/KHQR.svg',
                            height: 18,
                            placeholderBuilder: (_) => const Text(
                              'KHQR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Store & Price
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Text(
                            'Shopping Store',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                amount,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'USD',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SvgPicture.asset(
                        'assets/images/khqr/Divider.svg',
                        width: double.infinity,
                        fit: BoxFit.fill,
                      ),
                    ),

                    // QR Code
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Image.memory(
                        imageBytes,
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Actions Below Card ──────────────────────────────────────
            const Text(
              'Scan to Pay',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'or',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Download Button
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading QR to gallery...')),
                );
              },
              icon: const Icon(Icons.download_outlined, color: Color(0xFF00B4DB)),
              label: const Text(
                'Download QR',
                style: TextStyle(
                  color: Color(0xFF00B4DB),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
              child: Text(
                'and upload to Mobile Banking app supporting KHQR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Bottom Summary ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal:',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        '$amount USD',
                        style: TextStyle(color: Colors.grey[800], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      Text(
                        '$amount USD',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E), // Dark theme button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'I HAVE PAID',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 1,
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
    );
  }
}
