import '../services/product_repository.dart';
import '../validators/input_validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/app_error_message.dart';
import '../services/user_repository.dart';
import 'login_screen.dart';
import 'product_crud_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<CartItem> _cart = [];
  final _productRepository = ProductRepository();
  late Future<List<Product>> _featuredProducts;

  @override
  void initState() {
    super.initState();
    _featuredProducts = _productRepository.listAll();
  }

  @override
  void dispose() {
    _productRepository.dispose();
    super.dispose();
  }

  int _selectedNav = 0;
  String? _selectedProductCategory;

  int get _cartItems => _cart.fold(0, (total, item) => total + item.quantity);
  double get _cartTotal =>
      _cart.fold(0, (total, item) => total + item.subtotal);

  void _openCategory(String category) {
    setState(() {
      _selectedProductCategory = category;
      _selectedNav = 1;
    });
  }

  /// Adiciona uma unidade, agrupando produtos iguais no mesmo item do carrinho.
  bool _increaseCartItem(Product product) {
    final index = _cart.indexWhere(
      (item) =>
          (item.product.id != null && item.product.id == product.id) ||
          (item.product.id == null &&
              item.product.name == product.name &&
              item.product.category == product.category),
    );
    final currentQuantity = index == -1 ? 0 : _cart[index].quantity;

    // Não permite colocar no carrinho mais itens do que o estoque disponível.
    if (product.stock <= currentQuantity) return false;

    setState(() {
      if (index == -1) {
        _cart.add(CartItem(product: product));
      } else {
        _cart[index].quantity++;
      }
    });
    return true;
  }

  void _addToCart(Product product) {
    if (!_increaseCartItem(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product.stock == 0
                ? '${product.name} está sem estoque.'
                : 'Você já adicionou todas as unidades disponíveis.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} adicionado ao carrinho'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'VER', onPressed: _showCart),
      ),
    );
  }

  void _removeOneFromCart(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cart.remove(item);
      }
    });
  }

  void _removeItemFromCart(CartItem item) => setState(() => _cart.remove(item));

  void _showCart() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: _cart.isEmpty
              ? const SizedBox(
                  height: 160,
                  child: Center(child: Text('Seu carrinho está vazio.')),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seu carrinho',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_cartItems ${_cartItems == 1 ? 'item selecionado' : 'itens selecionados'}',
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _cart.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (_, index) {
                          final item = _cart[index];
                          return _CartItemTile(
                            item: item,
                            onDecrease: () {
                              _removeOneFromCart(item);
                              setModalState(() {});
                            },
                            onIncrease: () {
                              if (_increaseCartItem(item.product)) {
                                setModalState(() {});
                              }
                            },
                            onRemove: () {
                              _removeItemFromCart(item);
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Text(
                      'Total: R\$ ${_cartTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CONTINUAR COMPRANDO'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Image.asset(
          'assets/images/Gemini_Generated_Image_1mw7h51mw7h51mw7.jfif',
          height: 46,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Buscar',
          ),
          Badge(
            isLabelVisible: _cartItems > 0,
            label: Text('$_cartItems'),
            child: IconButton(
              onPressed: _showCart,
              icon: const Icon(Icons.shopping_cart_outlined),
              tooltip: 'Carrinho',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _selectedNav == 3
            ? const _AccountTab()
            : _selectedNav == 1
            ? ProductCrudScreen(
                onAddToCart: _addToCart,
                initialCategory: _selectedProductCategory,
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _DeliveryBanner(),
                        const SizedBox(height: 18),
                        const _HeroCard(),
                        const SizedBox(height: 28),
                        const _SectionTitle('Compre por categoria'),
                        const SizedBox(height: 14),
                        _CategoryList(onSelected: _openCategory),
                        const SizedBox(height: 30),
                        const _SectionTitle('Produtos em destaque'),
                        const SizedBox(height: 14),
                        FutureBuilder<List<Product>>(
                          future: _featuredProducts,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Column(
                                children: [
                                  Text(
                                    AppErrorMessage.forOperation(
                                      snapshot.error!,
                                      operation: 'consulta',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _featuredProducts = _productRepository
                                          .listAll();
                                    }),
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              );
                            }
                            final products = snapshot.data ?? [];
                            if (products.isEmpty) {
                              return const Text('Nenhum produto cadastrado.');
                            }
                            return LayoutBuilder(
                              builder: (context, constraints) => GridView.count(
                                crossAxisCount: constraints.maxWidth >= 600
                                    ? 3
                                    : 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: .67,
                                children: products
                                    .take(4)
                                    .map(
                                      (product) => _ProductCard(
                                        product: product,
                                        icon: Icons.router_outlined,
                                        onAdd: _addToCart,
                                      ),
                                    )
                                    .toList(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        const _TrustRow(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNav,
        onDestinationSelected: (index) {
          // O carrinho é apresentado como modal; a aba anterior continua ativa
          // quando o usuário o fecha.
          if (index == 2) {
            _showCart();
            return;
          }
          setState(() {
            if (index == 0) _featuredProducts = _productRepository.listAll();
            _selectedNav = index;
            if (index == 1) _selectedProductCategory = null;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produtos',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Carrinho',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Conta',
          ),
        ],
      ),
    );
  }
}

class _AccountTab extends StatefulWidget {
  const _AccountTab();

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _repository = UserRepository();
  bool _isSaving = false;
  bool _isSigningOut = false;
  String? _loadedUserId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadFields(UserModel user) {
    if (_loadedUserId == user.uid) return;
    _loadedUserId = user.uid;
    _nameController.text = user.name;
    _phoneController.text = _phoneMask.maskText(user.phone);
  }

  String? _validateName(String? value) =>
      value == null || value.trim().isEmpty ? 'Informe seu nome' : null;

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _repository.updateProfile(
        uid: uid,
        name: _nameController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessage.forOperation(error, operation: 'alteração'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível sair da conta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Faça login para acessar seu perfil.'));
    }
    return StreamBuilder<UserModel?>(
      stream: _repository.watchUser(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppErrorMessage.forOperation(
                  snapshot.error!,
                  operation: 'consulta',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data!;
        _loadFields(user);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      child: Icon(Icons.person_outline, size: 42),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Meu perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_phoneMask],
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        hintText: '(00) 00000-0000',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: InputValidators.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: user.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : () => _save(user.uid),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? 'SALVANDO...' : 'SALVAR ALTERAÇÕES',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isSigningOut ? null : _signOut,
                        icon: _isSigningOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout_outlined),
                        label: Text(
                          _isSigningOut ? 'SAINDO...' : 'SAIR DA CONTA',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeliveryBanner extends StatelessWidget {
  const _DeliveryBanner();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFE4F4F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.local_shipping_outlined, color: Color(0xFF005A83)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Entrega para todo o Brasil • Suporte técnico especializado',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF004A70), Color(0xFF007BA5)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.hub_rounded, color: Color(0xFFFFA328), size: 38),
        const SizedBox(height: 20),
        const Text(
          'Conecte seu projeto ao futuro.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Equipamentos profissionais para redes, conectividade e infraestrutura.',
          style: TextStyle(color: Color(0xFFD6EEF5), height: 1.4),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF8A00),
            foregroundColor: Colors.white,
          ),
          child: const Text('EXPLORAR OFERTAS'),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _Category(
          icon: Icons.router_outlined,
          label: 'Switches',
          onTap: onSelected,
        ),
        _Category(
          icon: Icons.router_rounded,
          label: 'Roteador',
          onTap: onSelected,
        ),
        _Category(
          icon: Icons.cable_rounded,
          label: 'Cabeamento',
          onTap: onSelected,
        ),
        _Category(
          icon: Icons.storage_rounded,
          label: 'Racks',
          onTap: onSelected,
        ),
        _Category(
          icon: Icons.videocam_outlined,
          label: 'Equipamentos',
          onTap: onSelected,
        ),
      ],
    ),
  );
}

class _Category extends StatelessWidget {
  const _Category({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: SizedBox(
      width: 88,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onTap(label),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000A13),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF005A83), size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.icon,
    required this.onAdd,
  });
  final Product product;
  final IconData icon;
  final ValueChanged<Product> onAdd;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                _FeaturedProductImage(product: product, fallbackIcon: icon),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
          ),
          const SizedBox(height: 7),
          Text(
            'R\$ ${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF005A83),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton.icon(
              onPressed: () => onAdd(product),
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 17),
              label: const Text('Adicionar', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Exibe a foto cadastrada do produto e mantém um ícone quando ela não existe
/// ou não pode ser carregada.
class _FeaturedProductImage extends StatelessWidget {
  const _FeaturedProductImage({
    required this.product,
    required this.fallbackIcon,
  });

  final Product product;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim() ?? '';
    final fallback = Icon(
      fallbackIcon,
      size: 54,
      color: const Color(0xFF007CA3),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F7),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? fallback
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
            ),
    );
  }
}

/// Linha responsiva com todas as informações e ações de um item do carrinho.
class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ProductThumbnail(product: item.product),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.product.category} • ${item.product.speedOrCapacity}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Unitário: R\$ ${item.product.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: 'Remover uma unidade',
                  onPressed: onDecrease,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  tooltip: 'Adicionar uma unidade',
                  onPressed: item.quantity >= item.product.stock
                      ? null
                      : onIncrease,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text(
                  'R\$ ${item.subtotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF005A83),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  tooltip: 'Remover item',
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

/// Exibe a foto associada ao produto e usa um ícone quando não houver URL válida.
class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.product});

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
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: _Trust(
          icon: Icons.verified_user_outlined,
          label: 'Compra segura',
        ),
      ),
      Expanded(
        child: _Trust(
          icon: Icons.support_agent_rounded,
          label: 'Suporte técnico',
        ),
      ),
      Expanded(
        child: _Trust(
          icon: Icons.credit_card_outlined,
          label: 'Pagamento facilitado',
        ),
      ),
    ],
  );
}

class _Trust extends StatelessWidget {
  const _Trust({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: const Color(0xFF007CA3)),
      const SizedBox(height: 6),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
