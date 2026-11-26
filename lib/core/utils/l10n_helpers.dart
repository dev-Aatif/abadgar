import 'package:flutter/material.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import '../constants/enums.dart';

class L10nHelpers {
  L10nHelpers._();

  /// Maps a Flutter [Locale] to an `intl`-supported locale code.
  /// Falls back `sd` -> `ur` because `intl` lacks Sindhi date/number symbols.
  static String intlLocaleFor(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'sd' ? 'ur' : code;
  }

  static String categoryLabel(BuildContext context, String? category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'Seed':
        return l10n.categorySeed;
      case 'Fertilizer':
        return l10n.categoryFertilizer;
      case 'Labor':
        return l10n.categoryLabor;
      case 'Fuel':
        return l10n.categoryFuel;
      case 'Water':
        return l10n.categoryWater;
      case 'Pesticide':
        return l10n.categoryPesticide;
      case 'Repairs':
        return l10n.categoryRepairs;
      case 'Harvest Sale':
        return l10n.categoryHarvestSale;
      case 'Wheat Sale':
        return l10n.categoryWheatSale;
      case 'Rice Sale':
        return l10n.categoryRiceSale;
      case 'Subsidy':
        return l10n.categorySubsidy;
      case 'Other':
      case null:
        return l10n.categoryOther;
      default:
        return category;
    }
  }

  static String yieldUnitLabel(BuildContext context, YieldUnit unit) {
    final l10n = AppLocalizations.of(context)!;
    switch (unit) {
      case YieldUnit.kg:
        return l10n.unitKg;
      case YieldUnit.mund:
        return l10n.unitMund;
      case YieldUnit.kharrar:
        return l10n.unitKharrar;
      case YieldUnit.tons:
        return l10n.unitTons;
    }
  }

  static String dispositionLabel(
      BuildContext context, YieldDisposition disposition) {
    final l10n = AppLocalizations.of(context)!;
    switch (disposition) {
      case YieldDisposition.sold:
        return l10n.sold;
      case YieldDisposition.stored:
        return l10n.stored;
      case YieldDisposition.personal:
        return l10n.personalUse;
    }
  }

  static String cropLabel(BuildContext context, CropType crop) {
    final l10n = AppLocalizations.of(context)!;
    return crop == CropType.wheat ? l10n.wheat : l10n.rice;
  }
}
