import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
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
            return NavigationDecision.navigate;
          },
        ),
      );

    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.initialUrl!));
    } else if (widget.htmlContent != null) {
      _controller.loadHtmlString(widget.htmlContent!);
    } else if (widget.paywayPayload != null && widget.paywayApiUrl != null) {
      // Prepare the HTML form for auto-submitting POST request
      final String formHtml = '''
        <html>
          <body onload="document.forms[0].submit()">
            <form method="POST" action="${widget.paywayApiUrl}">
              ${widget.paywayPayload!.entries.map((e) => '<input type="hidden" name="${e.key}" value="${e.value}">').join('\n')}
            </form>
            <div style="display: flex; justify-content: center; align-items: center; height: 100vh; font-family: sans-serif;">
              <p>Redirecting to ABA PayWay...</p>
            </div>
          </body>
        </html>
      ''';
      _controller.loadHtmlString(formHtml);
    }
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
