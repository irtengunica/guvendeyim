// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/disaster_notification.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için (eklemeniz gerekebilir: flutter pub add intl)

class ApiService {
  // Yeni AFAD API v2 endpoint'i
  final String _afadApiBaseUrl =
      'https://deprem.afad.gov.tr/apiv2/event/filter';

  // Son depremleri çeken fonksiyon (API v2 ile)
  Future<List<DisasterNotification>> fetchLatestEarthquakes({
    int limit = 100,
  }) async {
    http.Response? response;
    try {
      // Son 24 saati belirleyelim
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(Duration(days: 1));
      // API'nin istediği format: yyyy-MM-dd HH:mm:ss
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final String startTime = formatter.format(twentyFourHoursAgo);
      final String endTime = formatter.format(now);

      // Sorgu parametrelerini oluştur
      final Map<String, String> queryParams = {
        'start': startTime,
        'end': endTime,
        'orderby': 'timedesc', // En yeniden eskiye sırala
        'limit': limit.toString(), // Limit belirle (örn: 100)
        // Gerekirse başka filtreler eklenebilir (minmag, lat/lon vb.)
        'format':
            'json', // Yanıt formatını belirt (varsayılan olabilir ama belirtmek iyi)
      };

      // Tam URL'yi oluştur
      final Uri requestUri = Uri.parse(
        _afadApiBaseUrl,
      ).replace(queryParameters: queryParams);

      print("AFAD API v2'ye istek gönderiliyor: $requestUri");
      response = await http
          .get(requestUri)
          .timeout(Duration(seconds: 20)); // Zaman aşımını biraz artırabiliriz

      print("AFAD API v2 Yanıt Kodu: ${response.statusCode}");
      print(
        "AFAD API v2 Ham Yanıtı:\n${response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length))}...",
      ); // Başını logla

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        // API v2 doğrudan liste döndürüyor olabilir, kontrol edelim
        final List<dynamic> data = jsonDecode(responseBody);

        print("Alınan deprem sayısı (v2): ${data.length}");

        List<DisasterNotification> notifications =
            data
                .map(
                  (item) => DisasterNotification.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .where(
                  (quake) => quake.type != 'Hata',
                ) // Parse hatası olanları filtrele
                .toList();
        return notifications;
      } else {
        print(
          "AFAD API v2 Hatası (Kod ${response.statusCode}): ${response.body}",
        );
        throw Exception(
          'AFAD API v2\'den veri çekilemedi. Durum Kodu: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("API isteği sırasında HATA (v2): $e");
      if (e is FormatException && response != null) {
        throw FormatException(
          'API yanıtı JSON formatında değil veya bozuk (v2). Hata: $e\nYanıt: ${response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length))}...',
        );
      }
      throw Exception('API isteği sırasında bir hata oluştu (v2): $e');
    }
  }
}
