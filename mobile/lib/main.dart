import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_api.dart';
import 'customer_api.dart';
import 'product_api.dart';

void main() => runApp(TalegaonFreshApp(authRepository: _createAuthRepository()));

AuthRepository _createAuthRepository() =>
    const String.fromEnvironment('AUTH_MODE', defaultValue: 'remote') == 'remote'
        ? HttpAuthRepository()
        : const DemoAuthRepository();

class CustomerSession {
  const CustomerSession({required this.phone, required this.name, this.token});
  final String phone;
  final String name;
  final String? token;
}

class Product {
  const Product({required this.name, required this.unit, required this.price, required this.icon});
  final String name, unit;
  final double price;
  final IconData icon;
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onAuthenticated, this.authRepository = const DemoAuthRepository()});
  final ValueChanged<CustomerSession> onAuthenticated;
  final AuthRepository authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  bool otpSent = false;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final normalizedPhone = phone.text.replaceAll(RegExp(r'\D'), '');
    if (normalizedPhone.length != 10) {
      setState(() {
        loading = false;
        error = 'Enter a valid 10-digit mobile number.';
      });
      return;
    }

    try {
      if (!otpSent) {
        await widget.authRepository.requestOtp(normalizedPhone);
        if (!mounted) return;
        setState(() {
          loading = false;
          otpSent = true;
        });
        return;
      }

      final session = await widget.authRepository.verifyOtp(
        normalizedPhone,
        otp.text.trim(),
      );
      if (!mounted) return;
      setState(() => loading = false);
      widget.onAuthenticated(session);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Authentication failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.eco, size: 52, color: Color(0xFF168447)),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome to Talegaon Fresh',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in with your mobile number to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixText: '+91 ',
                    ),
                  ),
                  if (otpSent) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: otp,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        helperText: 'Demo OTP: 123456',
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    child: Text(
                      loading
                          ? 'Please wait…'
                          : (otpSent ? 'Verify & Continue' : 'Send OTP'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class CustomerAddress {
  const CustomerAddress({this.id, required this.label, required this.fullAddress, required this.city, required this.pincode, this.landmark = '', this.isDefault = false});
  final int? id;
  final String label, fullAddress, city, pincode, landmark;
  final bool isDefault;

  String get displayAddress => [fullAddress, city, pincode].where((x) => x.isNotEmpty).join(', ');

  Map<String, dynamic> toApiJson() => {
    'label': label,
    'address': fullAddress + (landmark.isEmpty ? '' : ', ' + landmark),
    'city': city,
    'pincode': pincode,
    'is_default': isDefault,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'fullAddress': fullAddress,
    'city': city,
    'pincode': pincode,
    'landmark': landmark,
  };

  static CustomerAddress? fromApiJson(dynamic value) {
    if (value is! Map) return null;
    final label = value['label'];
    final address = value['address'];
    final city = value['city'];
    final pincode = value['pincode'];
    if (label is! String || address is! String || city is! String || pincode is! String) return null;
    return CustomerAddress(id: value['id'] is num ? (value['id'] as num).toInt() : null, label: label, fullAddress: address, city: city, pincode: pincode, isDefault: value['is_default'] == true);
  }

  static CustomerAddress? fromJson(dynamic value) {
    if (value is! Map) return null;
    final label = value['label'];
    final fullAddress = value['fullAddress'];
    final city = value['city'];
    final pincode = value['pincode'];
    final landmark = value['landmark'];
    if (label is! String || fullAddress is! String || city is! String || pincode is! String) return null;
    return CustomerAddress(id: value['id'] is num ? (value['id'] as num).toInt() : null, label: label, fullAddress: fullAddress, city: city, pincode: pincode, landmark: landmark is String ? landmark : '', isDefault: value['isDefault'] == true);
  }
}

class OrderLine {
  const OrderLine({
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
  });

  final String name;
  final String unit;
  final double price;
  final int quantity;

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'price': price,
    'quantity': quantity,
  };

  static OrderLine? fromJson(dynamic value) {
    if (value is! Map) return null;
    final name = value['name'];
    final unit = value['unit'];
    final price = value['price'];
    final quantity = value['quantity'];
    if (name is! String || unit is! String || price is! num || quantity is! num || quantity < 1) return null;
    return OrderLine(name: name, unit: unit, price: price.toDouble(), quantity: quantity.toInt());
  }
}

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.total,
    required this.payment,
    required this.address,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final double total;
  final String payment;
  final String address;
  final DateTime createdAt;
  final List<OrderLine> items;

  Map<String, dynamic> toJson() => {
    'id': id,
    'total': total,
    'payment': payment,
    'address': address,
    'createdAt': createdAt.toIso8601String(),
    'status': 'CONFIRMED',
    'items': items.map((item) => item.toJson()).toList(),
  };

  static OrderRecord fromApiJson(Map value) {
    final rawItems = value['items'];
    final items = <OrderLine>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final name = raw['name'];
        final unit = raw['unit'];
        final price = raw['unit_price'];
        final quantity = raw['quantity'];
        if (name is String && unit is String && price is num && quantity is num && quantity > 0) {
          items.add(OrderLine(name: name, unit: unit, price: price.toDouble(), quantity: quantity.toInt()));
        }
      }
    }
    return OrderRecord(
      id: '${value['order_id']}',
      total: value['total'] is num ? (value['total'] as num).toDouble() : 0,
      payment: value['payment_method'] is String ? value['payment_method'] : '',
      address: value['address'] is String ? value['address'] : '',
      createdAt: DateTime.now(),
      items: items,
    );
  }

  static OrderRecord? fromJson(dynamic value) {
    if (value is! Map) return null;
    final id = value['id'];
    final total = value['total'];
    final payment = value['payment'];
    final address = value['address'];
    final createdAt = value['createdAt'];
    final rawItems = value['items'];
    if (id is! String || total is! num || payment is! String || address is! String || createdAt is! String) return null;
    final date = DateTime.tryParse(createdAt);
    if (date == null) return null;
    final items = rawItems is List ? rawItems.map(OrderLine.fromJson).whereType<OrderLine>().toList() : const <OrderLine>[];
    return OrderRecord(id: id, total: total.toDouble(), payment: payment, address: address, createdAt: date, items: items);
  }
}

