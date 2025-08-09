import 'package:json_annotation/json_annotation.dart';
import '../utils/constants.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel {
  final String txid;
  final double amount; // Positive for received, negative for sent
  @JsonKey(name: 'block_height')
  final int? blockHeight;
  final DateTime timestamp;
  final String? memo;
  @JsonKey(name: 'tx_type')
  final String type; // 'sent', 'received', 'pending'
  @JsonKey(name: 'from_address')
  final String? fromAddress;
  @JsonKey(name: 'to_address')
  final String? toAddress;
  final int? confirmations;
  final double? fee;

  const TransactionModel({
    required this.txid,
    required this.amount,
    this.blockHeight,
    required this.timestamp,
    this.memo,
    required this.type,
    this.fromAddress,
    this.toAddress,
    this.confirmations,
    this.fee,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  /// Check if transaction is sent
  bool get isSent => type == AppConstants.transactionTypeSent || amount < 0;

  /// Check if transaction is received
  bool get isReceived => type == AppConstants.transactionTypeReceived || amount > 0;

  /// Check if transaction is pending
  bool get isPending => type == AppConstants.transactionTypePending || (confirmations != null && confirmations! < 1);

  /// Check if transaction is confirmed
  bool get isConfirmed => !isPending && confirmations != null && confirmations! > 0;

  /// Get absolute amount (always positive)
  double get absoluteAmount => amount.abs();

  /// Get amount in zatoshis
  int get amountZatoshis => (amount * AppConstants.zatoshisPerBtcz).round();

  /// Get absolute amount in zatoshis
  int get absoluteAmountZatoshis => (absoluteAmount * AppConstants.zatoshisPerBtcz).round();

  /// Get fee in zatoshis
  int get feeZatoshis => fee != null ? (fee! * AppConstants.zatoshisPerBtcz).round() : 0;

  /// Format amount for display
  String get formattedAmount => _formatAmount(amount);
  String get formattedAbsoluteAmount => _formatAmount(absoluteAmount);
  String get formattedFee => fee != null ? _formatAmount(fee!) : '0.00000000';

  /// Get display symbol based on transaction type
  String get displaySymbol => isSent ? '-' : '+';

  /// Get display amount with symbol
  String get displayAmount => '$displaySymbol${formattedAbsoluteAmount}';

  /// Check if transaction has memo
  bool get hasMemo => memo != null && memo!.isNotEmpty;

  /// Check if transaction involves shielded addresses
  bool get isShielded => 
      (fromAddress?.startsWith(AppConstants.shieldedAddressPrefix) ?? false) ||
      (toAddress?.startsWith(AppConstants.shieldedAddressPrefix) ?? false);

  /// Check if transaction is transparent only
  bool get isTransparent => !isShielded;

  /// Get short transaction ID for display
  String get shortTxid => txid.length > 16 ? '${txid.substring(0, 8)}...${txid.substring(txid.length - 8)}' : txid;

  /// Get formatted timestamp
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Get confirmation status text
  String get confirmationStatus {
    if (isPending) return 'Pending';
    if (confirmations == null) return 'Unknown';
    if (confirmations! == 0) return 'Unconfirmed';
    if (confirmations! == 1) return '1 confirmation';
    return '$confirmations confirmations';
  }

  /// Get transaction priority based on confirmations
  TransactionPriority get priority {
    if (isPending) return TransactionPriority.pending;
    if (confirmations == null || confirmations! < 3) return TransactionPriority.low;
    if (confirmations! < 6) return TransactionPriority.medium;
    return TransactionPriority.high;
  }

  /// Create a copy with updated values
  TransactionModel copyWith({
    String? txid,
    double? amount,
    int? blockHeight,
    DateTime? timestamp,
    String? memo,
    String? type,
    String? fromAddress,
    String? toAddress,
    int? confirmations,
    double? fee,
  }) {
    return TransactionModel(
      txid: txid ?? this.txid,
      amount: amount ?? this.amount,
      blockHeight: blockHeight ?? this.blockHeight,
      timestamp: timestamp ?? this.timestamp,
      memo: memo ?? this.memo,
      type: type ?? this.type,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      confirmations: confirmations ?? this.confirmations,
      fee: fee ?? this.fee,
    );
  }

  /// Private helper to format amount
  String _formatAmount(double amount) {
    if (amount == 0) return '0.00000000';
    
    // Show up to 8 decimal places, removing trailing zeros
    String formatted = amount.abs().toStringAsFixed(8);
    formatted = formatted.replaceAll(RegExp(r'0*$'), '');
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    
    return formatted;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TransactionModel &&
        other.txid == txid &&
        other.amount == amount &&
        other.blockHeight == blockHeight &&
        other.timestamp == timestamp &&
        other.memo == memo &&
        other.type == type &&
        other.fromAddress == fromAddress &&
        other.toAddress == toAddress &&
        other.confirmations == confirmations &&
        other.fee == fee;
  }

  @override
  int get hashCode {
    return txid.hashCode ^
        amount.hashCode ^
        blockHeight.hashCode ^
        timestamp.hashCode ^
        memo.hashCode ^
        type.hashCode ^
        fromAddress.hashCode ^
        toAddress.hashCode ^
        confirmations.hashCode ^
        fee.hashCode;
  }

  @override
  String toString() {
    return 'TransactionModel('
        'txid: $txid, '
        'amount: $amount, '
        'type: $type, '
        'timestamp: $timestamp, '
        'confirmations: $confirmations'
        ')';
  }
}

enum TransactionPriority {
  pending,
  low,
  medium,
  high,
}