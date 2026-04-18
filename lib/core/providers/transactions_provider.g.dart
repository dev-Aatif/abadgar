// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeSeasonTransactionsHash() =>
    r'72f427decf2786f44636f4c02637d097afc7c4a6';

/// See also [activeSeasonTransactions].
@ProviderFor(activeSeasonTransactions)
final activeSeasonTransactionsProvider =
    AutoDisposeStreamProvider<List<Transaction>>.internal(
  activeSeasonTransactions,
  name: r'activeSeasonTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSeasonTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveSeasonTransactionsRef
    = AutoDisposeStreamProviderRef<List<Transaction>>;
String _$allTransactionsHash() => r'2ea4ac34b72cf02be8771f056b10256af0fca8f3';

/// See also [allTransactions].
@ProviderFor(allTransactions)
final allTransactionsProvider =
    AutoDisposeStreamProvider<List<Transaction>>.internal(
  allTransactions,
  name: r'allTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllTransactionsRef = AutoDisposeStreamProviderRef<List<Transaction>>;
String _$transactionsNotifierHash() =>
    r'0b9054f985d91950017987b308fee29769483ec6';

/// See also [TransactionsNotifier].
@ProviderFor(TransactionsNotifier)
final transactionsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<TransactionsNotifier, void>.internal(
  TransactionsNotifier.new,
  name: r'transactionsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TransactionsNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
