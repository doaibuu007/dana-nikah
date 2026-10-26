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
}
