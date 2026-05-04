import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/currency_rate_service.dart';

// Selected display currency (what user wants to see amounts in)
final selectedCurrencyProvider = StateProvider<String>((ref) => 'BDT');

// Live exchange rates
final exchangeRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  return CurrencyRateService().fetchRates();
});

// Helper: convert any amount to selected display currency
double convertAmount({
  required double amount,
  required String fromCurrency,
  required String toCurrency,
  required Map<String, double> rates, // rates are X BDT per 1 unit
}) {
  if (fromCurrency == toCurrency) return amount;

  // Convert to BDT first, then to target currency
  final inBdt = amount * (rates[fromCurrency] ?? 1.0);
  final toRate = rates[toCurrency] ?? 1.0;
  return inBdt / toRate;
}