class CartItem {
  CartItem(this.product, this.quantity);
  final Product product;
  int quantity;
}

class TalegaonFreshApp extends StatefulWidget {
  const TalegaonFreshApp({super.key, this.authRepository = const DemoAuthRepository()});
  final AuthRepository authRepository;

  @override
  State<TalegaonFreshApp> createState() => _TalegaonFreshAppState();
}

class _TalegaonFreshAppState extends State<TalegaonFreshApp> {
  CustomerSession? session;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('talegaon_fresh_session_phone');
    final token = prefs.getString('talegaon_fresh_session_token');
    if (!mounted || phone == null || phone.isEmpty || token == null || token.isEmpty) return;
    setState(() => session = CustomerSession(phone: phone, name: prefs.getString('talegaon_fresh_session_name') ?? 'Talegaon Customer', token: token));
  }

  Future<void> _handleAuthenticated(CustomerSession value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('talegaon_fresh_session_phone', value.phone);
    await prefs.setString('talegaon_fresh_session_name', value.name);
    if (value.token != null && value.token!.isNotEmpty) {
      await prefs.setString('talegaon_fresh_session_token', value.token!);
    }
    if (mounted) setState(() => session = value);
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('talegaon_fresh_session_phone');
    await prefs.remove('talegaon_fresh_session_name');
    await prefs.remove('talegaon_fresh_session_token');
    if (mounted) setState(() => session = null);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Talegaon Fresh',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168447)),
      scaffoldBackgroundColor: const Color(0xFFF7FAF5),
    ),
    home: session == null
        ? LoginPage(onAuthenticated: _handleAuthenticated, authRepository: widget.authRepository)
        : AppShell(session: session!, onSignOut: _signOut),
  );
}

class AppShell extends StatefulWidget {
  AppShell({super.key, ProductRepository? repository, required this.session, this.onSignOut})
      : repository = repository ?? HttpProductRepository(token: session.token);

  final ProductRepository repository;
  final CustomerSession session;
  final VoidCallback? onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  final cart = <CartItem>[];
  List<Product> products = [];
  bool loading = true;
  String? error;
  final addresses = <CustomerAddress>[
    const CustomerAddress(label: 'Home', fullAddress: 'Talegaon Dabhade', city: 'Pune', pincode: '410507', landmark: 'Near Talegaon station'),
  ];
  final orders = <OrderRecord>[];
  late final HttpCustomerRepository customerApi;
  final favorites = <String>{};

