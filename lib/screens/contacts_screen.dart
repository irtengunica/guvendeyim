// lib/screens/contacts_screen.dart
import 'dart:async'; // Timer için
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart'; // Ses çalmak için
import 'package:vibration/vibration.dart'; // Titreşim için
import '../models/contact.dart';
import '../models/disaster_notification.dart'; // Disaster modelini import et
import '../services/location_service.dart';
import '../services/api_service.dart'; // ApiService'i import et

class EmergencyContactsScreen extends StatefulWidget {
  @override
  _EmergencyContactsScreenState createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late Box<Contact> contactsBox;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService(); // ApiService örneği
  final AudioPlayer _audioPlayer = AudioPlayer(); // Ses çalar örneği

  bool _isSendingLocation = false;

  // --- YENİ: Periyodik Kontrol Değişkenleri ---
  Timer? _periodicCheckTimer;
  final Duration _checkInterval = Duration(
    minutes: 1,
  ); // Kontrol aralığı (test için 1 dk)
  final double _minMagnitudeThreshold = 1.0; // Minimum büyüklük
  final double _maxDistanceKm = 1000.0; // Maksimum uzaklık (km)
  bool _isCheckingEarthquakes = false; // Kontrol sırasında çakışmayı önle
  String? _lastShownAlertId; // Aynı deprem için tekrar uyarı göstermeyi engelle

  @override
  void initState() {
    super.initState();
    contactsBox = Hive.box<Contact>('contacts');
    _startPeriodicCheck(); // Ekran açıldığında periyodik kontrolü başlat
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel(); // Ekran kapanırken timer'ı durdur
    _audioPlayer.dispose(); // Ses çaları temizle
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- Periyodik Kontrol Fonksiyonları ---
  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel(); // Önceki timer varsa durdur
    print(
      "Deprem kontrolü başlatıldı (${_checkInterval.inMinutes} dk aralıklarla).",
    );
    // İlk kontrolü hemen yap (isteğe bağlı)
    _checkNearbyEarthquakes();
    // Sonra periyodik olarak tekrarla
    _periodicCheckTimer = Timer.periodic(_checkInterval, (timer) {
      _checkNearbyEarthquakes();
    });
  }

