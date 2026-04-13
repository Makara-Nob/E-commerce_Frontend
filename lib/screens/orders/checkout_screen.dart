import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/pricing_provider.dart';
import '../../models/pricing/order_calculation.dart';
import '../../models/cart/cart_item.dart';
import '../../models/address/address_model.dart';
import '../../models/payment/saved_card.dart';
import '../../services/card_service.dart';
import '../../theme/app_colors.dart';
import '../profile/address_list_screen.dart';
import 'order_success_screen.dart';
import 'aba_webview_screen.dart';
import 'aba_khqr_screen.dart';
// ➕ NEW — InvoiceScreen replaces OrderSuccessScreen as post-payment destination
import 'invoice_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Payment method identifiers
// ─────────────────────────────────────────────────────────────────────────────
enum _PaymentChoice {
  khqr,
  abaApp,
  cards_new,
  savedCard,
}

class CheckoutScreen extends StatefulWidget {
  final List<CartItem>? directItems;
  const CheckoutScreen({super.key, this.directItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with WidgetsBindingObserver {
  // ── state ──────────────────────────────────────────────────────────────────
  AddressModel? _selectedAddress;
  _PaymentChoice _paymentChoice = _PaymentChoice.khqr;
  SavedCard? _selectedCard;

  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isInit = true;
  bool _isPlacingOrder = false;
  bool _isCheckingPayment = false;
  bool _isWaitingForReturn = false;
  bool _isConfirmingPayment = false;
  int? _placedOrderId;

  List<SavedCard> _savedCards = [];
  final _cardService = CardService();


  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final ap = Provider.of<AddressProvider>(context, listen: false);
      if (ap.addresses.isEmpty && !ap.isLoading) {
        ap.loadAddresses().then((_) {
          if (mounted) setState(() => _selectedAddress = ap.defaultAddress);
        });
      } else {
        _selectedAddress = ap.defaultAddress;
      }
      _isInit = false;
      _loadSavedCards();
      _triggerCalculation();
    }
  }

  void _triggerCalculation() {
    final pp = Provider.of<PricingProvider>(context, listen: false);

    List<Map<String, dynamic>> items;
    bool isBuyNow;

    if (widget.directItems != null && widget.directItems!.isNotEmpty) {
      items = widget.directItems!.map((i) => {
        'productId': i.product.id,
        'quantity': i.quantity,
        if (i.variantId != null) 'variantId': i.variantId!,
      }).toList();
      isBuyNow = true;
    } else {
      final cart = Provider.of<CartProvider>(context, listen: false).cart;
      if (cart == null || cart.items.isEmpty) return;
      items = cart.items.map((i) => {
        'productId': i.product.id,
        'quantity': i.quantity,
        if (i.variantId != null) 'variantId': i.variantId!,
      }).toList();
      isBuyNow = false;
    }

    pp.calculate(items: items, isBuyNow: isBuyNow);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForReturn) {
      _isWaitingForReturn = false;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _placedOrderId != null) _verifyPayment(_placedOrderId!);
      });
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  Future<void> _loadSavedCards() async {
    try {
      final cards = await _cardService.getSavedCards();
      if (mounted) setState(() => _savedCards = cards);
    } catch (_) {}
  }

  String _formatCurrency(double amount) =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);

  // ── verify payment ─────────────────────────────────────────────────────────
  Future<bool> _verifyPayment(int orderId, {bool silent = false}) async {
    if (_isCheckingPayment) return false;
    if (!silent) setState(() => _isCheckingPayment = true);
    try {
      final op = Provider.of<OrderProvider>(context, listen: false);
      final ok = await op.checkPaymentStatus(orderId);
      if (!mounted) return false;
      if (ok && op.currentOrder?.status == 'CONFIRMED') {
        if (widget.directItems == null) {
          Provider.of<CartProvider>(context, listen: false).clearLocalCart();
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => InvoiceScreen(order: op.currentOrder!),
          ),
        );
        return true; // ➕ stops KHQR polling timer
      } else if (!silent) {
        _showSnack('Payment still pending. Please wait a moment.', isError: false);
      }
    } finally {
      if (mounted && !silent) setState(() => _isCheckingPayment = false);
    }
    return false;
  }

  void _startPollingAfterWebView(int orderId) {
    int attempts = 0;
    if (mounted) _showSnack('Verifying payment, please wait...', isError: false);

    void poll() async {
      if (!mounted) return;
      attempts++;
      final success = await _verifyPayment(orderId, silent: true);
      if (success) return;

      if (attempts < 8) {
        Future.delayed(const Duration(seconds: 3), poll);
      } else {
        if (!mounted) return;
        setState(() => _isConfirmingPayment = false);
        // Cancel the PENDING order so it doesn't pollute the order list
        Provider.of<OrderProvider>(context, listen: false).cancelOrder(orderId);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Payment Not Confirmed'),
            content: const Text(
              'We could not verify your payment. Your order has been cancelled and no charge was made. Please try again.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // go back to cart
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }

    poll();
  }

  // ── place order then route by payment choice ───────────────────────────────
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAddress == null) {
      _showSnack('Please select a delivery address');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      List<Map<String, dynamic>> items = [];
      
      if (widget.directItems != null && widget.directItems!.isNotEmpty) {
        items = widget.directItems!.map((i) => {
          'productId': i.product.id,
          'quantity': i.quantity,
          if (i.variantId != null) 'variantId': i.variantId!,
        }).toList();
      } else {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        final cart = cartProvider.cart;

        if (cart == null || cart.items.isEmpty) {
          _showSnack('Cart is empty');
          return;
        }

        items = cart.items.map((i) => {
          'productId': i.product.id,
          'quantity': i.quantity,
          if (i.variantId != null) 'variantId': i.variantId!,
        }).toList();
      }

      final addr = _selectedAddress!;
      final fullAddress = '${addr.streetAddress}, ${addr.city}'
          '${addr.state != null ? ', ${addr.state}' : ''}'
          '${addr.zipCode != null ? ' ${addr.zipCode}' : ''}';

      final success = await orderProvider.createOrder(
        deliveryAddress: fullAddress,
        deliveryPhone: addr.phoneNumber,
        notes: _noteController.text,
        items: items,
        paymentMethod: 'ABA_PAYWAY',
        isBuyNow: widget.directItems != null,
      );

      if (!mounted) return;

      if (!success) {
        _showSnack(orderProvider.errorMessage ?? 'Failed to place order');
        return;
      }

      final order = orderProvider.currentOrder;

      if (order == null) {
        _showSnack('Order created but data missing.');
        return;
      }

      _placedOrderId = order.id;

      // ── route by chosen payment ───────────────────────────────────────────
      if (_paymentChoice == _PaymentChoice.savedCard && _selectedCard != null) {
        await _payByToken(order.id, _selectedCard!);
      } else if (order.paywayPayload != null && order.paywayApiUrl != null) {
        final abaOption = _paymentChoice == _PaymentChoice.khqr
            ? 'abapay_khqr'
            : _paymentChoice == _PaymentChoice.cards_new
                ? 'cards_new'
                : 'abapay_khqr_deeplink';
        await _processAbaPayment(
          orderId: order.id,
          abaOption: abaOption,
          methodName: _paymentChoice == _PaymentChoice.khqr
              ? 'ABA KHQR'
              : _paymentChoice == _PaymentChoice.cards_new
                  ? 'Credit / Debit Card'
                  : 'ABA Mobile App',
          orderProvider: orderProvider,
        );
      } else {
        // No payway payload → straight to success
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  Future<void> _payByToken(int orderId, SavedCard card) async {
    setState(() => _isConfirmingPayment = true);
    try {
      final ok = await _cardService.payByToken(orderId, card.index);
      if (!mounted) return;
      if (ok) {
        if (widget.directItems == null) {
          Provider.of<CartProvider>(context, listen: false).clearLocalCart();
        }
        // ➕ NEW — Navigate to InvoiceScreen with saved-card payment order data
        final op = Provider.of<OrderProvider>(context, listen: false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => InvoiceScreen(order: op.currentOrder!),
          ),
        );
        // BEFORE: MaterialPageRoute(builder: (_) => const OrderSuccessScreen())
      } else {
        // Cancel the PENDING order so it doesn't pollute the order list
        Provider.of<OrderProvider>(context, listen: false).cancelOrder(orderId);
        _showSnack('Card payment failed. Please try another payment method.');
      }
    } catch (e) {
      if (mounted) {
        // Also cancel on exception (e.g. ABA returned error code)
        Provider.of<OrderProvider>(context, listen: false).cancelOrder(orderId);
        _showSnack('Payment failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isConfirmingPayment = false);
    }
  }

  Future<void> _processAbaPayment({
    required int orderId,
    required String abaOption,
    required String methodName,
    required OrderProvider orderProvider,
  }) async {
    final result = await orderProvider.getPaywayPayload(orderId, abaOption);
    if (!mounted) return;

    if (result == null) {
      _showSnack(orderProvider.errorMessage ?? 'Failed to initialize payment');
      return;
    }

    final paywayPayload = result['paywayPayload'] as Map<String, dynamic>;
    final paywayApiUrl = result['paywayApiUrl'] as String;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final request = http.MultipartRequest('POST', Uri.parse(paywayApiUrl));
      paywayPayload.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (!mounted) return;
      Navigator.pop(context); // remove loading dialog

      if (response.statusCode == 200) {
        final body = response.body.trim();
        final ct = response.headers['content-type'] ?? '';
        final isJson =
            ct.contains('application/json') || (body.startsWith('{') && body.endsWith('}'));

        if (isJson) {
          final json = jsonDecode(body);
          if (json['status']['code'] == '00') {
            final paymentUrl = json['payment_link'] ??
                json['checkout_url'] ??
                json['url'] ??
                json['abapay_deeplink'];

            if (abaOption != 'abapay_khqr' && paymentUrl != null && (paymentUrl as String).isNotEmpty) {
              if (!paymentUrl.startsWith('http')) {
                await _launchDeeplink(paymentUrl, orderId);
                return;
              }
              _openWebView(null, null, methodName, initialUrl: paymentUrl);
              return;
            }

            if (abaOption == 'abapay_khqr' && json.containsKey('qrImage')) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AbaKhqrScreen(
                    qrImage: json['qrImage'],
                    qrString: json['qrString'],
                    amount: paywayPayload['amount'] ?? '0.00',
                    tranId: paywayPayload['tran_id'] ?? json['status']['tran_id'] ?? 'N/A',
                    // ➕ Now returns bool — true stops the polling timer in AbaKhqrScreen
                    onVerify: ({bool silent = false}) => _verifyPayment(orderId, silent: silent),
                  ),
                ),
              );
              return;
            }

            if (paymentUrl != null && (paymentUrl as String).isNotEmpty) {
              if (!paymentUrl.startsWith('http')) {
                await _launchDeeplink(paymentUrl, orderId);
                return;
              }
              _openWebView(null, null, methodName, initialUrl: paymentUrl);
              return;
            }

            throw Exception('No redirect data received.');
          } else {
            throw Exception(
                'ABA Error (${json['status']['code']}): ${json['status']['message']}');
          }
        } else {
          _openWebView(null, null, methodName, htmlContent: body);
        }
      } else if ([301, 302, 307, 308].contains(response.statusCode)) {
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          _openWebView(null, null, methodName, initialUrl: location);
        } else {
          throw Exception('Redirect with no Location header (${response.statusCode})');
        }
      } else {
        throw Exception('Server error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      // Cancel the PENDING order since payment initialization failed
      Provider.of<OrderProvider>(context, listen: false).cancelOrder(orderId);
      _showSnack('Payment Error: $e');
    }
  }

  Future<void> _launchDeeplink(String url, int orderId) async {
    try {
      final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Could not launch ABA Mobile app.');
      setState(() => _isWaitingForReturn = true);
      if (mounted) {
        _showSnack('Complete payment in ABA app, then return here.', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('Could not open ABA app. Please ensure it is installed.');
    }
  }

  void _openWebView(
    Map<String, dynamic>? payload,
    String? url,
    String name, {
    String? htmlContent,
    String? initialUrl,
  }) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AbaWebViewScreen(
              paywayPayload: payload,
              paywayApiUrl: url,
              methodName: name,
              htmlContent: htmlContent,
              initialUrl: initialUrl,
            ),
          ),
        )
        .then((_) {
      if (_placedOrderId != null) {
        if (_paymentChoice == _PaymentChoice.cards_new) {
           setState(() => _isConfirmingPayment = true);
           _startPollingAfterWebView(_placedOrderId!);
        } else {
           _verifyPayment(_placedOrderId!);
        }
      }
    });
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorLight : AppColors.primaryStart,
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Waiting for ABA app banner
            if (_isWaitingForReturn)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: const Color(0xFFC6A664).withOpacity(0.15),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFC6A664)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Waiting for ABA payment… Return here after completing.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B6914),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Order Items ─────────────────────────────────────
                    _buildOrderItems(theme),
                    const SizedBox(height: 24),

                    // ── 2. Delivery Address ────────────────────────────────
                    _buildSectionHeader('Delivery Address', Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    _buildAddressCard(),
                    const SizedBox(height: 24),

                    // ── 3. Payment Method ──────────────────────────────────
                    _buildSectionHeader('Payment Method', Icons.payment_outlined),
                    const SizedBox(height: 12),
                    _buildPaymentMethodKhqr(),
                    const SizedBox(height: 8),
                    _buildPaymentMethodAbaApp(),
                    // Card payment options hidden (feature not available yet)
                    const SizedBox(height: 24),

                    // ── 4. Notes ───────────────────────────────────────────
                    _buildSectionHeader('Notes (Optional)', Icons.note_alt_outlined),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Gate code, delivery instructions…',
                        prefixIcon: const Icon(Icons.edit_note_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      maxLines: 2,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // ── 5. Bottom summary + CTA ────────────────────────────────────
            _buildBottomBar(theme),
          ],
        ),
      ),
    ),
    if (_isConfirmingPayment)
      Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFC6A664)),
              const SizedBox(height: 24),
              const Text(
                'Processing Payment...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please do not close the app.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  // ── Section 1: Order Items ─────────────────────────────────────────────────
  Widget _buildOrderItems(ThemeData theme) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final items = widget.directItems ?? cartProvider.cart?.items ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                '${items.length} item${items.length > 1 ? 's' : ''} in your order',
                Icons.shopping_bag_outlined),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: items.asMap().entries.map((e) {
                  final item = e.value;
                  final isLast = e.key == items.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 64,
                                height: 64,
                                color: Colors.grey[100],
                                child: (item.product.images.isNotEmpty ||
                                        item.product.imageUrl != null)
                                    ? Image.network(
                                        item.product.images.isNotEmpty
                                            ? item.product.images.first
                                            : item.product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.shopping_bag,
                                                color: Colors.grey),
                                      )
                                    : const Icon(Icons.shopping_bag,
                                        color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.variantName != null ||
                                      item.variantAttributes != null)
                                    Text(
                                      '${item.variantName ?? ''} ${item.variantAttributes != null ? "(${item.variantAttributes})" : ""}'
                                          .trim(),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatCurrency(item.price),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryStart
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'x${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryStart,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(height: 1, color: Colors.grey.shade100),
                    ],
                  );
                }).toList(),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
          ],
        );
      },
    );
  }

  // ── Section 2: Address Card ───────────────────────────────────────────────
  Widget _buildAddressCard() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push<AddressModel>(
          context,
          MaterialPageRoute(
            builder: (_) => const AddressListScreen(isSelectionMode: true),
          ),
        );
        if (result != null) setState(() => _selectedAddress = result);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedAddress == null
                ? AppColors.errorLight
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, color: AppColors.primaryStart),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _selectedAddress == null
                  ? const Text(
                      'Tap to select a delivery address',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedAddress!.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (_selectedAddress!.isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryStart.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                      color: AppColors.primaryStart,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedAddress!.recipientName} • ${_selectedAddress!.phoneNumber}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedAddress!.streetAddress}, ${_selectedAddress!.city}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  // ── Section 3: Payment options ────────────────────────────────────────────
  Widget _buildPaymentOption({
    required _PaymentChoice choice,
    required String title,
    required String subtitle,
    required Widget leading,
    SavedCard? card,
  }) {
    final isSelected = _paymentChoice == choice &&
        (choice != _PaymentChoice.savedCard || _selectedCard == card);

    return GestureDetector(
      onTap: () => setState(() {
        _paymentChoice = choice;
        if (choice == _PaymentChoice.savedCard) _selectedCard = card;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryStart : Colors.grey.shade200,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryStart.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryStart : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryStart : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
  }

  Widget _buildPaymentMethodKhqr() => _buildPaymentOption(
        choice: _PaymentChoice.khqr,
        title: 'ABA KHQR',
        subtitle: 'Scan to pay with any banking app',
        leading: SvgPicture.asset(
          'assets/images/payment/ABA_BANK_khqr.svg',
          width: 44,
          fit: BoxFit.contain,
        ),
      );

  Widget _buildPaymentMethodAbaApp() => _buildPaymentOption(
        choice: _PaymentChoice.abaApp,
        title: 'ABA Mobile App',
        subtitle: 'Open ABA app to pay instantly',
        leading: SvgPicture.asset(
          'assets/images/payment/ABA_BANK_khqr.svg',
          width: 44,
          fit: BoxFit.contain,
        ),
      );

  Widget _buildPaymentMethodCardsNew() => _buildPaymentOption(
        choice: _PaymentChoice.cards_new,
        title: _savedCards.isEmpty ? 'Pay with Credit / Debit Card' : '+ Add New Card',
        subtitle: _savedCards.isEmpty ? 'Visa, Mastercard, UnionPay' : 'Link a new card for future payments',
        leading: SvgPicture.asset(
          'assets/images/payment/cards_icons.svg',
          width: 44,
          fit: BoxFit.contain,
        ),
      );

  Widget _buildSavedCardOption(SavedCard card) {
    final isVisa = card.cardType.toLowerCase() == 'visa';
    final isMC = card.cardType.toLowerCase() == 'mc' ||
        card.cardType.toLowerCase() == 'mastercard';
    final isSelected =
        _paymentChoice == _PaymentChoice.savedCard && _selectedCard == card;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          _paymentChoice = _PaymentChoice.savedCard;
          _selectedCard = card;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isVisa
                  ? [const Color(0xFF1A1F71), const Color(0xFF1565C0)]
                  : isMC
                      ? [const Color(0xFF1B1B1B), const Color(0xFF333333)]
                      : [AppColors.primaryStart, AppColors.primaryEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  card.brandIcon,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isVisa ? const Color(0xFF1A1F71) : Colors.black87,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.maskPan,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Tap to select',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14,
                        color: AppColors.primaryStart)
                    : null,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05);
  }

  // ── Bottom CTA bar ─────────────────────────────────────────────────────────
  Widget _buildBottomBar(ThemeData theme) {
    return Consumer<PricingProvider>(
      builder: (context, pricingProvider, _) {
        final calc = pricingProvider.calculation;
        final isLoadingPricing = pricingProvider.isLoading;
        final isBusy = _isPlacingOrder || _isConfirmingPayment || _isCheckingPayment;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Price breakdown ──────────────────────────────────────
                if (isLoadingPricing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else if (calc != null)
                  _buildPricingBreakdown(calc, theme),

                const SizedBox(height: 14),

                // ── Place Order button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isBusy ? null : _placeOrder,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryStart,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Place Order',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Pricing breakdown rows ──────────────────────────────────────────────────
  Widget _buildPricingBreakdown(OrderCalculation calc, ThemeData theme) {
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]);
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);
    final totalLabelStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final totalValueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: AppColors.primaryStart,
    );

    Widget row(String label, String value, {TextStyle? ls, TextStyle? vs}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ls ?? labelStyle),
          Text(value,  style: vs ?? valueStyle),
        ],
      ),
    );

    return Column(
      children: [
        row('Subtotal', _formatCurrency(calc.subtotal)),
        if (calc.taxAmount > 0)
          row('Tax (${calc.taxRate.toStringAsFixed(0)}%)', _formatCurrency(calc.taxAmount)),
        row(
          'Delivery',
          calc.deliveryFee > 0 ? _formatCurrency(calc.deliveryFee) : 'Free',
          vs: calc.deliveryFee == 0
              ? valueStyle?.copyWith(color: Colors.green[600])
              : valueStyle,
        ),
        if (calc.discountAmount > 0)
          row('Discount', '-${_formatCurrency(calc.discountAmount)}',
              vs: valueStyle?.copyWith(color: Colors.green[600])),
        const Divider(height: 16),
        row('Total', _formatCurrency(calc.total), ls: totalLabelStyle, vs: totalValueStyle),
      ],
    );
  }

  // ── Shared section header ─────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryStart),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight),
        ),
      ],
    );
  }
}
