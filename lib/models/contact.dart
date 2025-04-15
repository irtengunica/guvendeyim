// lib/models/contact.dart
import 'package:hive/hive.dart'; // Hive importu

part 'contact.g.dart'; // Oluşturulacak dosya adı (önemli!)

@HiveType(
  typeId: 0,
) // Hive için tip tanımlayıcısı (her sınıf için benzersiz olmalı)
class Contact extends HiveObject {
  // HiveObject'ten türetmek Hive özellikleri ekler

  @HiveField(0) // Alan sırası (0'dan başlar, sınıf içinde benzersiz olmalı)
  final String id;

  @HiveField(1) // Sonraki alan
  String name;

  @HiveField(2) // Sonraki alan
  String phoneNumber;

  // Constructor'ı Hive için ayarlamaya gerek YOKTUR.
  // Ancak HiveObject'ten türettiğimiz için final olmayan alanlar gerekiyor.
  // id'yi final bırakabiliriz ama name ve phoneNumber değişebilir olmalı.
  Contact({required this.id, required this.name, required this.phoneNumber});

  // toJson/fromJson'a şimdilik gerek yok, Hive kendi hallediyor.
}
