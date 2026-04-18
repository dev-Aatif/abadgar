import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/enums.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String seasonId,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String? category,
    String? notes,
    double? quantity,
    String? buyerName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  factory Transaction.fromRow(Map<String, dynamic> row) {
    return Transaction(
      id: row['id'] as String,
      seasonId: row['season_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String?,
      date: DateTime.parse(row['date'] as String),
      type: TransactionType.fromString(row['type'] as String),
      notes: row['notes'] as String?,
      quantity: row['quantity'] != null ? (row['quantity'] as num).toDouble() : null,
      buyerName: row['buyer_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toRow(Transaction transaction) {
    return {
      'id': transaction.id,
      'season_id': transaction.seasonId,
      'amount': transaction.amount,
      'category': transaction.category,
      'date': transaction.date.toIso8601String(),
      'type': transaction.type.value,
      'notes': transaction.notes,
      'quantity': transaction.quantity,
      'buyer_name': transaction.buyerName,
      'created_at': transaction.createdAt.toIso8601String(),
      'updated_at': transaction.updatedAt.toIso8601String(),
    };
  }
}
