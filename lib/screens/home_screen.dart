import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../models/user.dart';
import '../services/user_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _cartItems = 0;
  int _selectedNav = 0;

  void _addToCart(String product) {
    setState(() => _cartItems++);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$product adicionado ao carrinho'),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(label: 'VER', onPressed: _showCart),
    ));
  }

  void _showCart() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: _cartItems == 0
            ? const SizedBox(height: 160, child: Center(child: Text('Seu carrinho está vazio.')))
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Seu carrinho', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text('$_cartItems ${_cartItems == 1 ? 'item selecionado' : 'itens selecionados'}'),
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('CONTINUAR COMPRANDO'))),
              ]),
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
        title: Image.asset('assets/images/Gemini_Generated_Image_1mw7h51mw7h51mw7.jfif', height: 46, fit: BoxFit.contain),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded), tooltip: 'Buscar'),
          Badge(isLabelVisible: _cartItems > 0, label: Text('$_cartItems'), child: IconButton(onPressed: _showCart, icon: const Icon(Icons.shopping_cart_outlined), tooltip: 'Carrinho')),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _selectedNav == 3 ? const _AccountTab() : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _DeliveryBanner(),
                const SizedBox(height: 18),
                const _HeroCard(),
                const SizedBox(height: 28),
                const _SectionTitle('Compre por categoria'),
                const SizedBox(height: 14),
                const _CategoryList(),
                const SizedBox(height: 30),
                const _SectionTitle('Mais procurados', action: 'Ver todos'),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 3 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .67,
                    children: [
                      _ProductCard(name: 'Switch Gigabit 8 portas', price: 'R\$ 289,90', icon: Icons.settings_ethernet_rounded, tag: 'Mais vendido', onAdd: _addToCart),
                      _ProductCard(name: 'Cabo de rede CAT6 305m', price: 'R\$ 649,00', icon: Icons.cable_rounded, tag: 'Frete grátis', onAdd: _addToCart),
                      _ProductCard(name: 'Access Point Wi-Fi 6', price: 'R\$ 579,90', icon: Icons.wifi_rounded, tag: 'Lançamento', onAdd: _addToCart),
                      _ProductCard(name: 'Rack de parede 12U', price: 'R\$ 798,00', icon: Icons.dns_rounded, onAdd: _addToCart),
                    ],
                  );
                }),
                const SizedBox(height: 30),
                const _TrustRow(),
              ]),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNav,
        onDestinationSelected: (index) {
          if (index == 2) _showCart();
          setState(() => _selectedNav = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Categorias'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Carrinho'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Conta'),
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

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 ? null : 'Digite um telefone válido';
  }

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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível atualizar o perfil.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          return const Center(child: Text('Não foi possível carregar seu perfil.'));
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
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
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
                      validator: _validatePhone,
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
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSaving ? 'SALVANDO...' : 'SALVAR ALTERAÇÕES'),
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
        decoration: BoxDecoration(color: const Color(0xFFE4F4F8), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [Icon(Icons.local_shipping_outlined, color: Color(0xFF005A83)), SizedBox(width: 10), Expanded(child: Text('Entrega para todo o Brasil • Suporte técnico especializado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))]),
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF004A70), Color(0xFF007BA5)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.hub_rounded, color: Color(0xFFFFA328), size: 38),
          const SizedBox(height: 20),
          const Text('Conecte seu projeto ao futuro.', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.08)),
          const SizedBox(height: 10),
          const Text('Equipamentos profissionais para redes, conectividade e infraestrutura.', style: TextStyle(color: Color(0xFFD6EEF5), height: 1.4)),
          const SizedBox(height: 20),
          FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF8A00), foregroundColor: Colors.white), child: const Text('EXPLORAR OFERTAS')),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action});
  final String title;
  final String? action;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), if (action != null) TextButton(onPressed: () {}, child: Text(action!))]);
}

class _CategoryList extends StatelessWidget {
  const _CategoryList();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: const [
        _Category(icon: Icons.router_outlined, label: 'Switches'), _Category(icon: Icons.wifi_rounded, label: 'Wi-Fi'), _Category(icon: Icons.cable_rounded, label: 'Cabeamento'), _Category(icon: Icons.storage_rounded, label: 'Racks'), _Category(icon: Icons.videocam_outlined, label: 'CFTV'),
      ]));
}

class _Category extends StatelessWidget {
  const _Category({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(width: 88, child: Column(children: [
          Container(width: 68, height: 68, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x12000A13), blurRadius: 12, offset: Offset(0, 4))]), child: Icon(icon, color: const Color(0xFF005A83), size: 30)),
          const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ])),
      );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.name, required this.price, required this.icon, required this.onAdd, this.tag});
  final String name, price;
  final IconData icon;
  final String? tag;
  final ValueChanged<String> onAdd;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Stack(children: [
              Container(width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF0F5F7), borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 54, color: const Color(0xFF007CA3))),
              if (tag != null) Positioned(top: 7, left: 7, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFE6C6), borderRadius: BorderRadius.circular(8)), child: Text(tag!, style: const TextStyle(fontSize: 9, color: Color(0xFF9A5300), fontWeight: FontWeight.w800)))),
            ])),
            const SizedBox(height: 11),
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2)),
            const SizedBox(height: 7),
            Text(price, style: const TextStyle(color: Color(0xFF005A83), fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, height: 34, child: OutlinedButton.icon(onPressed: () => onAdd(name), icon: const Icon(Icons.add_shopping_cart_outlined, size: 17), label: const Text('Adicionar', style: TextStyle(fontSize: 11)))),
          ]),
        ),
      );
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();
  @override
  Widget build(BuildContext context) => const Row(children: [Expanded(child: _Trust(icon: Icons.verified_user_outlined, label: 'Compra segura')), Expanded(child: _Trust(icon: Icons.support_agent_rounded, label: 'Suporte técnico')), Expanded(child: _Trust(icon: Icons.credit_card_outlined, label: 'Pagamento facilitado'))]);
}

class _Trust extends StatelessWidget {
  const _Trust({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Column(children: [Icon(icon, color: const Color(0xFF007CA3)), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))]);
}
