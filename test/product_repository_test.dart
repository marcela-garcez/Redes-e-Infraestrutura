import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobileprimeiro/models/product.dart';
import 'package:mobileprimeiro/services/app_error_message.dart';
import 'package:mobileprimeiro/services/json_bin_exception.dart';
import 'package:mobileprimeiro/services/product_repository.dart';

void main() {
  test('cadastro propaga falha quando o JSONBin recusa a gravação', () async {
    var writes = 0;
    final client = MockClient((request) async {
      expect(request.headers['X-Access-Key'], 'test-key');
      if (request.method == 'GET') {
        return http.Response('{"products":[]}', 200);
      }
      expect(request.method, 'PUT');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect((body['products'] as List).single['name'], 'Switch');
      writes++;
      return http.Response('{}', 403);
    });
    final repository = ProductRepository(
      client: client, indexBinId: 'catalog', accessKey: 'test-key',
    );
    addTearDown(repository.dispose);
    await expectLater(
      repository.create(const Product(
        name: 'Switch', category: 'Redes', price: 10,
        stock: 2, speedOrCapacity: '1 Gbps',
      )),
      throwsA(isA<JsonBinException>().having(
        (error) => error.statusCode, 'statusCode', 403,
      )),
    );
    expect(writes, 1);
  });

  test('CRUD usa apenas o bin do catálogo', () async {
    var contents = <String, dynamic>{'products': <dynamic>[]};
    final requests = <String>[];
    final client = MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      expect(request.url.path, '/v3/b/catalog');
      if (request.method == 'GET') return http.Response(jsonEncode(contents), 200);
      expect(request.method, 'PUT');
      contents = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{}', 200);
    });
    final repository = ProductRepository(client: client, indexBinId: 'catalog', accessKey: 'test-key');
    const product = Product(name: 'Switch', category: 'Redes', price: 10, stock: 2, speedOrCapacity: '1 Gbps');
    await repository.create(product);
    expect((await repository.listAll()).single.id, '1');
    expect((await repository.getById('1')).name, 'Switch');
    await repository.update(const Product(id: '1', name: 'Switch novo', category: 'Redes', price: 12, stock: 1, speedOrCapacity: '1 Gbps'));
    expect((await repository.listAll()).single.name, 'Switch novo');
    await repository.delete('1');
    expect(await repository.listAll(), isEmpty);
    expect(requests.every((request) => request.startsWith('GET ') || request.startsWith('PUT ')), isTrue);
    repository.dispose();
  });

  test('lê formato antigo antes de migrar na próxima gravação', () async {
    var catalog = <String, dynamic>{'productIds': ['old-id']};
    final client = MockClient((request) async {
      if (request.url.path == '/v3/b/old-id') {
        expect(request.method, 'GET');
        return http.Response('{"name":"Switch","category":"Redes","price":10,"stock":2,"speedOrCapacity":"1 Gbps"}', 200);
      }
      if (request.method == 'GET') return http.Response(jsonEncode(catalog), 200);
      expect(request.method, 'PUT');
      catalog = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{}', 200);
    });
    final repository = ProductRepository(client: client, indexBinId: 'catalog', accessKey: 'test-key');
    await repository.create(const Product(name: 'Roteador', category: 'Redes', price: 20, stock: 1, speedOrCapacity: '1 Gbps'));
    expect((catalog['products'] as List).length, 2);
    expect((catalog['products'] as List).first['id'], 'old-id');
    repository.dispose();
  });

  test('erro informa etapa e código sem expor chave', () async {
    final client = MockClient((request) async => http.Response('{"message":"test-key"}', 403));
    final repository = ProductRepository(client: client, indexBinId: 'catalog', accessKey: 'test-key');
    try {
      await repository.listAll();
      fail('A requisição deveria falhar');
    } on JsonBinException catch (error) {
      final message = AppErrorMessage.forOperation(error, operation: 'consulta');
      expect(message, contains('HTTP 403'));
      expect(message, contains('GET'));
      expect(message, isNot(contains('test-key')));
    } finally {
      repository.dispose();
    }
  });
}
