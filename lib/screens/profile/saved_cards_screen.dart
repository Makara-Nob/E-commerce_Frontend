import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/card_service.dart';
import '../../models/payment/saved_card.dart';
import '../../constants/api_constants.dart';
import '../../theme/app_colors.dart';
import '../orders/aba_webview_screen.dart';
import 'package:http/http.dart' as http;

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  final _cardService = CardService();
  List<SavedCard> _cards = [];
  bool _isLoading = true;
  bool _isLinking = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      _cards = await _cardService.getSavedCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorLight),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCard(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Card'),
        content: const Text('Are you sure you want to remove this card?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorLight),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _cardService.deleteCard(index);
      await _loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorLight),
        );
      }
    }
  }

  Future<void> _addCard() async {
    setState(() => _isLinking = true);
    try {
      final result = await _cardService.initLinkCard();
      if (!mounted) return;

      final cofUrl = result['cofUrl'] as String;

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AbaWebViewScreen(
            initialUrl: cofUrl,
            methodName: 'Link Card',
            successUrl: '${ApiConstants.baseUrl}/api/v1/orders/payway-webhook',
          ),
        ),
      );
      
      // Give the S2S webhook a moment to finish saving the card
      if (mounted) {
        setState(() => _isLoading = true);
        await Future.delayed(const Duration(milliseconds: 2000));
        await _loadCards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorLight),
        );
      }
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Saved Cards', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isLinking)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              onPressed: _addCard,
              icon: const Icon(Icons.add_card_outlined),
              tooltip: 'Add New Card',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCards,
        color: AppColors.primaryStart,
        child: _isLoading && _cards.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _cards.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 
                             AppBar().preferredSize.height - 
                             MediaQuery.of(context).padding.top,
                      child: _buildEmpty(),
                    ),
                  )
                : _buildCardList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 2),
            ),
            child: const Icon(Icons.credit_card_off_outlined, size: 52, color: AppColors.textSecondaryLight),
          ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(height: 24),
          const Text('No Saved Cards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
          const SizedBox(height: 8),
          const Text('Add a card for one-click checkout', style: TextStyle(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _isLinking ? null : _addCard,
            icon: const Icon(Icons.add_card),
            label: const Text('Add New Card'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${_cards.length} saved card${_cards.length > 1 ? 's' : ''}',
          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ..._cards.asMap().entries.map((entry) => _buildCardTile(entry.value)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _isLinking ? null : _addCard,
          icon: const Icon(Icons.add_card_outlined),
          label: const Text('Add Another Card'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildCardTile(SavedCard card) {
    final isVisa = card.cardType.toLowerCase() == 'visa';
    final isMC = card.cardType.toLowerCase() == 'mc' || card.cardType.toLowerCase() == 'mastercard';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              card.brandIcon,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isVisa ? const Color(0xFF1A1F71) : Colors.black87,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              card.maskPan,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _deleteCard(card.index),
            icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 22),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
