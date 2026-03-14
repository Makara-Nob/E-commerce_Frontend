import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'order_success_screen.dart';
import '../../theme/app_colors.dart';

class AbaCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> paywayPayload;
  final String paywayApiUrl;

  const AbaCheckoutScreen({
    super.key,
    required this.paywayPayload,
    required this.paywayApiUrl,
  });

  @override
  State<AbaCheckoutScreen> createState() => _AbaCheckoutScreenState();
}

class _AbaCheckoutScreenState extends State<AbaCheckoutScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  String? _qrImageBase64;
  String? _deeplink;
  String? _qrString;
  String? _amount;
  String? _tranId;

  @override
  void initState() {
    super.initState();
    _amount = widget.paywayPayload['amount']?.toString();
    _fetchAbaPaymentDetails();
  }

  Future<void> _fetchAbaPaymentDetails() async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(widget.paywayApiUrl));
      
      widget.paywayPayload.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (!mounted) return;

      if (data['status']?['code'] == '00') {
        setState(() {
          _isLoading = false;
          // Extract the base64 part: "data:image/png;base64,iVBORw0KGgo..."
          final qrImageRaw = data['qrImage'] as String?;
          if (qrImageRaw != null && qrImageRaw.contains(',')) {
            _qrImageBase64 = qrImageRaw.split(',')[1];
          }
          _deeplink = data['abapay_deeplink'];
          _qrString = data['qrString'];
          _tranId = data['status']['tran_id'];
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = data['status']?['message'] ?? 'Payment initialization failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect to ABA PayWay: $e';
      });
    }
  }

  Future<void> _launchAbaApp() async {
    if (_deeplink == null) return;
    final uri = Uri.parse(_deeplink!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch ABA Mobile App. Please scan the QR code instead.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('ABA PayWay', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(), // User can cancel
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryLight,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryStart),
            const SizedBox(height: 24),
            Text('Generating secure payment...', 
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondaryLight),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.errorLight),
              const SizedBox(height: 16),
              Text('Payment Error', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ).animate().fadeIn();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Scan KHQR to Pay',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ).animate().fadeIn().slideY(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            'Open ABA Mobile and scan this QR code or tap the button below to pay directly.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2),
          const SizedBox(height: 32),
          
          // QR Code Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryStart.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_qrImageBase64 != null)
                  Image.memory(
                    base64Decode(_qrImageBase64!),
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack)
                else
                  const SizedBox(
                    width: 250,
                    height: 250,
                    child: Center(child: Icon(Icons.qr_code_scanner, size: 64, color: AppColors.textTertiaryLight)),
                  ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondaryLight)),
                    Text('\$${_amount ?? "0.00"}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryStart)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transaction ID', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
                    Text(_tranId ?? '-', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 48),
          
          // Pay with App Button
          if (_deeplink != null)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _launchAbaApp,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryStart,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open ABA Mobile App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            
          const SizedBox(height: 16),
          
          // Skip / Done Mock Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryStart, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('I have made the payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryStart)),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}
