import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyRateService {
  // Supported currencies
  static const List<String> supported = [
    'BDT',
    'USD',
    'EUR',
    'GBP',
    'INR',
    'SAR',
    'AED',
    'SGD',
    'MYR'
  ];

  static const Map<String, String> symbols = {
    'BDT': '৳',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'SAR': '﷼',
    'AED': 'د.إ',
    'SGD': 'S\$',
    'MYR': 'RM',
  };

  // Fallback rates to BDT (used if API fails)
  static const Map<String, double> fallbackRates = {
    'BDT': 1.0,
    'USD': 110.0,
    'EUR': 120.0,
    'GBP': 140.0,
    'INR': 1.32,
    'SAR': 29.3,
    'AED': 30.0,
    'SGD': 82.0,
    'MYR': 24.0,
  };

  // Fetch live rates (1 unit of currency = X BDT)
  Future<Map<String, double>> fetchRates() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.exchangerate-api.com/v4/latest/BDT',
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        // rates are relative to BDT
        // 1 BDT = rates[currency], so 1 currency = 1/rates[currency] BDT
        final Map<String, double> result = {'BDT': 1.0};
        for (final currency in supported) {
          if (currency == 'BDT') continue;
          final rate = rates[currency];
          if (rate != null && rate > 0) {
            result[currency] = 1.0 / (rate as num).toDouble();
          }
        }
        return result;
      }
    } catch (_) {}
    // Return fallback if API fails
    return fallbackRates;
  }

  static String symbolFor(String currency) => symbols[currency] ?? currency;
}
