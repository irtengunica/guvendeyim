// lib/models/disaster_notification.dart

class DisasterNotification {
  final String eventID;
  final String title;
  final String date;
  final double latitude;
  final double longitude;
  final double depth;
  final double magnitude;
  final String type;

  DisasterNotification({
    required this.eventID,
    required this.title,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.magnitude,
    required this.type,
  });

  factory DisasterNotification.fromJson(Map<String, dynamic> json) {
    try {
      return DisasterNotification(
        eventID: json['eventID'] ?? 'Bilinmiyor',
        title: json['location'] ?? 'Bilinmiyor',
        date: json['date'] ?? 'Bilinmiyor',
        latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
        longitude:
            double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
        depth: double.tryParse(json['depth']?.toString() ?? '0.0') ?? 0.0,
        magnitude:
            double.tryParse(
              json['magnitude']?.toString() ??
                  json['mw']?.toString() ??
                  json['ml']?.toString() ??
                  '0.0',
            ) ??
            0.0,
        type: json['type'] ?? 'Bilinmeyen',
      );
    } catch (e) {
      print("JSON Parse Hatası: $e - Gelen veri: $json");
      return DisasterNotification(
        eventID: 'Hata',
        title: 'Veri Okunamadı',
        date: '',
        latitude: 0,
        longitude: 0,
        depth: 0,
        magnitude: 0,
        type: 'Hata',
      );
    }
  }
}
