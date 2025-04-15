// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Kullanıcının o anki konumunu tek seferlik alır
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cihazda konum servisleri açık mı?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Konum servisleri kapalıysa hata döndür
      return Future.error('Konum servisleri kapalı. Lütfen açın.');
    }

    // Uygulamanın konum iznini kontrol et
    permission = await Geolocator.checkPermission();

    // Eğer izin verilmemişse, kullanıcıdan izin iste
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      // Kullanıcı izni yine reddederse hata döndür
      if (permission == LocationPermission.denied) {
        return Future.error('Konum izinleri reddedildi.');
      }
    }

    // Eğer izin kalıcı olarak reddedilmişse (örn. ayarlardan engellenmişse)
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Konum izinleri kalıcı olarak reddedildi. Lütfen uygulama ayarlarından izin verin.',
      );
    }

    // İzinler tamamsa veya kullanıcı o anda izin verdiyse, konumu al
    // desiredAccuracy: Konum hassasiyetini belirler (daha yüksek hassasiyet daha fazla pil tüketir)
    print("Konum alınıyor...");
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Yüksek hassasiyet istiyoruz
      );
      print("Konum alındı: ${position.latitude}, ${position.longitude}");
      return position;
    } catch (e) {
      print("Konum alınırken hata: $e");
      // Düşük hassasiyetle tekrar deneme (opsiyonel)
      try {
        print("Düşük hassasiyetle tekrar deneniyor...");
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        print(
          "Konum alındı (düşük hassasiyet): ${position.latitude}, ${position.longitude}",
        );
        return position;
      } catch (e2) {
        print("Düşük hassasiyetle de konum alınamadı: $e2");
        return Future.error('Konum bilgisi alınamadı: $e2');
      }
    }
  }

  // Google Maps linki oluşturan yardımcı fonksiyon
  String getGoogleMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }
}