  @override
  void initState() {
    super.initState();
    customerApi = HttpCustomerRepository(token: widget.session.token ?? '');
    _loadProducts();
    _loadCart();
    _loadOrders();
    _loadAddresses();
    _loadFavorites();
  }

  String get _cartStorageKey => 'talegaon_fresh_cart_${widget.session.phone}';
  String get _ordersStorageKey => 'talegaon_fresh_orders_${widget.session.phone}';
  String get _addressesStorageKey => 'talegaon_fresh_addresses_${widget.session.phone}';
  String get _favoritesStorageKey => 'talegaon_fresh_favorites_${widget.session.phone}';

  Future<void> _loadCart() async {
    if (widget.session.token != null && widget.session.token!.isNotEmpty) {
      try {
        final remote = await customerApi.getCart(products);
        if (mounted) setState(() => cart..clear()..addAll(remote));
        return;
      } catch (e) { if (e is CustomerApiException && e.statusCode == 401) { widget.onSignOut?.call(); return; } }
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartStorageKey);
    if (raw == null || !mounted) return;
    try {
      final items = jsonDecode(raw);
      if (items is! List) return;
      final restored = <CartItem>[];
      for (final item in items) {
        if (item is! Map) continue;
        final name = item['name'];
        final unit = item['unit'];
        final price = item['price'];
        final quantity = item['quantity'];
        if (name is! String || unit is! String || price is! num || quantity is! num || quantity < 1) continue;
        restored.add(CartItem(
          Product(
            name: name,
            unit: unit,
            price: price.toDouble(),
            icon: _iconForProduct(name),
          ),
          quantity.toInt(),
        ));
      }
      if (mounted) setState(() => cart
        ..clear()
        ..addAll(restored));
    } catch (_) {
      await prefs.remove(_cartStorageKey);
    }
  }

  Future<void> _loadAddresses() async {
    if (widget.session.token != null && widget.session.token!.isNotEmpty) {
      try { final remote = await customerApi.getAddresses(); if (mounted) setState(() => addresses..clear()..addAll(remote)); return; }
      catch (e) { if (e is CustomerApiException && e.statusCode == 401) { widget.onSignOut?.call(); return; } }
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesStorageKey);
    if (raw == null || !mounted) return;
    try {
      final items = jsonDecode(raw);
      if (items is! List) return;
      final restored = items.map(CustomerAddress.fromJson).whereType<CustomerAddress>().toList();
      if (mounted) setState(() => addresses..clear()..addAll(restored));
    } catch (_) {
      await prefs.remove(_addressesStorageKey);
    await prefs.remove(_favoritesStorageKey);
    }
  }

