import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/app_error_message.dart';
import '../services/product_repository.dart';

class ProductCrudScreen extends StatefulWidget {
  const ProductCrudScreen({
    super.key,
    required this.onAddToCart,
    this.initialCategory,
  });

  final ValueChanged<Product> onAddToCart;
  final String? initialCategory;

  @override
  State<ProductCrudScreen> createState() => _ProductCrudScreenState();
}

class _ProductCrudScreenState extends State<ProductCrudScreen> {
  final _repository = ProductRepository();
  final _searchController = TextEditingController();
  bool _isCreatingCatalog = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _openForm([Product? product]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductForm(product: product, repository: _repository),
    );
  }

  Future<void> _showDetails(Product product) async {
    if (product.id == null) return;
    try {
      final currentProduct = await _repository.getById(product.id!);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(currentProduct.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductImage(product: currentProduct),
                const SizedBox(height: 16),
                Text('ID: ${currentProduct.id}'),
                Text('Categoria: ${currentProduct.category}'),
                Text('Preço: R\$ ${currentProduct.price.toStringAsFixed(2)}'),
                Text('Estoque: ${currentProduct.stock}'),
                Text('Especificações: ${currentProduct.speedOrCapacity}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _openForm(currentProduct);
              },
              child: const Text('Alterar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorMessage.forOperation(error, operation: 'consulta'))),
        );
      }
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text('"${product.name}" será removido permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || product.id == null || !mounted) return;
    try {
      await _repository.delete(product.id!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Produto excluído.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorMessage.forOperation(error, operation: 'exclusão')),
          ),
        );
      }
    }
  }

  Future<void> _createInitialCatalog() async {
    if (_isCreatingCatalog) return;
    setState(() => _isCreatingCatalog = true);
    try {
      final createdCount = await _repository.ensureInitialCatalog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              createdCount == 0
                  ? 'O catálogo inicial já estava cadastrado.'
                  : 'Catálogo inicial cadastrado com $createdCount produtos.',
            ),
          )
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorMessage.forOperation(error, operation: 'cadastro')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingCatalog = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'sync-catalog',
          tooltip: 'Sincronizar catálogo inicial',
          onPressed: _isCreatingCatalog ? null : _createInitialCatalog,
          child: _isCreatingCatalog
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'create-product',
          onPressed: _openForm,
          icon: const Icon(Icons.add),
          label: const Text('Cadastrar produto'),
        ),
      ],
    ),
    body: StreamBuilder<List<Product>>(
      stream: _repository.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppErrorMessage.forOperation(snapshot.error!, operation: 'consulta'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data!;
        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isCreatingCatalog
                        ? 'Cadastrando o catÃ¡logo inicial...'
                        : 'Nenhum produto cadastrado.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isCreatingCatalog
                        ? null
                        : _createInitialCatalog,
                    icon: _isCreatingCatalog
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.playlist_add),
                    label: Text(
                      _isCreatingCatalog
                          ? 'CADASTRANDO...'
                          : 'CADASTRAR INICIAL',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ou use o botão abaixo para cadastrar manualmente.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final normalizedSearch = _searchQuery.trim().toLowerCase();
        final normalizedCategory = widget.initialCategory?.toLowerCase();
        final filteredProducts = products.where((product) {
          final matchesCategory =
              normalizedCategory == null ||
              product.category.toLowerCase() == normalizedCategory;
          final searchableText =
              '${product.name} ${product.category} ${product.speedOrCapacity}'
                  .toLowerCase();
          return matchesCategory && searchableText.contains(normalizedSearch);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  labelText: 'Pesquisar produtos',
                  hintText: 'Nome, marca, categoria ou descrição',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar pesquisa',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
            ),
            if (widget.initialCategory != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text('Categoria: ${widget.initialCategory}'),
                  ),
                ),
              ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        widget.initialCategory == null
                            ? 'Nenhum produto encontrado.'
                            : 'Nenhum produto encontrado em ${widget.initialCategory}.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Card(
                          child: ListTile(
                            onTap: () => _showDetails(product),
                            leading: _ProductImage(product: product),
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.category} • ${product.speedOrCapacity}\nR\$ ${product.price.toStringAsFixed(2)} • Estoque: ${product.stock}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Adicionar ao carrinho',
                                  onPressed: () => widget.onAddToCart(product),
                                  icon: const Icon(
                                    Icons.add_shopping_cart_outlined,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) => value == 'edit'
                                      ? _openForm(product)
                                      : _delete(product),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Alterar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Excluir'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.product, required this.repository});
  final Product? product;
  final ProductRepository repository;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _speedOrCapacity;
  late final TextEditingController _imageUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _category = TextEditingController(text: product?.category ?? '');
    _price = TextEditingController(
      text: product?.price.toStringAsFixed(2) ?? '',
    );
    _stock = TextEditingController(text: product?.stock.toString() ?? '');
    _speedOrCapacity = TextEditingController(
      text: product?.speedOrCapacity ?? '',
    );
    _imageUrl = TextEditingController(text: product?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _stock.dispose();
    _speedOrCapacity.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  String? _validatePositivePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final price = double.tryParse(value.replaceAll(',', '.'));
    return price == null || price <= 0 ? 'Informe um preço maior que zero' : null;
  }

  String? _validateStock(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final stock = int.tryParse(value);
    return stock == null || stock < 0 ? 'Informe um estoque válido (zero ou mais)' : null;
  }

  String? _validateImageUrl() {
    final value = _imageUrl.text.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    return uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')
        ? 'Informe uma URL de imagem válida (http ou https).'
        : null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final imageError = _validateImageUrl();
    if (imageError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(imageError)));
      return;
    }
    setState(() => _saving = true);
    final product = Product(
      id: widget.product?.id,
      name: _name.text.trim(),
      category: _category.text.trim(),
      price: double.parse(_price.text.replaceAll(',', '.')),
      stock: int.parse(_stock.text),
      speedOrCapacity: _speedOrCapacity.text.trim(),
      imageUrl: _imageUrl.text.trim(),
    );
    try {
      if (widget.product == null) {
        await widget.repository.create(product);
      } else {
        await widget.repository.update(product);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Produto salvo no JSONBin com sucesso.'
                  : 'Produto atualizado no JSONBin com sucesso.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessage.forOperation(
                error,
                operation: widget.product == null ? 'cadastro' : 'alteração',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _managePhoto() async {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Foto do equipamento'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PhotoPreview(imageUrl: _imageUrl.text),
                const SizedBox(height: 16),
                TextField(
                  controller: _imageUrl,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'URL da foto',
                    hintText: 'https://exemplo.com/equipamento.jpg',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cole uma URL pública de imagem para associá-la ao produto.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            if (_imageUrl.text.trim().isNotEmpty)
              TextButton(
                onPressed: () {
                  _imageUrl.clear();
                  setDialogState(() {});
                },
                child: const Text('Remover foto'),
              ),
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Concluir'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        18,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.product == null
                    ? 'Cadastrar produto'
                    : 'Alterar produto',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (widget.product?.id != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'ID: ${widget.product!.id}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 20),
              _field(_name, 'Nome', validator: _required),
              _field(_category, 'Categoria', validator: _required),
              _field(
                _price,
                'Preço',
                validator: _validatePositivePrice,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              _field(
                _stock,
                'Estoque',
                validator: _validateStock,
                keyboard: TextInputType.number,
              ),
              _field(
                _speedOrCapacity,
                'Especificações técnicas',
                validator: _required,
              ),
              OutlinedButton.icon(
                onPressed: _managePhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _imageUrl.text.trim().isEmpty
                      ? 'Adicionar foto por URL'
                      : 'Gerenciar foto do produto',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'SALVANDO...' : 'SALVAR NO JSONBIN'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboard,
    ),
  );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim() ?? '';
    if (imageUrl.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.inventory_2_outlined));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

/// Pré-visualização usada no modal de gerenciamento da foto do produto.
class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 120,
        height: 120,
        child: url.isEmpty
            ? const ColoredBox(
                color: Color(0xFFF0F5F7),
                child: Icon(Icons.add_photo_alternate_outlined, size: 42),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFF0F5F7),
                  child: Icon(Icons.broken_image_outlined, size: 42),
                ),
              ),
      ),
    );
  }
}
