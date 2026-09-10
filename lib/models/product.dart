/// Entidade Produto de Rede.
/// O [id] identifica o produto dentro do catálogo JSON.
class Product {
  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.speedOrCapacity,
    this.imageUrl,
  });

  final String? id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String speedOrCapacity;

  /// URL pública da foto do equipamento. Pode ficar vazia quando não houver foto.
  final String? imageUrl;

  factory Product.fromJson(Map<String, dynamic> data) {
    if (data['name'] is! String || (data['name'] as String).trim().isEmpty ||
        data['category'] is! String || (data['category'] as String).trim().isEmpty ||
        data['price'] is! num || (data['price'] as num) <= 0 ||
        data['stock'] is! int || (data['stock'] as int) < 0 ||
        data['speedOrCapacity'] is! String || (data['speedOrCapacity'] as String).trim().isEmpty ||
        (data['imageUrl'] != null && data['imageUrl'] is! String)) {
      throw const FormatException('Produto recebido com dados inválidos.');
    }
    return Product(
      id: data['id'] as String?,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      price: (data['price'] as num? ?? 0).toDouble(),
      stock: (data['stock'] as num? ?? 0).toInt(),
      speedOrCapacity: data['speedOrCapacity'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
    );
  }

  /// Serializa os dados para o registro JSON do produto.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name.trim(),
    'category': category.trim(),
    'price': price,
    'stock': stock,
    'speedOrCapacity': speedOrCapacity.trim(),
    'imageUrl': imageUrl?.trim() ?? '',
  };

  Product copyWith({String? id}) => Product(
    id: id ?? this.id,
    name: name,
    category: category,
    price: price,
    stock: stock,
    speedOrCapacity: speedOrCapacity,
    imageUrl: imageUrl,
  );
}
