
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

class AbaWebViewScreen extends StatefulWidget {
  final Map<String, dynamic>? paywayPayload;
  final String? paywayApiUrl;
  final String? methodName;
  final String? htmlContent;
  final String? initialUrl;
  final String? successUrl;
  final String? cancelUrl;

  const AbaWebViewScreen({
    super.key,
    this.paywayPayload,
    this.paywayApiUrl,
    this.methodName,
    this.htmlContent,
    this.initialUrl,
    this.successUrl,
    this.cancelUrl,
  });

  @override
  State<AbaWebViewScreen> createState() => _AbaWebViewScreenState();
}

class _AbaWebViewScreenState extends State<AbaWebViewScreen>
    with TickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onWebResourceError: (WebResourceError error) {},
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
              _fadeController.forward();
              _pulseController.stop();
            }
          },
          onNavigationRequest: (request) async {
            final url = request.url;
            
            // Check explicit URLs from paywayPayload (old flow)
            final pReturnUrl = widget.paywayPayload?['return_url'] as String?;
            final pSuccessUrl = widget.paywayPayload?['continue_success_url'] as String?;
            final pCancelUrl = widget.paywayPayload?['cancel_url'] as String?;
            final pCofSuccessUrl = widget.paywayPayload?['continue_add_card_success_url'] as String?;

            bool shouldPop = false;

            // 1. Check explicit URLs from payload
            if ((pReturnUrl != null && url.startsWith(pReturnUrl)) ||
                (pSuccessUrl != null && url.startsWith(pSuccessUrl)) ||
                (pCancelUrl != null && url.startsWith(pCancelUrl)) ||
                (pCofSuccessUrl != null && url.startsWith(pCofSuccessUrl))) {
              shouldPop = true;
            }
            
            // 2. Check explicit URLs from widget properties (new flow)
            if (widget.successUrl != null && url.startsWith(widget.successUrl!)) {
              shouldPop = true;
            }
            if (widget.cancelUrl != null && url.startsWith(widget.cancelUrl!)) {
              shouldPop = true;
            }

            // 3. Robust fallback: Intercept any redirect to our backend's payway-webhook
            // This prevents the "Render" loading screen from appearing in the WebView.
            if (url.contains('payway-webhook')) {
              shouldPop = true;
            }

            if (shouldPop) {
              debugPrint('Intercepted PayWay redirect: $url - Popping WebView after 200ms');
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) Navigator.of(context).pop();
              });
              return NavigationDecision.prevent;
            }

            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              try {
                final Uri uri = Uri.parse(url);
                launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Could not launch custom scheme: $e');
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
        _controller.loadRequest(Uri.parse(widget.initialUrl!));
      } else if (widget.htmlContent != null) {
        _controller.loadHtmlString(widget.htmlContent!);
      } else if (widget.paywayPayload != null && widget.paywayApiUrl != null) {
        debugPrint('--- BUILDING MULTIPART FORM POST TO ${widget.paywayApiUrl} ---');

        final StringBuffer formFields = StringBuffer();
        widget.paywayPayload!.forEach((key, value) {
          final escapedValue = value
              .toString()
              .replaceAll('&', '&amp;')
              .replaceAll('"', '&quot;')
              .replaceAll("'", '&#x27;')
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;');
          debugPrint('[ABA Payload] $key: $value');
          formFields.write('<input type="hidden" name="$key" value="$escapedValue">');
        });

        final String html = '''
<!DOCTYPE html>
<html>
  <head><meta charset="utf-8"></head>
  <body>
    <form id="payway_form" action="${widget.paywayApiUrl}" method="POST" enctype="multipart/form-data">
      $formFields
    </form>
    <script>document.getElementById("payway_form").submit();</script>
  </body>
</html>''';

        _controller.loadHtmlString(html, baseUrl: widget.paywayApiUrl);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _isCofFlow =>
      widget.methodName?.toLowerCase().contains('card') == true ||
      widget.paywayPayload?.containsKey('continue_add_card_success_url') == true;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Column(
          children: [
            _buildHeader(context),
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC6A664)),
                minHeight: 2,
              ),
            Expanded(
              child: Stack(
                children: [
                  // Loading state
                  if (_isLoading) _buildLoadingState(),

                  // WebView (fades in when loaded)
                  AnimatedOpacity(
                    opacity: _isLoading ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: WebViewWidget(controller: _controller),
                  ),
                ],
              ),
            ),
            // Security footer
            _buildSecurityFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Top bar with close + title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.methodName ?? 'ABA PayWay',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balance the close button
              ],
            ),
          ),

          // Payment info strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                // ABA Logo/badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BCD4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ABA PayWay',
                        style: TextStyle(
                          color: Color(0xFF00BCD4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Secure badge
                Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFF4CAF50), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'SSL Secured',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated card icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C2C2C), Color(0xFF5A5A5A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2C2C2C).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isCofFlow
                        ? Icons.credit_card_rounded
                        : Icons.payment_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          Text(
            _isCofFlow ? 'Preparing Secure\nCard Form...' : 'Loading Payment\nGateway...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Connecting to ABA PayWay',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 36),

          // Shimmer placeholder cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                _buildShimmerRow(width: double.infinity, height: 48),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildShimmerRow(width: double.infinity, height: 48)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildShimmerRow(width: double.infinity, height: 48)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildShimmerRow(width: double.infinity, height: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerRow({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.grey.shade200,
              Colors.grey.shade100,
              _pulseAnimation.value,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 13, color: Colors.white.withOpacity(0.4)),
          const SizedBox(width: 6),
          Text(
            'Your payment is encrypted & secured by ABA PayWay',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
