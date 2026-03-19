import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'order_success_screen.dart';
import 'aba_webview_screen.dart';
import 'aba_khqr_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';

class AbaCheckoutScreen extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> paywayPayload;
  final String paywayApiUrl;

  const AbaCheckoutScreen({
    super.key,
    required this.orderId,
    required this.paywayPayload,
    required this.paywayApiUrl,
  });

  @override
  State<AbaCheckoutScreen> createState() => _AbaCheckoutScreenState();
}

class _AbaCheckoutScreenState extends State<AbaCheckoutScreen> {
  bool _isCheckingPayment = false;
  String? _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.paywayPayload['amount']?.toString();
  }

  Future<void> _verifyPayment({bool silent = false}) async {
    if (_isCheckingPayment) return;

    if (!silent) setState(() => _isCheckingPayment = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final success = await orderProvider.checkPaymentStatus(widget.orderId);

      if (!mounted) return;

      if (success) {
        final order = orderProvider.currentOrder;
        if (order?.status == 'CONFIRMED') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
          );
          return;
        } else if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment is still pending. Please wait a moment or try again.'),
              backgroundColor: AppColors.primaryStart,
            ),
          );
        }
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Could not verify payment status'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _isCheckingPayment = false);
    }
  }

  void _navigateToAbaCheckout(String abaOption, String methodName) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    // DEBUG SNACK
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting $methodName flow (Option: $abaOption)...')),
    );

    // 1. Fetch fresh payload from backend to get correct hash
    final result = await orderProvider.getPaywayPayload(widget.orderId, abaOption);
    
    if (!mounted) return;

    if (result != null) {
      final paywayPayload = result['paywayPayload'] as Map<String, dynamic>;
      final paywayApiUrl = result['paywayApiUrl'] as String;

      // Show loading indicator while waiting for ABA response
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        print('POSTing to ABA: $paywayApiUrl with option: $abaOption');
        final response = await http.post(
          Uri.parse(paywayApiUrl),
          body: paywayPayload,
        );

        if (!mounted) return;
        Navigator.pop(context); // Remove loading dialog

        print('ABA Response Status: ${response.statusCode}');
        print('ABA Response Headers: ${response.headers}');

        if (response.statusCode == 200) {
          final String body = response.body.trim();
          final String contentType = response.headers['content-type'] ?? '';
          
          bool isJson = contentType.contains('application/json') || (body.startsWith('{') && body.endsWith('}'));
          
          if (isJson) {
            final jsonResponse = jsonDecode(body);
            
            if (jsonResponse['status']['code'] == '00') {
              final String? paymentUrl = jsonResponse['payment_link'] ?? 
                                         jsonResponse['checkout_url'] ?? 
                                         jsonResponse['url'] ??
                                         jsonResponse['abapay_deeplink']; // ✅ Support specific deeplink field
              
              print('ABA Response for $abaOption:');
              print(' - paymentUrl: $paymentUrl');
              print(' - abapay_deeplink: ${jsonResponse['abapay_deeplink']}');
              print(' - hasQrImage: ${jsonResponse.containsKey('qrImage')}');

              // If user DID NOT choose KHQR explicitly, prioritize the web/app link
              if (abaOption != 'abapay_khqr' && paymentUrl != null && paymentUrl.isNotEmpty) {
                if (!paymentUrl.startsWith('http')) {
                  print(' -> Launching Direct Deeplink: $paymentUrl');
                  launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
                  // Verify payment in background while user is in ABA app
                  _verifyPayment(silent: true);
                  return;
                }
                print(' -> Navigating to WebView/Deeplink (URL priority)');
                _openWebView(null, null, methodName, initialUrl: paymentUrl);
                return;
              }

              // Otherwise, if there is a QR image, show our custom QR screen
              // BUT ONLY if the user actually requested KHQR
              if (abaOption == 'abapay_khqr' && jsonResponse.containsKey('qrImage')) {
                print(' -> Navigating to Custom QR Screen');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AbaKhqrScreen(
                      qrImage: jsonResponse['qrImage'],
                      qrString: jsonResponse['qrString'],
                      amount: paywayPayload['amount'] ?? '0.00',
                      tranId: paywayPayload['tran_id'] ?? jsonResponse['status']['tran_id'] ?? 'N/A',
                      onVerify: _verifyPayment,
                    ),
                  ),
                );
                return;
              }
              
              // Fallback to URL if we are here (either no QR or it wasn't a KHQR request)
              if (paymentUrl != null && paymentUrl.isNotEmpty) {
                if (!paymentUrl.startsWith('http')) {
                  print(' -> Launching Direct Deeplink (Fallback): $paymentUrl');
                  launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
                  _verifyPayment(silent: true);
                  return;
                }
                print(' -> Navigating to WebView/Deeplink (Fallback)');
                _openWebView(null, null, methodName, initialUrl: paymentUrl);
                return;
              }

              // If JSON but no QR data and no URL, it might be an error or different format
              throw Exception('Success message found but no redirect data. Response: $body');
            } else {
              throw Exception('ABA Error (${jsonResponse['status']['code']}): ${jsonResponse['status']['message']}. Response: $body');
            }
          } else {
            // It's HTML, load it directly in WebView
            _openWebView(null, null, methodName, htmlContent: body);
          }
        } else if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307 || response.statusCode == 308) {
          // Handle redirect manually (common for COF point to card entry page)
          final String? location = response.headers['location'];
          if (location != null && location.isNotEmpty) {
            _openWebView(null, null, methodName, initialUrl: location);
          } else {
            throw Exception('Redirect received (code ${response.statusCode}) but no Location header found.');
          }
        } else {
          throw Exception('Server responded with status code ${response.statusCode}. Body: ${response.body}');
        }
      } catch (e) {
        if (!mounted) return;
        if (Navigator.canPop(context)) Navigator.pop(context); // Safety pop
        
        final String errorMsg = e.toString();
        print('❌ ABA Payment Error: $errorMsg');

        if (errorMsg.contains('Response:')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Debug Info'),
              content: SingleChildScrollView(
                child: SelectableText(errorMsg),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment Error: $errorMsg'),
              backgroundColor: AppColors.errorLight,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to initialize payment'),
          backgroundColor: AppColors.errorLight,
        ),
      );
    }
  }

  void _openWebView(Map<String, dynamic>? payload, String? url, String name, {String? htmlContent, String? initialUrl}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AbaWebViewScreen(
          paywayPayload: payload,
          paywayApiUrl: url,
          methodName: name,
          htmlContent: htmlContent,
          initialUrl: initialUrl,
        ),
      ),
    ).then((_) => _verifyPayment());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimaryLight,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummary(theme),
                const SizedBox(height: 32),
                Text(
                  'Choose way to pay',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                _buildPaymentMethodTile(
                  title: 'ABA KHQR',
                  subtitle: 'Scan to pay with any banking app',
                  svgAsset: 'assets/images/payment/ABA_BANK_khqr.svg',
                  onTap: () => _navigateToAbaCheckout('abapay_khqr', 'ABA KHQR'),
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodTile(
                  title: 'ABA Mobile App',
                  subtitle: 'Open ABA app to pay instantly',
                  svgAsset: 'assets/images/payment/ABA_BANK_khqr.svg',
                  onTap: () => _navigateToAbaCheckout('abapay_deeplink', 'ABA Mobile App'),
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodTile(
                  title: 'Credit/Debit Card',
                  subtitleWidget: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SvgPicture.asset(
                      'assets/images/payment/aba_card_group.svg',
                      height: 18,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  svgAsset: 'assets/images/payment/cards_icons.svg',
                  onTap: () => _navigateToAbaCheckout('cards', 'Credit/Debit Card'),
                ),
                const SizedBox(height: 48),
                _buildPaymentConfirmButton(),
              ],
            ),
          ),
        ),
        if (orderProvider.isLoading && !_isCheckingPayment)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryStart),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total to Pay', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              const SizedBox(height: 4),
              Text('\$${_amount ?? "0.00"}', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Order #${widget.orderId}',
              style: const TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    required String svgAsset,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              alignment: Alignment.center,
              child: SvgPicture.asset(
                svgAsset,
                width: svgAsset.contains('khqr') ? 50 : 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (subtitleWidget != null)
                    subtitleWidget
                  else if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildPaymentConfirmButton() {
    return Column(
      children: [
        const Text(
          'Already made the payment?',
          style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _isCheckingPayment ? null : _verifyPayment,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryStart, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isCheckingPayment
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Verify Payment Status', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryStart)
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}
