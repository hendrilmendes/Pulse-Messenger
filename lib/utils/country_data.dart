import 'dart:convert';
import 'package:http/http.dart' as http;

class CountryData {
  // Mapa estático para armazenar os países carregados
  static Map<String, Map<String, String>> countries = {};

  // Método para buscar países de uma API real
  static Future<void> fetchCountriesFromApi() async {
    final url = Uri.parse('https://restcountries.com/v3.1/all');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      countries = {
        for (var item in data)
          if (item['cca2'] != null &&
              item['name'] != null &&
              item['idd'] != null)
            item['cca2']: {
              'name': item['name']['common'] ?? '',
              'ddi':
                  (item['idd']['root'] ?? '') +
                  ((item['idd']['suffixes'] != null &&
                          item['idd']['suffixes'].isNotEmpty)
                      ? item['idd']['suffixes'][0]
                      : ''),
              'flag': item['flags']?['png'] ?? '',
              'code': item['cca2'] ?? '',
            },
      };
    } else {
      throw Exception('Falha ao carregar países');
    }
  }

  // Método para obter a lista de países formatada para exibição
  static List<Map<String, String>> getCountryList() {
    if (countries.isEmpty) {
      throw Exception('Países ainda não carregados. Chame fetchCountriesFromApi() primeiro.');
    }
    return countries.entries.map((entry) {
      return {
        'code': entry.key,
        'name': entry.value['name'] ?? '',
        'ddi': entry.value['ddi'] ?? '',
        'flag': entry.value['flag'] ?? '',
      };
    }).toList();
  }

  // Método para obter um país específico pelo código
  static Map<String, String>? getCountryByCode(String code) {
    if (countries.containsKey(code)) {
      return {
        'code': code,
        'name': countries[code]?['name'] ?? '',
        'ddi': countries[code]?['ddi'] ?? '',
        'flag': countries[code]?['flag'] ?? '',
      };
    }
    return null;
  }
}
