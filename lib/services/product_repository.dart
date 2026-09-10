import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'json_bin_exception.dart';

/// CRUD REST de produtos no JSONBin.io.
/// Todos os produtos são armazenados em um único bin de catálogo.
class ProductRepository {
  ProductRepository({
    http.Client? client,
    String? indexBinId,
    String? accessKey,
  })  : _client = client ?? http.Client(),
        _indexBinId = indexBinId ?? _defaultIndexBinId,
        _accessKey = accessKey ?? _defaultAccessKey;

  static const _baseUrl = 'https://api.jsonbin.io/v3';
  static const _defaultIndexBinId = String.fromEnvironment('JSONBIN_INDEX_BIN_ID');
  static const _defaultAccessKey = String.fromEnvironment('JSONBIN_ACCESS_KEY');
  final http.Client _client;
  final String _indexBinId;
  final String _accessKey;
  final _updates = StreamController<List<Product>>.broadcast();

  Stream<List<Product>> watchAll() async* {
    yield await listAll();
    yield* _updates.stream;
  }

  Future<List<Product>> listAll() async {
    final record = await _readCatalog();
    final rawProducts = record['products'];
    List<Product> products;
    if (rawProducts is List) {
      products = rawProducts.map((item) {
        if (item is! Map) {
          throw const JsonBinException('O catálogo contém um produto inválido.');
        }
        try {
          final product = Product.fromJson(Map<String, dynamic>.from(item));
          if (product.id == null || product.id!.isEmpty) {
            throw const FormatException();
          }
          return product;
        } catch (_) {
          throw const JsonBinException('O catálogo contém um produto inválido.');
        }
      }).toList();
    } else if (record['productIds'] is List) {
      final ids = record['productIds'] as List;
      if (!ids.every((id) => id is String && id.isNotEmpty)) {
        throw const JsonBinException('O índice antigo contém identificadores inválidos.');
      }
      products = await Future.wait(ids.cast<String>().map(_readLegacyProduct));
    } else {
      throw const JsonBinException('Formato do catálogo inválido.');
    }
    products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return products;
  }

  Future<Product> getById(String id) async {
    final products = await listAll();
    for (final product in products) {
      if (product.id == id) return product;
    }
    throw const JsonBinException('Produto não encontrado.', statusCode: 404);
  }

  Future<Product> _readLegacyProduct(String id) async {
    _validateConfiguration();
    final response = await _request(
      () => _client.get(_binUri(id), headers: _headers()),
      stage: 'consulta do produto', method: 'GET',
    );
    final record = _recordFromResponse(response);
    try {
      return Product.fromJson(record).copyWith(id: id);
    } on FormatException {
      throw const JsonBinException('O produto recebido contém dados inválidos.');
    } on TypeError {
      throw const JsonBinException('O produto recebido contém dados inválidos.');
    }
  }

  Future<void> create(Product product) async {
    final products = await listAll();
    final existingIds = products.map((item) => item.id).toSet();
    var nextId = 1;
    while (existingIds.contains('$nextId')) { nextId++; }
    products.add(product.copyWith(id: '$nextId'));
    await _writeCatalog(products);
  }

  Future<void> update(Product product) async {
    if (product.id == null || product.id!.isEmpty) {
      throw ArgumentError('Produto sem identificador.');
    }
    final products = await listAll();
    final index = products.indexWhere((item) => item.id == product.id);
    if (index == -1) throw const JsonBinException('Produto não encontrado.', statusCode: 404);
    products[index] = product;
    await _writeCatalog(products);
  }

  Future<void> delete(String id) async {
    final products = await listAll();
    final count = products.length;
    products.removeWhere((item) => item.id == id);
    if (products.length == count) throw const JsonBinException('Produto não encontrado.', statusCode: 404);
    await _writeCatalog(products);
  }

  Future<int> ensureInitialCatalog() async {
    final products = await listAll();
    final names = products.map((item) => item.name.toLowerCase()).toSet();
    final missing = _initialProducts
        .where((item) => !names.contains(item.name.toLowerCase()))
        .toList();
    for (final product in missing) {
      await create(product);
    }
    return missing.length;
  }

  Future<Map<String, dynamic>> _readCatalog() async {
    _validateConfiguration();
    final response = await _request(
      () => _client.get(_binUri(_indexBinId), headers: _headers()),
      stage: 'leitura do índice', method: 'GET',
    );
    return _recordFromResponse(response);
  }

  Future<void> _writeCatalog(List<Product> products) async {
    await _request(
      () => _client.put(
        _binUri(_indexBinId),
        headers: _headers(contentType: true),
        body: jsonEncode({'products': products.map((product) => product.toJson()).toList()}),
      ),
      stage: 'atualização do índice', method: 'PUT',
    );
    if (!_updates.isClosed) _updates.add(products);
  }

  Future<http.Response> _request(Future<http.Response> Function() action,
      {required String stage, required String method}) async {
    try {
      final response = await action().timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw JsonBinException(
          'A solicitação ao JSONBin foi recusada.',
          statusCode: response.statusCode,
          stage: stage,
          method: method,
        );
      }
      return response;
    } on JsonBinException {
      rethrow;
    } on TimeoutException {
      throw JsonBinException('A conexão com o JSONBin.io expirou.', stage: stage, method: method);
    } catch (error) {
      throw JsonBinException('Falha de conexão com o JSONBin.io.', stage: stage, method: method);
    }
  }

  Map<String, dynamic> _recordFromResponse(http.Response response) {
    final decoded = _decodeObject(response.body);
    final record = decoded['record'] ?? decoded;
    if (record is! Map) {
      throw const JsonBinException('A resposta da API não contém um registro JSON válido.');
    }
    return Map<String, dynamic>.from(record);
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) throw const FormatException();
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const JsonBinException('A resposta recebida não é um JSON válido.');
    }
  }

  Uri _binUri(String id) => Uri.parse('$_baseUrl/b/$id?meta=false');

  Map<String, String> _headers({bool contentType = false}) => {
        'X-Access-Key': _accessKey,
        if (contentType) 'Content-Type': 'application/json',
      };

  void _validateConfiguration() {
    if (_indexBinId.isEmpty || _accessKey.isEmpty) {
      throw const JsonBinException(
        'JSONBin.io não foi configurado. Informe JSONBIN_INDEX_BIN_ID e JSONBIN_ACCESS_KEY.',
      );
    }
  }

  void dispose() {
    _updates.close();
    _client.close();
  }

  static const List<Product> _initialProducts = [
    Product(name: 'Switch Gigabit', category: 'Switches', price: 289.90, stock: 25, speedOrCapacity: '8 portas Gigabit'),
    Product(name: 'Access Point Wi-Fi 6', category: 'Wi-Fi', price: 579.90, stock: 12, speedOrCapacity: '1,8 Gbps'),
    Product(name: 'Cabo de fibra óptica', category: 'Fibra óptica', price: 4.90, stock: 500, speedOrCapacity: '1 Gbps'),
    Product(name: 'Roteador', category: 'Conectividade', price: 289.90, stock: 22, speedOrCapacity: '1 Gbps'),
  ];
}
