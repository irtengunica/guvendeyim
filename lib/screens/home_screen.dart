// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'contacts_screen.dart'; // Birazdan oluşturacağız
import 'disaster_notifications_screen.dart'; // Birazdan oluşturacağız

// Ana ekranı temsil eden StatelessWidget
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Scaffold, temel Material Design sayfa yapısını sağlar (AppBar, Body vb.)
    return Scaffold(
      // Sayfanın üstündeki uygulama çubuğu
      appBar: AppBar(
        title: Text('Güvendeyim'), // Başlık
        centerTitle: true, // Başlığı ortala
      ),
      // Sayfanın ana içeriği
      body: Center(
        // İçeriği dikey ve yatayda ortala
        child: Column(
          // Butonları alt alta sıralamak için Column
          mainAxisAlignment: MainAxisAlignment.center, // Dikeyde ortala
          children: <Widget>[
            // Acil Durum Kişileri butonu
            ElevatedButton.icon(
              // İkonlu buton
              icon: Icon(Icons.contacts),
              label: Text('Acil Durum Kişileri'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ), // İç boşluk
                textStyle: TextStyle(fontSize: 16), // Yazı boyutu
              ),
              onPressed: () {
                // Butona tıklandığında yapılacak işlem: ContactsScreen'e git
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencyContactsScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 30), // Butonlar arasına dikey boşluk
            // Afet Bildirimleri butonu
            ElevatedButton.icon(
              icon: Icon(Icons.notifications_active),
              label: Text('Afet Bildirimleri'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
              onPressed: () {
                // Butona tıklandığında yapılacak işlem: DisasterNotificationsScreen'e git
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisasterNotificationsScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 50), // Alt kısma biraz daha boşluk
            // Acil Durum Butonu (şimdilik sadece görsel, işlevsellik sonra eklenecek)
            ElevatedButton(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'ACİL DURUM\n(Konum Gönder)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700, // Koyu kırmızı
                foregroundColor: Colors.white, // Yazı rengi beyaz
                shape: CircleBorder(), // Yuvarlak buton
              ),
              onPressed: () {
                // Şimdilik doğrudan kişileri yönetme ekranına yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencyContactsScreen(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Lütfen listeden gönderme seçeneğini kullanın.',
                    ),
                  ),
                );
                // TODO (İleri Seviye): State Management ile kişi listesine
                // buradan erişip _sendEmergencyMessageWithLocation('sms') çağrılabilir.
              },
            ),
            // --- GÜNCELLEME BİTTİ ---
          ],
        ),
      ),
    );
  }
}
