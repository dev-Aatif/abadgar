// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_season_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeSeasonHash() => r'7fed83750db4612cee5fc56bdb117c9b8c61bd06';

/// See also [activeSeason].
@ProviderFor(activeSeason)
final activeSeasonProvider = AutoDisposeStreamProvider<Season?>.internal(
  activeSeason,
  name: r'activeSeasonProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeSeasonHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveSeasonRef = AutoDisposeStreamProviderRef<Season?>;
String _$activeSeasonIdHash() => r'19c5bd945755f9e9b82659570857cb9e49bb6dd8';

/// See also [ActiveSeasonId].
@ProviderFor(ActiveSeasonId)
final activeSeasonIdProvider =
    AutoDisposeNotifierProvider<ActiveSeasonId, String?>.internal(
  ActiveSeasonId.new,
  name: r'activeSeasonIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSeasonIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveSeasonId = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
