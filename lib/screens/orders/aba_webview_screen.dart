import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

class AbaWebViewScreen extends StatefulWidget {
  final Map<String, dynamic>? paywayPayload;
  final String? paywayApiUrl;
  final String? methodName;
  final String? htmlContent;
  final String? initialUrl;

  const AbaWebViewScreen({
    super.key,
    this.paywayPayload,
    this.paywayApiUrl,
    this.methodName,
    this.htmlContent,
    this.initialUrl,
  });

  @override
  State<AbaWebViewScreen> createState() => _AbaWebViewScreenState();
}

class _AbaWebViewScreenState extends State<AbaWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onWebResourceError: (WebResourceError error) {},
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) async {
            final url = request.url;
            final returnUrl = widget.paywayPayload?['return_url'] as String?;
            final successUrl = widget.paywayPayload?['continue_success_url'] as String?;
            final cancelUrl = widget.paywayPayload?['cancel_url'] as String?;

            if ((returnUrl != null && url.startsWith(returnUrl)) ||
                (successUrl != null && url.startsWith(successUrl)) ||
                (cancelUrl != null && url.startsWith(cancelUrl))) {
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }

            // Handle custom schemes (e.g., abamobilebank://, abapay://, intent://)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              try {
                final Uri uri = Uri.parse(url);
                launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Could not launch custom scheme: $e');
              }
              // Always prevent the WebView from trying to load custom schemes
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // Yield execution to allow Android's WebView Platform Channel and Pigeon NavigationDelegates to natively instantiate
    // before we throw dynamic POST requests at it, dodging the `arg_pigeon_instance != null` crash.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
        _controller.loadRequest(Uri.parse(widget.initialUrl!));
      } else if (widget.htmlContent != null) {
        _controller.loadHtmlString(widget.htmlContent!);
      } else if (widget.paywayPayload != null && widget.paywayApiUrl != null) {
        debugPrint('--- SENDING NATIVE POST REQUEST TO ${widget.paywayApiUrl} ---');
        
        // Correctly URL-encode all payload components natively to prevent transmission truncation
        final String bodyString = widget.paywayPayload!.entries
            .map((e) {
              debugPrint('[ABA Payload] ${e.key}: ${e.value}');
              return '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}';
            })
            .join('&');
            
        debugPrint('----------------------------------------------');

        // Execute a native URL POST directly through the WebViewController.
        // This guarantees headers, origins, and encodings perfectly mirror standard applications like Postman.
        _controller.loadRequest(
          Uri.parse(widget.paywayApiUrl!),
          method: LoadRequestMethod.post,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
          },
          body: Uint8List.fromList(utf8.encode(bodyString)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.methodName ?? 'ABA PayWay'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryStart,
              ),
            ),
        ],
      ),
    );
  }
}