  Future<void> _checkNearbyEarthquakes() async {
    if (_isCheckingEarthquakes) {
      print("[DEBUG] Zaten kontrol yapılıyor, atlanıyor.");
      return;
    }
    setState(() {
      _isCheckingEarthquakes = true;
    });
    print("[DEBUG] Deprem kontrolü başladı..."); // <-- LOG 1

    Position? currentPosition;
    try {
      currentPosition = await _locationService.getCurrentLocation();
      print(
        "[DEBUG] Konum alındı: ${currentPosition.latitude}, ${currentPosition.longitude}",
      ); // <-- LOG 2
    } catch (e) {
      print("[DEBUG][HATA] Konum alınamadı: $e"); // <-- LOG 3
      if (mounted)
        setState(() {
          _isCheckingEarthquakes = false;
        });
      return;
    }

    try {
      final List<DisasterNotification> earthquakes = await _apiService
          .fetchLatestEarthquakes(limit: 10);
      print(
        "[DEBUG] ${earthquakes.length} adet deprem API'dan çekildi.",
      ); // <-- LOG 4

      DisasterNotification? foundQuake;

      // Bütün depremleri loglayalım (ilk birkaç tanesi yeterli olabilir)
      print("[DEBUG] Gelen Depremler:");
      for (int i = 0; i < earthquakes.length && i < 5; i++) {
        // İlk 5'ini logla
        print(
          "  - ID: ${earthquakes[i].eventID}, Mag: ${earthquakes[i].magnitude}, Yer: ${earthquakes[i].title}",
        );
      }

      for (var quake in earthquakes) {
        print(
          "[DEBUG] Kontrol ediliyor: ID: ${quake.eventID}, Mag: ${quake.magnitude}, Yer: ${quake.title}",
        ); // <-- LOG 5

        // Büyüklük Kontrolü
        bool magnitudeOk = quake.magnitude >= _minMagnitudeThreshold;
        print(
          "  -> Büyüklük kontrolü (${_minMagnitudeThreshold}): ${magnitudeOk}",
        ); // <-- LOG 6

        if (magnitudeOk) {
          // Mesafe Hesaplama
          double distanceInMeters = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            quake.latitude,
            quake.longitude,
          );
          double distanceInKm = distanceInMeters / 1000.0;
          print(
            "  -> Mesafe: ${distanceInKm.toStringAsFixed(1)} km",
          ); // <-- LOG 7

          // Mesafe Kontrolü
          bool distanceOk = distanceInKm <= _maxDistanceKm;
          print(
            "  -> Mesafe kontrolü (${_maxDistanceKm} km): ${distanceOk}",
          ); // <-- LOG 8

          if (distanceOk) {
            // Daha Önce Gösterildi mi Kontrolü
            bool newQuake = quake.eventID != _lastShownAlertId;
            print(
              "  -> Yeni deprem mi? (ID: ${quake.eventID} != ${_lastShownAlertId}): ${newQuake}",
            ); // <-- LOG 9

            if (newQuake) {
              print(
                "[DEBUG] *** UYGUN DEPREM BULUNDU! Alarm tetiklenecek. ***",
              ); // <-- LOG 10
              foundQuake = quake;
              break; // Döngüden çık
            }
          }
        }
      } // Döngü sonu

      if (foundQuake != null) {
        print(
          "[DEBUG] Uyarı tetiklenmeden önce _lastShownAlertId güncelleniyor: ${foundQuake.eventID}",
        ); // <-- LOG 11
        // ÖNEMLİ: setState UI güncellemesi içindir, alarmı hemen tetikleyelim
        // setState(() { _lastShownAlertId = foundQuake!.eventID; }); // Bunu trigger fonksiyonu sonrasına alabiliriz veya hemen şimdi atayabiliriz.
        _lastShownAlertId = foundQuake.eventID; // ID'yi hemen ata
        _triggerAlarmAndShowDialog(foundQuake, currentPosition);
      } else {
        print("[DEBUG] Eşiklere uyan YENİ deprem bulunamadı."); // <-- LOG 12
      }
    } catch (e) {
      print(
        "[DEBUG][HATA] Deprem kontrolü sırasında API veya işleme hatası: $e",
      ); // <-- LOG 13
    } finally {
      print("[DEBUG] Deprem kontrolü bitti."); // <-- LOG 14
      if (mounted) {
        setState(() {
          _isCheckingEarthquakes = false;
        });
      }
    }
  }

  // --- Uyarı ve Dialog Fonksiyonları ---
  Future<void> _triggerAlarmAndShowDialog(
    DisasterNotification quake,
    Position currentPosition,
  ) async {
    print("Alarm ve dialog tetikleniyor...");

    // 1. Titreşim
    Vibration.hasVibrator().then((hasVibrator) {
      if (hasVibrator == true) {
        Vibration.vibrate(
          pattern: [500, 1000, 500, 1000],
          intensities: [1, 255],
        );
      }
    });

    // 2. Alarm Sesi
    try {
      await _audioPlayer.play(AssetSource('alarm.wav'), volume: 1.0);
    } catch (e) {
      print("Alarm sesi hatası: $e");
    }

    // 3. Onay Dialogu
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // Dışarı tıklayarak kapatılamaz
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Text('Deprem Algılandı!'),
              ],
            ),
            content: Text(
              'Yakınınızda ${quake.magnitude.toStringAsFixed(1)} büyüklüğünde (${quake.title}) deprem algılandı.\n\nDurumunuz nedir?',
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'İyiyim',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
                onPressed: () {
                  print("'İyiyim' seçildi.");
                  _stopAlarm();
                  Navigator.of(dialogContext).pop();
                  // İsteğe bağlı: "İyiyim" mesajı gönderme seçeneği
                  _showSendMessageDialog(quake, currentPosition, isOkay: true);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: Text(
                  'Yardım İste',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                onPressed: () {
                  print("'Yardım İste' seçildi.");
                  _stopAlarm();
                  Navigator.of(dialogContext).pop();
                  // Mesaj gönderme seçenekleri dialogunu aç
                  _showSendMessageDialog(quake, currentPosition, isOkay: false);
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _stopAlarm() {
    print("Alarm durduruluyor...");
    Vibration.cancel();
    _audioPlayer.stop();
  }

  // Mesaj gönderme seçenekleri dialogu
  void _showSendMessageDialog(
    DisasterNotification quake,
    Position currentPosition, {
    required bool isOkay,
  }) {
    final List<Contact> currentContacts = contactsBox.values.toList();
    if (currentContacts.isEmpty) {
      /* ... (uyarı aynı) ... */
      return;
    }

    final String locationUrl = _locationService.getGoogleMapsUrl(
      currentPosition.latitude,
      currentPosition.longitude,
    );
    String message;
    if (isOkay) {
      message =
          "Yakınımdaki ${quake.magnitude.toStringAsFixed(1)} (${quake.title}) depremden sonra güvendeyim. Konumum: $locationUrl";
    } else {
      message =
          "ACİL YARDIM! Yakınımdaki ${quake.magnitude.toStringAsFixed(1)} (${quake.title}) deprem bölgesindeyim. Yardıma ihtiyacım var! Konumum: $locationUrl";
    }

    // Gönderme seçenekleri
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isOkay ? 'Durum Bildir' : 'Yardım İste'),
            content: Text(
              'Aşağıdaki yöntemlerle kişilerinize mesaj gönderin:\n\nMesaj:\n$message',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('İptal'),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.sms),
                label: Text('SMS ile Gönder'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _sendSmsToContacts(currentContacts, message);
                },
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.message), // WhatsApp ikonu
                label: Text('WhatsApp (İlk Kişi)'),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (currentContacts.isNotEmpty) {
                    _sendWhatsAppMessage(
                      currentContacts.first.phoneNumber,
                      message,
                    );
                  }
                },
              ),
              // E-posta butonu (isteğe bağlı)
              // ElevatedButton.icon(
              //   icon: Icon(Icons.email),
              //   label: Text('E-posta ile Gönder'),
              //   onPressed: () {
              //      Navigator.of(context).pop();
              //     _sendEmailToContacts(currentContacts, message);
              //   },
              // ),
            ],
          ),
    );
  }

  // --- Yardımcı Fonksiyonlar ---

  // Verilen URL'yi harici uygulamada açmayı dener
  Future<void> _launchURL(Uri url) async {
    // launchUrl asenkron olduğu için await kullanılır
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Eğer URL açılamazsa ve widget hala aktifse kullanıcıya hata göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${url.scheme} uygulaması açılamadı veya bulunamadı.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('URL açılamadı: $url');
    }
  }

  // --- Kişi Yönetimi Fonksiyonları ---

  // Yeni kişiyi Hive kutusuna ekler
  Future<void> _addContact() async {
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();

    if (name.isNotEmpty && phone.isNotEmpty) {
      final String id =
          DateTime.now().millisecondsSinceEpoch.toString(); // Benzersiz ID
      final newContact = Contact(id: id, name: name, phoneNumber: phone);

      await contactsBox.put(id, newContact); // Hive'a kaydet (await önemli)

      // Formu temizle ve klavyeyi kapat
      _nameController.clear();
      _phoneController.clear();
      FocusScope.of(context).unfocus();

      // Başarı mesajı (widget aktifse göster)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name kişisi eklendi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Hata mesajı (widget aktifse göster)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lütfen isim ve telefon numarası girin.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Kişiyi Hive kutusundan siler
  Future<void> _deleteContact(String id) async {
    await contactsBox.delete(id); // Hive'dan sil (await önemli)

    // Silindi mesajı (widget aktifse göster)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        // !!! DÜZELTME: SnackBar widget'ı eksikti !!!
        SnackBar(
          content: Text('Kişi silindi.'),
          backgroundColor: Colors.red.shade300, // Biraz daha açık kırmızı
        ),
      );
    }
  }

  // --- Acil Durum Mesajı Gönderme Fonksiyonları ---

  // Konumu alıp ilgili mesaj gönderme fonksiyonunu çağıran ana fonksiyon
  Future<void> _sendEmergencyMessageWithLocation(String type) async {
    final List<Contact> currentContacts = contactsBox.values.toList();

    if (currentContacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderilecek kişi bulunamadı!')),
        );
      }
      return;
    }

    // Gönderim başladığında durumu güncelle (UI'da progress gösterilecek)
    setState(() {
      _isSendingLocation = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum alınıyor...'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      final Position position = await _locationService.getCurrentLocation();
      final String locationUrl = _locationService.getGoogleMapsUrl(
        position.latitude,
        position.longitude,
      );
      final String baseMessage = "Acil durumdayım. Yardıma ihtiyacım var.";
      final String messageWithLocation = "$baseMessage\nKonumum: $locationUrl";

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mesaj gönderiliyor...')));
      }

      switch (type) {
        case 'sms':
          _sendSmsToContacts(currentContacts, messageWithLocation);
          break;
        case 'email':
          _sendEmailToContacts(currentContacts, messageWithLocation);
          break;
        case 'whatsapp':
          if (currentContacts.isNotEmpty) {
            _sendWhatsAppMessage(
              currentContacts.first.phoneNumber,
              messageWithLocation,
            );
          }
          break;
      }
    } catch (e) {
      print("Acil mesaj gönderme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // İşlem bitince (hata olsa da olmasa da) durumu eski haline getir
      if (mounted) {
        setState(() {
          _isSendingLocation = false;
        });
      }
    }
  }

  // SMS uygulamasını açar
  void _sendSmsToContacts(List<Contact> contactsToSend, String message) {
    String recipients = contactsToSend.map((c) => c.phoneNumber).join(",");
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: recipients,
      queryParameters: {'body': Uri.encodeComponent(message)},
    );
    _launchURL(smsUri);
  }

  // E-posta uygulamasını açar
  void _sendEmailToContacts(List<Contact> contactsToSend, String message) {
    // String recipients = contactsToSend.map((c) => c.emailAddress).join(","); // Email eklenmeli
    String recipients = "ornek@eposta.com"; // Örnek
    String subject = "Acil Durum Bildirimi";
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: recipients,
      queryParameters: {
        'subject': Uri.encodeComponent(subject),
        'body': Uri.encodeComponent(message),
      },
    );
    _launchURL(emailUri);
  }

  // WhatsApp uygulamasını açar
  void _sendWhatsAppMessage(String phoneNumber, String message) async {
    String whatsappNumber = phoneNumber.replaceAll(RegExp(r'\s+|-'), '');
    if (!whatsappNumber.startsWith('+')) {
      whatsappNumber = "+90$whatsappNumber";
    }
    final Uri whatsappUri = Uri.parse(
      "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}",
    );
    // _launchURL fonksiyonu içindeki mounted kontrolü sayesinde burada tekrar kontrol etmeye gerek yok.
    _launchURL(whatsappUri);
  }

  // --- Widget Build Metodu ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Acil Durum Kişileri'),
        actions: [
          // Gönderme menüsü
          PopupMenuButton<String>(
            icon:
                _isSendingLocation
                    ? SizedBox(
                      // Gönderim sırasında dönen ikon
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                    : Icon(Icons.send), // Normal gönder ikonu
            tooltip: "Konumla Bildirim Gönder",
            enabled: !_isSendingLocation, // Gönderim sırasında pasif yap
            onSelected:
                _sendEmergencyMessageWithLocation, // Seçildiğinde ana fonksiyonu çağır
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'sms',
                    child: ListTile(
                      leading: Icon(Icons.sms),
                      title: Text('SMS ile Konum Gönder'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'email',
                    child: ListTile(
                      leading: Icon(Icons.email),
                      title: Text('E-posta ile Konum Gönder'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'whatsapp',
                    child: ListTile(
                      leading: Icon(Icons.message), // WhatsApp için farklı ikon
                      title: Text('WhatsApp (İlk Kişi)'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Kişi ekleme formu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'İsim',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Telefon Numarası',
                    hintText: '+90 5XX XXX XX XX', // İpucu metni
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  // Butonu ikonlu yapmak daha şık olabilir
                  icon: Icon(Icons.person_add),
                  label: Text('Kişi Ekle'),
                  onPressed: _addContact,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Tam genişlik
                  ),
                ),
              ],
            ),
          ),
          Divider(thickness: 1),
          // Kişi listesi (Hive kutusunu dinleyen kısım)
          Expanded(
            child: ValueListenableBuilder(
              valueListenable:
                  contactsBox.listenable(), // Kutudaki değişiklikleri dinle
              builder: (context, Box<Contact> box, _) {
                final contacts = box.values.toList(); // Anlık kişileri al

                if (contacts.isEmpty) {
                  return Center(
                    child: Text(
                      'Henüz acil durum kişisi eklenmedi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                } else {
                  // Kaydırılabilir liste
                  return ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return Card(
                        elevation: 2, // Hafif gölge
                        margin: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            // İsmin baş harfi veya bir ikon
                            child: Text(
                              contact.name.isNotEmpty
                                  ? contact.name[0].toUpperCase()
                                  : '?',
                            ),
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).primaryColorLight, // Temadan renk al
                          ),
                          title: Text(
                            contact.name,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(contact.phoneNumber),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_forever,
                              color: Colors.redAccent,
                            ), // Biraz farklı ikon
                            tooltip: 'Kişiyi Sil',
                            onPressed: () => _deleteContact(contact.id),
                          ),
                          // İsteğe bağlı: Kişiye özel mesaj gönderme
                          // onTap: () {
                          //   _sendEmergencyMessageWithLocation('whatsapp'); // Veya seçtir
                          // },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          SizedBox(height: 10), // En alta küçük bir boşluk
        ],
      ),
    );
  }
} // Sınıfın sonu
