// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seasons_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$seasonsHash() => r'4fd980964748f477fa5a27f83ec5c1c4a6f27fd2';

/// See also [seasons].
@ProviderFor(seasons)
final seasonsProvider = AutoDisposeStreamProvider<List<Season>>.internal(
  seasons,
  name: r'seasonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$seasonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SeasonsRef = AutoDisposeStreamProviderRef<List<Season>>;
String _$seasonsNotifierHash() => r'5a052ba4050528f265e0d289a62585442f5eea2e';

/// See also [SeasonsNotifier].
@ProviderFor(SeasonsNotifier)
final seasonsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SeasonsNotifier, void>.internal(
  SeasonsNotifier.new,
  name: r'seasonsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$seasonsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SeasonsNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
