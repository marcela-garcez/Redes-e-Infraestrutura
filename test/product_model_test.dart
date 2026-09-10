import 'package:flutter_test/flutter_test.dart';
import 'package:mobileprimeiro/models/product.dart';

void main() {
  test('converte JSON em produto e preserva os dados ao serializar', () {
    final product = Product.fromJson({
      'id': 'produto-1',
      'name': 'Switch',
      'category': 'Switches',
      'price': 289.90,
      'stock': 25,
      'speedOrCapacity': '8 portas',
      'imageUrl': 'https://example.com/switch.jpg',
    });

    expect(product.id, 'produto-1');
    expect(product.price, 289.90);
    expect(product.toJson()['stock'], 25);
  });

  test('rejeita JSON sem campos obrigatórios', () {
    expect(() => Product.fromJson({}), throwsFormatException);
  });
}
