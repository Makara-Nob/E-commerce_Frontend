class SavedCard {
  final int index;
  final String maskPan;
  final String cardType;
  final String ctid;

  const SavedCard({
    required this.index,
    required this.maskPan,
    required this.cardType,
    required this.ctid,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) => SavedCard(
        index: json['index'] as int,
        maskPan: json['maskPan'] as String,
        cardType: json['cardType'] as String,
        ctid: json['ctid'] as String,
      );

  /// Returns the card brand icon character for display
  String get brandIcon {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return 'VISA';
      case 'mc':
      case 'mastercard':
        return 'MC';
      case 'jcb':
        return 'JCB';
      case 'cup':
        return 'CUP';
      default:
        return cardType.toUpperCase();
    }
  }
}
