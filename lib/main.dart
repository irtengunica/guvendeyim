// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Hive Flutter importu
import 'models/contact.dart'; // Contact modelini import et
import 'screens/home_screen.dart'; // Henüz oluşturmadık ama import edelim

void main() async {
  // main'i async yap
  WidgetsFlutterBinding.ensureInitialized(); // Flutter binding'i başlat

  // --- HIVE BAŞLATMA ---
  await Hive.initFlutter(); // Hive Flutter'ı başlat
  Hive.registerAdapter(ContactAdapter()); // Oluşturulan Adapter'ı kaydet
  await Hive.openBox<Contact>('contacts'); // Kişileri saklayacağımız kutuyu aç
  // --- HIVE BAŞLATMA BİTTİ ---

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Bu widget uygulamanızın köküdür.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Uygulama çubuğundaki başlık ve görev yöneticisindeki isim
      title: 'Güvendeyim',
      // Uygulamanın genel tema ayarları
      theme: ThemeData(
        // Ana renk paleti (örneğin mavi tonları)
        primarySwatch:
            Colors
                .red, // Acil durum uygulaması için kırmızı daha uygun olabilir
        // Farklı platformlarda daha doğal görünüm için yoğunluk ayarı
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Uygulama açıldığında gösterilecek ilk ekran
      home: HomeScreen(), // HomeScreen'i birazdan oluşturacağız
      // Hata ayıklama sırasında sağ üstte çıkan "DEBUG" etiketini kaldırır
      debugShowCheckedModeBanner: false,
    );
  }
}
