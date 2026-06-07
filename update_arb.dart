import 'dart:convert';
import 'dart:io';

void main() {
  final keys = {
    "search": "Search...",
    "confirmDelete": "Confirm Delete",
    "confirmDeleteTransaction": "Are you sure you want to delete this transaction?",
    "confirmDeleteHarvest": "Are you sure you want to delete this harvest record?",
    "confirmDeleteLand": "Are you sure you want to delete this land? This may break existing seasons tied to it.",
    "financials": "Financials",
    "harvests": "Harvests",
    "noHarvestsLogged": "No harvests logged yet.",
    "errorLoadingHarvests": "Error loading harvests: {err}",
    "@errorLoadingHarvests": { "placeholders": { "err": { "type": "String" } } },
    "harvestDeleted": "Harvest record deleted",
    "transactionDeleted": "Transaction deleted",
    "totalYield": "Total Yield",
    "pricePer": "Price per {unit}",
    "@pricePer": { "placeholders": { "unit": { "type": "String" } } },
    "totalEstimatedRevenue": "Total Estimated Revenue:",
    "whereStored": "Where is it stored?",
    "loggingHarvest": "Logging Harvest...",
    "saveHarvest": "Save Harvest",
    "howMuchHarvested": "HOW MUCH WAS HARVESTED?",
    "whatDidYouDo": "WHAT DID YOU DO WITH IT?",
    "sold": "Sold",
    "stored": "Stored",
    "home": "Home",
    "revenuePerAcre": "Revenue / Acre",
    "yieldPerAcre": "Yield / Acre",
    "delete": "Delete",
    "deleteLand": "Delete Land"
  };

  final urduTranslations = {
    "search": "تلاش...",
    "confirmDelete": "حذف کی تصدیق",
    "confirmDeleteTransaction": "کیا آپ واقعی یہ ٹرانزیکشن حذف کرنا چاہتے ہیں؟",
    "confirmDeleteHarvest": "کیا آپ واقعی یہ فصل کا ریکارڈ حذف کرنا چاہتے ہیں؟",
    "confirmDeleteLand": "کیا آپ واقعی یہ زمین حذف کرنا چاہتے ہیں؟",
    "financials": "مالیات",
    "harvests": "فصلیں",
    "noHarvestsLogged": "ابھی تک کوئی فصل درج نہیں ہوئی۔",
    "errorLoadingHarvests": "فصلیں لوڈ کرنے میں خرابی: {err}",
    "@errorLoadingHarvests": { "placeholders": { "err": { "type": "String" } } },
    "harvestDeleted": "فصل کا ریکارڈ حذف کر دیا گیا",
    "transactionDeleted": "ٹرانزیکشن حذف کر دی گئی",
    "totalYield": "کل پیداوار",
    "pricePer": "قیمت فی {unit}",
    "@pricePer": { "placeholders": { "unit": { "type": "String" } } },
    "totalEstimatedRevenue": "کل متوقع آمدنی:",
    "whereStored": "یہ کہاں ذخیرہ ہے؟",
    "loggingHarvest": "فصل درج ہو رہی ہے...",
    "saveHarvest": "فصل محفوظ کریں",
    "howMuchHarvested": "کتنی فصل ہوئی؟",
    "whatDidYouDo": "آپ نے اس کے ساتھ کیا کیا؟",
    "sold": "فروخت شدہ",
    "stored": "ذخیرہ شدہ",
    "home": "گھر",
    "revenuePerAcre": "آمدنی / ایکڑ",
    "yieldPerAcre": "پیداوار / ایکڑ",
    "delete": "حذف کریں",
    "deleteLand": "زمین حذف کریں"
  };

  final sindhiTranslations = {
    "search": "ڳوليو...",
    "confirmDelete": "ڊاهڻ جي پڪ",
    "confirmDeleteTransaction": "ڇا توهان واقعي هي ٽرانزيڪشن ڊاهڻ چاهيو ٿا؟",
    "confirmDeleteHarvest": "ڇا توهان واقعي هي فصل جو رڪارڊ ڊاهڻ چاهيو ٿا؟",
    "confirmDeleteLand": "ڇا توهان واقعي هي زمين ڊاهڻ چاهيو ٿا؟",
    "financials": "ماليات",
    "harvests": "فصلون",
    "noHarvestsLogged": "اڃا تائين ڪوبه فصل درج ناهي ٿيو.",
    "errorLoadingHarvests": "فصلون لوڊ ڪرڻ ۾ خرابي: {err}",
    "@errorLoadingHarvests": { "placeholders": { "err": { "type": "String" } } },
    "harvestDeleted": "فصل جو رڪارڊ ڊاهيو ويو",
    "transactionDeleted": "ٽرانزيڪشن ڊاهي وئي",
    "totalYield": "ڪل پيداوار",
    "pricePer": "قيمت في {unit}",
    "@pricePer": { "placeholders": { "unit": { "type": "String" } } },
    "totalEstimatedRevenue": "ڪل متوقع آمدني:",
    "whereStored": "هي ڪٿي ذخيرو آهي؟",
    "loggingHarvest": "فصل درج ٿي رهي آهي...",
    "saveHarvest": "فصل محفوظ ڪريو",
    "howMuchHarvested": "ڪيترو فصل ٿيو؟",
    "whatDidYouDo": "توهان ان سان ڇا ڪيو؟",
    "sold": "وڪرو ٿيل",
    "stored": "ذخيرو ٿيل",
    "home": "گهر",
    "revenuePerAcre": "آمدني / ايڪڙ",
    "yieldPerAcre": "پيداوار / ايڪڙ",
    "delete": "ڊاهيو",
    "deleteLand": "زمين ڊاهيو"
  };

  void updateArb(String path, Map<String, dynamic> extras) {
    final file = File(path);
    if (!file.existsSync()) return;
    
    final content = file.readAsStringSync();
    final jsonContent = json.decode(content) as Map<String, dynamic>;
    
    jsonContent.addAll(extras);
    
    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(jsonContent));
  }

  updateArb('lib/l10n/app_en.arb', keys);
  updateArb('lib/l10n/app_ur.arb', urduTranslations);
  updateArb('lib/l10n/app_sd.arb', sindhiTranslations);
}