  Future<void> _persistAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressesStorageKey, jsonEncode(addresses.map((address) => address.toJson()).toList()));
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesStorageKey);
    if (raw == null || !mounted) return;
    try {
      final items = jsonDecode(raw);
      if (items is! List) return;
      final restored = items.whereType<String>().where((name) => name.isNotEmpty).toSet();
      if (mounted) setState(() => favorites..clear()..addAll(restored));
    } catch (_) {
      await prefs.remove(_favoritesStorageKey);
    }
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesStorageKey, jsonEncode(favorites.toList()));
  }

  Future<void> _loadOrders() async {
    if (widget.session.token != null && widget.session.token!.isNotEmpty) {
      try { final remote = await customerApi.getOrders(); if (mounted) setState(() => orders..clear()..addAll(remote)); return; }
      catch (e) { if (e is CustomerApiException && e.statusCode == 401) { widget.onSignOut?.call(); return; } }
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersStorageKey);
    if (raw == null || !mounted) return;
    try {
      final items = jsonDecode(raw);
      if (items is! List) return;
      final restored = items.map(OrderRecord.fromJson).whereType<OrderRecord>().toList();
      if (mounted) setState(() => orders..clear()..addAll(restored));
    } catch (_) {
      await prefs.remove(_ordersStorageKey);
    }
  }

  Future<void> _persistOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ordersStorageKey, jsonEncode(orders.map((order) => order.toJson()).toList()));
  }

  Future<void> _persistCart() async {
    if (widget.session.token != null && widget.session.token!.isNotEmpty) { try { await customerApi.replaceCart(cart); return; } catch (_) {} }
    final prefs = await SharedPreferences.getInstance();
    final data = cart.map((item) => <String, dynamic>{
      'name': item.product.name,
      'unit': item.product.unit,
      'price': item.product.price,
      'quantity': item.quantity,
    }).toList();
    await prefs.setString(_cartStorageKey, jsonEncode(data));
  }

  Future<String> _completeOrder(String payment, CustomerAddress address, double total) async {
    if (widget.session.token != null && widget.session.token!.isNotEmpty) {
      final created = await customerApi.createOrder(List<CartItem>.from(cart), address, payment);
      setState(() { orders.insert(0, created); cart.clear(); });
      await customerApi.clearCart();
      return created.id;
    }
    final orderId = 'TF' + (DateTime.now().millisecondsSinceEpoch % 1000000).toString();
    final items = cart.map((item) => OrderLine(name: item.product.name, unit: item.product.unit, price: item.product.price, quantity: item.quantity)).toList();
    final order = OrderRecord(id: orderId, total: total, payment: payment, address: address.displayAddress, createdAt: DateTime.now(), items: items);
    setState(() {
      orders.insert(0, order);
      cart.clear();
    });
    await _persistCart();
    await _persistOrders();
    return orderId;
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartStorageKey);
    await prefs.remove(_ordersStorageKey);
    await prefs.remove(_addressesStorageKey);
    if (!mounted) return;
    setState(cart.clear);
    widget.onSignOut?.call();
  }

  Future<void> _loadProducts() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final apiProducts = await widget.repository.fetchProducts();
      if (!mounted) return;
      setState(() {
        products = apiProducts
            .where((p) => p.inStock)
            .map((p) => Product(
                  name: p.name,
                  unit: p.unit,
                  price: p.price,
                  icon: _iconForProduct(p.name),
                ))
            .toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is ApiUnauthorizedException) {
        widget.onSignOut?.call();
        return;
      }
      setState(() {
        products = [];
        loading = false;
        error = 'Could not load today\'s products. Please try again.';
      });
    }
  }

  IconData _iconForProduct(String name) {
    switch (name.toLowerCase()) {
      case 'tomato':
        return Icons.circle;
      case 'potato':
        return Icons.circle_outlined;
      case 'onion':
        return Icons.spa;
      case 'carrot':
        return Icons.eco;
      case 'capsicum':
        return Icons.local_florist;
      case 'cabbage':
        return Icons.grass;
      default:
        return Icons.local_grocery_store;
    }
  }

  void toggleFavorite(Product p) {
    setState(() {
      if (favorites.contains(p.name)) {
        favorites.remove(p.name);
      } else {
        favorites.add(p.name);
      }
    });
    _persistFavorites();
  }

  void add(Product p) {
    setState(() {
      final matches = cart.where((x) => x.product.name == p.name);
      if (matches.isEmpty) {
        cart.add(CartItem(p, 1));
      } else {
        matches.first.quantity++;
      }
    });
    _persistCart();
  }

  int get count => cart.fold(0, (sum, x) => sum + x.quantity);

  void _openProduct(Product product) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product, onAdd: add)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(products: products, loading: loading, error: error, onRetry: _loadProducts, onAdd: add, onOpenProduct: _openProduct, favorites: favorites, onToggleFavorite: toggleFavorite),
      ProductsPage(products: products, loading: loading, error: error, onRetry: _loadProducts, onAdd: add, onOpenProduct: _openProduct, favorites: favorites, onToggleFavorite: toggleFavorite),
      CartPage(cart: cart, onChanged: _persistCart, addresses: addresses, onOrderPlaced: _completeOrder),
      OrdersPage(orders: orders),
      ProfilePage(
        session: widget.session,
        addresses: addresses,
        onManageAddresses: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddressBookPage(addresses: addresses, api: customerApi, onChanged: () { setState(() {}); _persistAddresses(); }))),
        onManageFavorites: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesPage(products: products.where((p) => favorites.contains(p.name)).toList(), onAdd: add, onToggleFavorite: toggleFavorite))),
        onSignOut: _signOut,
      ),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Products'),
          NavigationDestination(
            icon: Badge(isLabelVisible: count > 0, label: Text(count.toString()), child: const Icon(Icons.shopping_cart_outlined)),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.products, required this.loading, this.error, required this.onRetry, required this.onAdd, required this.onOpenProduct, required this.favorites, required this.onToggleFavorite});
  final List<Product> products;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onOpenProduct;
  final Set<String> favorites;
  final ValueChanged<Product> onToggleFavorite;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Row(children: [
            const CircleAvatar(radius: 23, backgroundColor: Color(0xFFE1F4E6), child: Icon(Icons.eco, color: Color(0xFF168447))),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Talegaon Fresh', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Text('Talegaon, Maharashtra', style: TextStyle(color: Colors.black54)),
            ])),
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        sliver: SliverToBoxAdapter(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search fruits, vegetables...',
              prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        sliver: SliverToBoxAdapter(
          child: Container(
            height: 165, padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF0D7A3D), Color(0xFF34A853)])),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fresh From\nLocal Farmers', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Healthy food • Happier families', style: TextStyle(color: Colors.white70)),
              Spacer(),
              Text('Fresh • Local • Delivered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
        sliver: SliverToBoxAdapter(child: Text("Today's Fresh Products", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
      ),
      if (loading)
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())))
      else if (error != null)
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: ErrorCard(message: error!, onRetry: onRetry)))
      else if (products.isEmpty)
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No products are available today.')))),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .82),
          delegate: SliverChildBuilderDelegate((context, i) => ProductCard(product: products[i], onAdd: onAdd, onOpen: onOpenProduct, isFavorite: favorites.contains(products[i].name), onToggleFavorite: onToggleFavorite), childCount: products.length > 4 ? 4 : products.length),
        ),
      ),
    ],
  );
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.products, required this.loading, this.error, required this.onRetry, required this.onAdd, required this.onOpenProduct, required this.favorites, required this.onToggleFavorite});
  final List<Product> products;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onOpenProduct;
  final Set<String> favorites;
  final ValueChanged<Product> onToggleFavorite;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final searchController = TextEditingController();
  String category = 'All';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool matchesCategory(Product product) {
    if (category == 'All') return true;
    final name = product.name.toLowerCase();
    if (category == 'Leafy Greens') {
      return ['spinach', 'palak', 'methi', 'lettuce', 'coriander', 'cabbage'].any(name.contains);
    }
    if (category == 'Fruits') {
      return ['apple', 'banana', 'orange', 'mango', 'grapes', 'papaya', 'watermelon'].any(name.contains);
    }
    return !['spinach', 'palak', 'methi', 'lettuce', 'coriander', 'cabbage', 'apple', 'banana', 'orange', 'mango', 'grapes', 'papaya', 'watermelon'].any(name.contains);
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final filtered = widget.products.where((product) {
      final matchesSearch = query.isEmpty || product.name.toLowerCase().contains(query) || product.unit.toLowerCase().contains(query);
      return matchesSearch && matchesCategory(product);
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text("Today's Products"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 8,
              children: ['All', 'Vegetables', 'Fruits', 'Leafy Greens'].map((value) => ChoiceChip(
                label: Text(value),
                selected: category == value,
                onSelected: (_) => setState(() => category = value),
              )).toList(),
            ),
          ),
        ),
        if (widget.loading)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())))
        else if (widget.error != null)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: ErrorCard(message: widget.error!, onRetry: widget.onRetry)))
        else if (filtered.isEmpty)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No products match your search.'))))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .78),
              delegate: SliverChildBuilderDelegate((context, i) => ProductCard(product: filtered[i], onAdd: widget.onAdd, onOpen: widget.onOpenProduct, isFavorite: widget.favorites.contains(filtered[i].name), onToggleFavorite: widget.onToggleFavorite), childCount: filtered.length),
            ),
          ),
      ],
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const Icon(Icons.cloud_off, size: 40),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onAdd, required this.onOpen, required this.isFavorite, required this.onToggleFavorite});
  final Product product;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onOpen;
  final bool isFavorite;
  final ValueChanged<Product> onToggleFavorite;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0, color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => onOpen(product),
      child: Stack(
        children: [
          Padding(
          padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFEAF6EA), borderRadius: BorderRadius.circular(14)),
          child: Icon(product.icon, size: 62, color: const Color(0xFF2E9B55)),
        )),
        const SizedBox(height: 10),
        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        Text('₹' + product.price.toStringAsFixed(0) + '/' + product.unit, style: const TextStyle(color: Color(0xFF168447), fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => onAdd(product), icon: const Icon(Icons.add, size: 18), label: const Text('Add'))),
      ]),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
              onPressed: () => onToggleFavorite(product),
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            ),
          ),
        ],
      ),
    ),
  );
}

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.product, required this.onAdd});

  final Product product;
  final ValueChanged<Product> onAdd;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;

  double get total => widget.product.price * quantity;

  void _addToCart() {
    for (var i = 0; i < quantity; i++) {
      widget.onAdd(widget.product);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Product Details')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6EA),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(widget.product.icon, size: 120, color: const Color(0xFF2E9B55)),
        ),
        const SizedBox(height: 22),
        Text(widget.product.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('₹' + widget.product.price.toStringAsFixed(0) + ' / ' + widget.product.unit, style: const TextStyle(color: Color(0xFF168447), fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        const Text('Freshly sourced and available for today\'s delivery.', style: TextStyle(color: Colors.black54, fontSize: 16)),
        const SizedBox(height: 24),
        const Text('Quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton.filledTonal(onPressed: quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Text(quantity.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            IconButton.filledTonal(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add)),
            const Spacer(),
            Text('₹' + total.toStringAsFixed(0), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _addToCart, icon: const Icon(Icons.shopping_cart_outlined), label: Text('Add ' + quantity.toString() + ' to Cart')),
      ],
    ),
  );
}

class CartPage extends StatelessWidget {
  const CartPage({super.key, required this.cart, required this.onChanged, required this.addresses, required this.onOrderPlaced});
  final List<CartItem> cart;
  final VoidCallback onChanged;
  final List<CustomerAddress> addresses;
  final Future<String> Function(String payment, CustomerAddress address, double total) onOrderPlaced;

  double get subtotal => cart.fold(0, (sum, x) => sum + x.product.price * x.quantity);

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.black26),
        SizedBox(height: 12),
        Text('Your cart is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text('Add fresh products to get started.'),
      ]));
    }
    final delivery = subtotal >= 199 ? 20.0 : 0.0;
    final total = subtotal + delivery;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text('My Cart', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        ...cart.map((item) => Card(
          elevation: 0, child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.eco)),
            title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('₹' + item.product.price.toStringAsFixed(0) + ' / ' + item.product.unit),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(onPressed: () { if (item.quantity > 1) item.quantity--; onChanged(); }, icon: const Icon(Icons.remove_circle_outline)),
              Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
              IconButton(onPressed: () { item.quantity++; onChanged(); }, icon: const Icon(Icons.add_circle_outline)),
            ]),
          ),
        )),
        const SizedBox(height: 16),
        SummaryRow(label: 'Subtotal', value: subtotal),
        SummaryRow(label: 'Delivery Fee', value: delivery),
        const Divider(height: 28),
        SummaryRow(label: 'Total', value: total, bold: true),
        const SizedBox(height: 18),
        FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(total: total, addresses: addresses, onOrderPlaced: onOrderPlaced))), child: const Text('Proceed to Checkout')),
      ],
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value, this.bold = false});
  final String label;
  final double value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
      Text('₹' + value.toStringAsFixed(0), style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, fontSize: bold ? 18 : 14)),
    ]),
  );
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.total, required this.addresses, required this.onOrderPlaced});
  final double total;
  final List<CustomerAddress> addresses;
  final Future<String> Function(String payment, CustomerAddress address, double total) onOrderPlaced;
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String payment = 'UPI';
  int selectedAddress = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      if (widget.addresses.isEmpty)
        const Card(child: ListTile(leading: Icon(Icons.location_off_outlined), title: Text('No saved address'), subtitle: Text('Add a delivery address from Profile.')))
      else
        DropdownButtonFormField<int>(
          initialValue: selectedAddress.clamp(0, widget.addresses.length - 1),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on, color: Color(0xFF168447)),
            labelText: 'Saved address',
          ),
          items: [
            for (var i = 0; i < widget.addresses.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(widget.addresses[i].label),
              ),
          ],
          onChanged: (value) => setState(() => selectedAddress = value ?? 0),
        ),
      if (widget.addresses.isNotEmpty) ...[
        const SizedBox(height: 8),
        Card(child: ListTile(
          leading: const Icon(Icons.home_outlined),
          title: Text(widget.addresses[selectedAddress.clamp(0, widget.addresses.length - 1)].label),
          subtitle: Text(widget.addresses[selectedAddress.clamp(0, widget.addresses.length - 1)].displayAddress),
        )),
      ],
      const SizedBox(height: 22),
      const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ChoiceChip(
            label: const Text('UPI'),
            selected: payment == 'UPI',
            onSelected: (_) => setState(() => payment = 'UPI'),
          ),
          ChoiceChip(
            label: const Text('Cash on Delivery'),
            selected: payment == 'COD',
            onSelected: (_) => setState(() => payment = 'COD'),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        payment == 'UPI' ? 'Google Pay / PhonePe / Paytm' : 'Pay in cash when your order is delivered.',
        style: const TextStyle(color: Colors.black54),
      ),
      SummaryRow(label: 'Total', value: widget.total, bold: true),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: widget.addresses.isEmpty ? null : () async {
          final orderId = await widget.onOrderPlaced(payment, widget.addresses[selectedAddress.clamp(0, widget.addresses.length - 1)], widget.total);
          if (!context.mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: orderId, total: widget.total)));
        },
        child: const Text('Place Order'),
      ),
    ]),
  );
}

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.orderId, required this.total});
  final String orderId;
  final double total;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircleAvatar(radius: 42, backgroundColor: Color(0xFFDDF3E4), child: Icon(Icons.check, size: 48, color: Color(0xFF168447))),
        const SizedBox(height: 22),
        const Text('Order Placed Successfully!', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Thank you for shopping with Talegaon Fresh.', textAlign: TextAlign.center),
        const SizedBox(height: 26),
        Card(child: ListTile(title: const Text('Order ID'), subtitle: Text('#$orderId'), trailing: Text('₹${total.toStringAsFixed(0)}'))),
        const SizedBox(height: 18),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Shopping')),
      ]),
    )),
  );
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key, required this.orders});
  final List<OrderRecord> orders;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('My Orders', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 18),
      if (orders.isEmpty)
        const Card(child: ListTile(
          leading: Icon(Icons.receipt_long_outlined),
          title: Text('No orders yet'),
          subtitle: Text('Your completed orders will appear here.'),
        ))
      else
        ...orders.map((order) => Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.shopping_basket)),
          title: Text('#' + order.id, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(order.payment + ' • ₹' + order.total.toStringAsFixed(0)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsPage(order: order))),
        ))),
    ],
  );
}

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Order #' + order.id)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text('#' + order.id, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(order.payment + ' • ' + _formatDate(order.createdAt)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (order.items.isEmpty)
          const Card(child: ListTile(title: Text('Item details are unavailable for this order.')))
        else
          ...order.items.map((item) => Card(
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(item.quantity.toString() + ' × ₹' + item.price.toStringAsFixed(0) + ' / ' + item.unit),
              trailing: Text('₹' + item.total.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          )),
        const SizedBox(height: 10),
        SummaryRow(label: 'Order Total', value: order.total, bold: true),
        const SizedBox(height: 14),
        Card(child: ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Delivery Address'),
          subtitle: Text(order.address),
        )),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingPage(order: order))),
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Track Order'),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return local.day.toString().padLeft(2, '0') + '/' +
      local.month.toString().padLeft(2, '0') + '/' +
      local.year.toString() + ' ' +
      local.hour.toString().padLeft(2, '0') + ':' +
      local.minute.toString().padLeft(2, '0');
}

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key, required this.order});
  final OrderRecord order;
  @override
  Widget build(BuildContext context) {
    const steps = ['Order Placed', 'Payment Confirmed', 'Preparing Order', 'Out for Delivery', 'Delivered'];
    return Scaffold(
      appBar: AppBar(title: Text('Order #' + order.id)),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        for (var i = 0; i < steps.length; i++) ListTile(
          leading: Icon(i < 3 ? Icons.check_circle : Icons.radio_button_unchecked, color: i < 3 ? const Color(0xFF168447) : Colors.black26),
          title: Text(steps[i], style: TextStyle(fontWeight: i == 2 ? FontWeight.w800 : FontWeight.w500)),
          subtitle: i == 2 ? const Text('In Progress') : null,
        ),
        Card(child: ListTile(leading: const Icon(Icons.local_shipping_outlined), title: const Text('Delivery Address'), subtitle: Text(order.address))),
      ]),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, required this.products, required this.onAdd, required this.onToggleFavorite});

  final List<Product> products;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onToggleFavorite;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Favorites')),
    body: products.isEmpty
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.black26),
            SizedBox(height: 12),
            Text('No favorites yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('Tap the heart on a product to save it here.'),
          ]))
        : GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .78),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onAdd: onAdd,
                onOpen: (value) => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(product: value, onAdd: onAdd))),
                isFavorite: true,
                onToggleFavorite: onToggleFavorite,
              );
            },
          ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.session, required this.addresses, required this.onManageAddresses, required this.onManageFavorites, this.onSignOut});
  final CustomerSession session;
  final List<CustomerAddress> addresses;
  final VoidCallback onManageAddresses;
  final VoidCallback onManageFavorites;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('My Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 20),
      const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
      const SizedBox(height: 10),
      Center(child: Text(session.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
      const SizedBox(height: 4),
      Center(child: Text(session.phone, style: const TextStyle(color: Colors.black54))),
      const SizedBox(height: 22),
      Card(
        child: ListTile(
          leading: const Icon(Icons.favorite_border),
          title: const Text('My Favorites'),
          subtitle: const Text('View your saved products'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onManageFavorites,
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('My Addresses'),
          subtitle: Text(addresses.isEmpty ? 'Add a delivery address' : '${addresses.length} saved address${addresses.length == 1 ? '' : 'es'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onManageAddresses,
        ),
      ),
      ...['My Orders', 'Payment Methods', 'Notifications', 'Help & Support', 'About Talegaon Fresh']
        .map((x) => Card(child: ListTile(title: Text(x), trailing: const Icon(Icons.chevron_right)))),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: onSignOut, icon: const Icon(Icons.logout), label: const Text('Sign out')),
    ],
  );
}


class _AddressFormDialog extends StatefulWidget {
  const _AddressFormDialog({this.existing});

  final CustomerAddress? existing;

  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  late final TextEditingController label;
  late final TextEditingController address;
  late final TextEditingController city;
  late final TextEditingController pincode;
  late final TextEditingController landmark;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    label = TextEditingController(text: existing?.label ?? '');
    address = TextEditingController(text: existing?.fullAddress ?? '');
    city = TextEditingController(text: existing?.city ?? '');
    pincode = TextEditingController(text: existing?.pincode ?? '');
    landmark = TextEditingController(text: existing?.landmark ?? '');
  }

  @override
  void dispose() {
    label.dispose();
    address.dispose();
    city.dispose();
    pincode.dispose();
    landmark.dispose();
    super.dispose();
  }

  bool get validPincode => pincode.text.trim().length == 6 && int.tryParse(pincode.text.trim()) != null;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Add Address' : 'Edit Address'),
    content: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: label, decoration: const InputDecoration(labelText: 'Label (Home, Work...)')),
        TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
        TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
        TextField(controller: pincode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN code')),
        TextField(controller: landmark, decoration: const InputDecoration(labelText: 'Landmark (optional)')),
      ]),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          if (label.text.trim().isEmpty ||
              address.text.trim().isEmpty ||
              city.text.trim().isEmpty ||
              !validPincode) {
            return;
          }
          Navigator.pop(
            context,
            CustomerAddress(
              label: label.text.trim(),
              fullAddress: address.text.trim(),
              city: city.text.trim(),
              pincode: pincode.text.trim(),
              landmark: landmark.text.trim(),
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key, required this.addresses, required this.onChanged, this.api});
  final List<CustomerAddress> addresses;
  final VoidCallback onChanged;
  final HttpCustomerRepository? api;

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  Future<void> _editAddress({CustomerAddress? existing, int? index}) async {
    final result = await showDialog<CustomerAddress>(
      context: context,
      builder: (_) => _AddressFormDialog(existing: existing),
    );

    if (!mounted || result == null) return;
    try {
      final saved = widget.api == null ? result : (index == null ? await widget.api!.createAddress(result) : await widget.api!.updateAddress(result));
      if (!mounted) return;
      setState(() {
        if (index == null) widget.addresses.add(saved); else widget.addresses[index] = saved;
      });
      widget.onChanged();
    } on CustomerApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    widget.onChanged();
  }

  Future<void> _deleteAddress(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove ${widget.addresses[index].label} from saved addresses?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final id = widget.addresses[index].id;
      if (widget.api != null && id != null) await widget.api!.deleteAddress(id);
      if (!mounted) return;
      setState(() => widget.addresses.removeAt(index));
      widget.onChanged();
    } on CustomerApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Addresses')),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _editAddress(), icon: const Icon(Icons.add), label: const Text('Add Address')),
    body: widget.addresses.isEmpty
        ? const Center(child: Text('No saved addresses yet.'))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: widget.addresses.length,
            itemBuilder: (context, index) {
              final item = widget.addresses[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(item.landmark.isEmpty ? item.displayAddress : '${item.displayAddress}\n${item.landmark}'),
                  isThreeLine: item.landmark.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => value == 'edit' ? _editAddress(existing: item, index: index) : _deleteAddress(index),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
