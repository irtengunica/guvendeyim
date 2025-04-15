// lib/screens/disaster_notifications_screen.dart
import 'package:flutter/material.dart';
import '../models/disaster_notification.dart'; // Model
import '../services/api_service.dart'; // Servis
import 'package:url_launcher/url_launcher.dart'; // url_launcher için

class DisasterNotificationsScreen extends StatefulWidget {
  @override
  _DisasterNotificationsScreenState createState() =>
      _DisasterNotificationsScreenState();
}

class _DisasterNotificationsScreenState
    extends State<DisasterNotificationsScreen> {
  // API'dan gelen veriyi tutacak Future (başlangıçta null)
  Future<List<DisasterNotification>>? _earthquakesFuture;
  final ApiService _apiService = ApiService(); // API servisi örneği

  // --- EKSİK FONKSİYONU EKLEYİN ---
  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${url.scheme} uygulaması açılamadı.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Could not launch $url');
    }
  }
  // --- EKLEME BİTTİ ---

  @override
  void initState() {
    super.initState();
    // Ekran ilk açıldığında verileri çekmeyi başlat
    _fetchData();
  }

  // Veri çekme işlemini başlatan fonksiyon
  void _fetchData() {
    setState(() {
      // Future'ı ayarla, bu FutureBuilder'ı tetikleyecek
      _earthquakesFuture = _apiService.fetchLatestEarthquakes();
    });
  }

  // Ekranı yenilemek için fonksiyon (AppBar'a buton olarak eklenebilir)
  Future<void> _refreshData() async {
    // setState içinde _earthquakesFuture'ı tekrar ayarlayarak yenilemeyi tetikle
    setState(() {
      _earthquakesFuture = _apiService.fetchLatestEarthquakes();
    });
    // İsteğe bağlı: Kullanıcıya yenilendiğini bildiren bir mesaj gösterilebilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Veriler yenileniyor...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Son Depremler (AFAD)'),
        actions: [
          // Yenileme butonu
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _refreshData, // Yenileme fonksiyonunu çağır
          ),
        ],
      ),
      // FutureBuilder, asenkron işlemi (veri çekme) yönetir
      body: FutureBuilder<List<DisasterNotification>>(
        future: _earthquakesFuture, // Takip edilecek Future
        builder: (context, snapshot) {
          // 1. Bağlantı durumu kontrolü (veri bekleniyor mu?)
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Veri yüklenirken ortada dönen bir ikon göster
            return Center(child: CircularProgressIndicator());
          }
          // 2. Hata kontrolü
          else if (snapshot.hasError) {
            // Hata oluştuysa hata mesajını göster ve yenileme butonu koy
            print("FutureBuilder Hata: ${snapshot.error}"); // Debug için
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'Veriler yüklenirken bir hata oluştu.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Tekrar Dene'),
                    onPressed: _refreshData,
                  ),
                ],
              ),
            );
          }
          // 3. Veri kontrolü (veri geldi mi ve boş mu?)
          else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // Veri başarıyla geldiyse ve boş değilse listeyi göster
            final earthquakes = snapshot.data!;
            return ListView.builder(
              itemCount: earthquakes.length,
              itemBuilder: (context, index) {
                final quake = earthquakes[index];
                // Basit bir liste öğesi
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    // Büyüklüğe göre renkli bir ikon
                    leading: CircleAvatar(
                      backgroundColor: _getMagnitudeColor(quake.magnitude),
                      child: Text(
                        quake.magnitude.toStringAsFixed(
                          1,
                        ), // Virgülden sonra 1 basamak
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      quake.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Tarih: ${quake.date}\nDerinlik: ${quake.depth.toStringAsFixed(1)} km',
                    ),
                    isThreeLine: true, // Üç satırlık metin için
                    // Tıklanınca detay sayfasına (veya haritaya) gidilebilir
                    onTap: () {
                      // TODO: Deprem detayları veya harita gösterimi eklenebilir
                      print("Deprem seçildi: ${quake.title}");
                      _showQuakeDetails(quake); // Detay dialog'u göster
                    },
                  ),
                );
              },
            );
          }
          // 4. Veri yok durumu (veri geldi ama liste boş)
          else {
            // API'dan veri geldi ama liste boşsa
            return Center(
              child: Text('Gösterilecek deprem bilgisi bulunamadı.'),
            );
          }
        },
      ),
    );
  }

  // Büyüklüğe göre renk döndüren yardımcı fonksiyon
  Color _getMagnitudeColor(double magnitude) {
    if (magnitude < 3.0) {
      return Colors.green;
    } else if (magnitude < 5.0) {
      return Colors.orange;
    } else if (magnitude < 6.0) {
      return Colors.deepOrange;
    } else {
      return Colors.red.shade700;
    }
  }

  // Deprem detaylarını gösteren basit bir dialog
  void _showQuakeDetails(DisasterNotification quake) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(quake.title),
            content: SingleChildScrollView(
              // İçerik sığmazsa kaydırılabilir yapar
              child: ListBody(
                children: <Widget>[
                  Text(
                    'Büyüklük: ${quake.magnitude.toStringAsFixed(1)} ${quake.type}',
                  ),
                  Text('Tarih: ${quake.date}'),
                  Text('Derinlik: ${quake.depth.toStringAsFixed(1)} km'),
                  Text(
                    'Konum: ${quake.latitude.toStringAsFixed(4)}, ${quake.longitude.toStringAsFixed(4)}',
                  ),
                  // Buraya bir harita linki veya küçük bir harita widget'ı eklenebilir
                  SizedBox(height: 15),
                  TextButton(
                    child: Text('Konumu Haritada Göster (Google Maps)'),
                    onPressed: () {
                      final Uri mapUri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${quake.latitude},${quake.longitude}',
                      );
                      _launchURL(mapUri); // Harita uygulamasını aç
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Kapat'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }
} // Sınıfın sonu
