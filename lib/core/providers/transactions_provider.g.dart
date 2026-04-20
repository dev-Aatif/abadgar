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
String _$activeSeasonYieldLogsHash() =>
    r'64a091a59c37efc68aa619b237482ebb06f2f270';

/// See also [activeSeasonYieldLogs].
@ProviderFor(activeSeasonYieldLogs)
final activeSeasonYieldLogsProvider =
    AutoDisposeStreamProvider<List<YieldLog>>.internal(
  activeSeasonYieldLogs,
  name: r'activeSeasonYieldLogsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSeasonYieldLogsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveSeasonYieldLogsRef = AutoDisposeStreamProviderRef<List<YieldLog>>;
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
    r'fb7c6eb80f8fe9faa6438eb253f0e5fdcbcd654d';

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
