# Güvendeyim - Akıllı Afet Uyarısı ve Acil İletişim Uygulaması

**Güvendeyim**, afet anlarında ve sonrasında kullanıcıların güvenliklerini sağlamalarına, yakınlarıyla hızlı ve etkili iletişim kurmalarına ve güvenilir kaynaklardan anlık afet bilgilerine ulaşmalarına yardımcı olmak amacıyla geliştirilmiş bir Flutter mobil uygulamasıdır. Bu proje, TÜBİTAK 4006 Bilim Fuarı kapsamında geliştirilmiştir.

## 🚀 Projenin Amacı

Türkiye, deprem kuşağında yer alan ve çeşitli doğal afetlerle sıkça karşılaşan bir ülkedir. Bu proje ile aşağıdaki ihtiyaçlara cevap verilmesi hedeflenmiştir:

*   Kullanıcıların anlık ve güvenilir deprem bilgilerine (AFAD verileri) kolayca erişebilmesi.
*   Kullanıcının bulunduğu konuma yakın ve belirli bir büyüklüğün üzerinde bir deprem meydana geldiğinde otomatik olarak (sesli ve titreşimli alarm ile) uyarılması.
*   Otomatik uyarı sonrası kullanıcıya "İyi misiniz?" sorusu yöneltilerek durumunun teyit edilmesi.
*   Kullanıcının, önceden belirlediği acil durum kişilerine, mevcut konumunu içeren "Yardım İste" veya "İyiyim" mesajlarını hızlıca (SMS, WhatsApp vb. uygulamaları açarak) gönderebilmesi.
*   Acil durum kişi listesinin cihazda kalıcı ve güvenli bir şekilde saklanması.

## ✨ Temel Özellikler

*   **Anlık Deprem Takibi:** AFAD API v2 üzerinden en son deprem verilerini listeler (yer, büyüklük, tarih, derinlik).
*   **Otomatik Deprem Uyarısı (Uygulama Ön Plandayken):**
    *   Belirli aralıklarla kullanıcının konumunu ve son depremleri kontrol eder.
    *   Tanımlanan mesafe ve büyüklük eşiklerini aşan bir deprem algılandığında:
        *   Cihazı titreştirir.
        *   Belirgin bir alarm sesi çalar.
        *   Ekranda "Yakınınızda Deprem Algılandı! İyi misiniz?" şeklinde bir uyarı diyalogu gösterir.
*   **Kullanıcı Etkileşimli Mesajlaşma:**
    *   Uyarı diyalogundaki "İyiyim" veya "Yardım İste" seçeneklerine göre hareket eder.
    *   "Yardım İste" durumunda, kayıtlı acil durum kişilerine mevcut GPS konumuyla birlikte (Google Maps linki olarak) mesaj göndermek için varsayılan SMS veya WhatsApp uygulamasını açar.
*   **Acil Durum Kişileri Yönetimi:**
    *   Kullanıcılar, isim ve telefon numarasıyla acil durum kişileri ekleyebilir, silebilir ve listeleyebilir.
    *   Kişi bilgileri, `hive` veritabanı kullanılarak cihazda kalıcı olarak saklanır.
*   **Konum Servisleri:** Cihazın GPS'i kullanılarak anlık konum bilgisi alınır.

## 🛠️ Kullanılan Teknolojiler ve Kütüphaneler

*   **Dil:** Dart
*   **Framework:** Flutter ([Flutter Sürümünüzü Buraya Yazın, örn: 3.19.x])
*   **Geliştirme Ortamı:** Visual Studio Code / Android Studio
*   **Ana Flutter Paketleri:**
    *   `http`: AFAD API'sinden veri çekmek için.
    *   `geolocator`: Cihazın GPS konumunu almak ve mesafe hesaplamak için.
    *   `url_launcher`: SMS, WhatsApp, E-posta gibi harici uygulamaları açmak için.
    *   `hive` & `hive_flutter`: Acil durum kişi listesini cihazda kalıcı olarak saklamak için.
    *   `audioplayers`: Özel alarm sesi çalmak için.
    *   `vibration`: Cihazı titreştirmek için.
    *   `intl`: Tarih ve saat formatlama işlemleri için.
*   **Veri Kaynağı:** AFAD Deprem Veri Servisi (API v2)

## 🖼️ Ekran Görüntüleri


| Ana Ekran                                       | Kişi Listesi                                         | Deprem Listesi                                        | Uyarı Diyalogu                                      |
| :----------------------------------------------: | :-------------------------------------------------: | :----------------------------------------------------: | :-------------------------------------------------: |


## 🚀 Kurulum ve Çalıştırma

1.  Bu repoyu klonlayın: `git clone https://github.com/irtengunica/guvendeyim.git`
2.  Proje dizinine gidin: `cd guvendeyim`
3.  Gerekli Flutter paketlerini yükleyin: `flutter pub get`
4.  Eğer `assets` klasörünüz ve içinde bir alarm sesi dosyanız (`alarm.mp3` gibi) yoksa, oluşturun ve `pubspec.yaml` dosyasında tanımlayın.
5.  `local.properties` dosyasının proje kök dizininde (`android` klasörünün bir üstünde) olduğundan ve içinde `flutter.sdk=/path/to/your/flutter/sdk` satırının doğru şekilde tanımlandığından emin olun.
6.  Bir emülatör başlatın veya fiziksel bir Android cihaz bağlayın.
7.  Uygulamayı çalıştırın: `flutter run`

**Not:** SMS gönderme ve konum alma gibi özellikler için cihazda gerekli izinlerin verilmiş olması gerekir. Fiziksel cihazda test edilmesi önerilir.

## 🔮 Gelecek Planları ve Geliştirmeler

*   **Arka Planda Çalışma:** Uygulama kapalıyken bile afet uyarılarının alınabilmesi için `flutter_background_service` ve Firebase Cloud Messaging (FCM) entegrasyonu.
*   **Otomatik Mesaj Gönderme:** Kullanıcıdan belirli bir süre yanıt alınamaması durumunda, acil durum kişilerine otomatik SMS gönderme (Android için, Play Store politikaları dikkate alınarak).
*   **Diğer Afet Türleri:** Sel, fırtına, yangın gibi diğer afetler için MGM ve ilgili kurumların API'lerinin entegrasyonu.
*   **Harita Entegrasyonu:** Depremleri ve kullanıcının konumunu harita üzerinde gösterme.
*   **En Yakın Toplanma Alanları:** Güvenli toplanma alanlarını haritada işaretleme.
*   **Çevrimdışı Mod Desteği:** İnternet kesintilerinde temel işlevlerin (örn. kayıtlı kişilere SMS) çalışabilmesi.
*   **Kapsamlı UI/UX İyileştirmeleri.**

## 🤝 Katkıda Bulunma

Bu proje bir TÜBİTAK 4006 Bilim Fuarı projesi olarak geliştirilmiştir. Katkıda bulunmak isterseniz lütfen bir issue açın veya bir pull request gönderin.

## 📜 Lisans

Bu proje MIT Lisansı lisansı altındadır.

