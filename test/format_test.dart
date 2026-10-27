import 'package:dana_nikah/models/models.dart';
import 'package:dana_nikah/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseAmount membaca angka dengan pemisah ribuan', () {
    expect(parseAmount('1.500.000'), 1500000);
    expect(parseAmount(''), 0);
    expect(parseAmount('Rp 25.000'), 25000);
  });

  test('amountToText memformat ribuan dengan titik', () {
    expect(amountToText(1500000), '1.500.000');
    expect(amountToText(0), '');
  });

  test('waNumber mengubah 08xx menjadi 628xx', () {
    expect(waNumber('0812-3456-789'), '628123456789');
    expect(waNumber('+62 812 3456'), '628123456');
  });

  test('daysBetween menghitung selisih hari', () {
    expect(daysBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 31)), 30);
  });

  test('SeserahanItem serialisasi ke Map dan kembali', () {
    const item = SeserahanItem(
      id: 1,
      name: 'Cincin Nikah',
      itemType: 'Mahar',
      estimatedPrice: 5000000,
      actualPrice: 4800000,
      bought: true,
      note: 'Emas 5gr',
    );
    final restored = SeserahanItem.fromMap(item.toMap());
    expect(restored.name, 'Cincin Nikah');
    expect(restored.itemType, 'Mahar');
    expect(restored.estimatedPrice, 5000000);
    expect(restored.actualPrice, 4800000);
    expect(restored.bought, isTrue);
  });

  test('WeddingProfile menyimpan parameter kalkulator katering', () {
    const profile = WeddingProfile(
      partner1: 'Ahmad',
      partner2: 'Siti',
      invitationCount: 300,
      buffetPercent: 65,
    );
    final restored = WeddingProfile.fromSettings(profile.toSettings());
    expect(restored.coupleName, 'Ahmad & Siti');
    expect(restored.invitationCount, 300);
    expect(restored.buffetPercent, 65);
  });
}
