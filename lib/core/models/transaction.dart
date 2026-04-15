import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String seasonId,
    required double amount,
    required String category,
    required DateTime date,
    required String type, // 'Expense' | 'Revenue'
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  factory Transaction.fromRow(Map<String, dynamic> row) {
    return Transaction(
      id: row['id'] as String,
      seasonId: row['season_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      date: DateTime.parse(row['date'] as String),
      type: row['type'] as String,
      notes: row['notes'] as String?,
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
      'type': transaction.type,
      'notes': transaction.notes,
      'created_at': transaction.createdAt.toIso8601String(),
      'updated_at': transaction.updatedAt.toIso8601String(),
    };
  }
}
