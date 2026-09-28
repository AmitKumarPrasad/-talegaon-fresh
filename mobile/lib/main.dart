import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product_api.dart';

void main() => runApp(const TalegaonFreshApp());

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
  const LoginPage({super.key, required this.onAuthenticated});
  final ValueChanged<CustomerSession> onAuthenticated;

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

    if (!otpSent) {
      setState(() {
        loading = false;
        otpSent = true;
      });
      return;
    }

    if (otp.text.trim() != '123456') {
      setState(() {
        loading = false;
        error = 'Invalid OTP. Use 123456 for the demo flow.';
      });
      return;
    }

    setState(() => loading = false);
    widget.onAuthenticated(
      CustomerSession(
        phone: normalizedPhone,
        name: 'Talegaon Customer',
        token: 'demo-token',
      ),
    );
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
  const CustomerAddress({required this.label, required this.fullAddress, required this.city, required this.pincode, this.landmark = ''});
  final String label, fullAddress, city, pincode, landmark;
  String get displayAddress => [fullAddress, city, pincode].where((x) => x.isNotEmpty).join(', ');
}

class CartItem {
  CartItem(this.product, this.quantity);
  final Product product;
  int quantity;
}

class TalegaonFreshApp extends StatefulWidget {
  const TalegaonFreshApp({super.key});

  @override
  State<TalegaonFreshApp> createState() => _TalegaonFreshAppState();
}

class _TalegaonFreshAppState extends State<TalegaonFreshApp> {
  CustomerSession? session;

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
        ? LoginPage(onAuthenticated: (value) => setState(() => session = value))
        : AppShell(session: session!, onSignOut: () => setState(() => session = null)),
  );
}

class AppShell extends StatefulWidget {
  AppShell({super.key, ProductRepository? repository, required this.session, this.onSignOut})
      : repository = repository ?? HttpProductRepository();

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

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCart();
  }

  String get _cartStorageKey => 'talegaon_fresh_cart_${widget.session.phone}';

  Future<void> _loadCart() async {
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

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    final data = cart.map((item) => <String, dynamic>{
      'name': item.product.name,
      'unit': item.product.unit,
      'price': item.product.price,
      'quantity': item.quantity,
    }).toList();
    await prefs.setString(_cartStorageKey, jsonEncode(data));
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartStorageKey);
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(products: products, loading: loading, error: error, onRetry: _loadProducts, onAdd: add),
      ProductsPage(products: products, loading: loading, error: error, onRetry: _loadProducts, onAdd: add),
      CartPage(cart: cart, onChanged: _persistCart, addresses: addresses),
      const OrdersPage(),
      ProfilePage(
        session: widget.session,
        addresses: addresses,
        onManageAddresses: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddressBookPage(addresses: addresses, onChanged: () => setState(() {})))),
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
  const HomePage({super.key, required this.products, required this.loading, this.error, required this.onRetry, required this.onAdd});
  final List<Product> products;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Product> onAdd;

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
          delegate: SliverChildBuilderDelegate((context, i) => ProductCard(product: products[i], onAdd: onAdd), childCount: products.length > 4 ? 4 : products.length),
        ),
      ),
    ],
  );
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key, required this.products, required this.loading, this.error, required this.onRetry, required this.onAdd});
  final List<Product> products;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      const SliverAppBar.large(title: Text("Today's Products"), actions: [Icon(Icons.search), SizedBox(width: 18)]),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        sliver: SliverToBoxAdapter(
          child: Wrap(spacing: 8, children: ['All', 'Vegetables', 'Fruits', 'Leafy Greens'].map((x) => Chip(label: Text(x))).toList()),
        ),
      ),
      if (loading)
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())))
      else if (error != null)
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: ErrorCard(message: error!, onRetry: onRetry)))
      else if (products.isEmpty)
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No products are available today.'))))
      else
        SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .78),
          delegate: SliverChildBuilderDelegate((context, i) => ProductCard(product: products[i], onAdd: onAdd), childCount: products.length),
        ),
      ),
      ],
  );
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
  const ProductCard({super.key, required this.product, required this.onAdd});
  final Product product;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0, color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
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
  );
}

class CartPage extends StatelessWidget {
  const CartPage({super.key, required this.cart, required this.onChanged, required this.addresses});
  final List<CartItem> cart;
  final VoidCallback onChanged;
  final List<CustomerAddress> addresses;

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
        FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(total: total, addresses: addresses))), child: const Text('Proceed to Checkout')),
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
  const CheckoutPage({super.key, required this.total, required this.addresses});
  final double total;
  final List<CustomerAddress> addresses;
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
          value: selectedAddress.clamp(0, widget.addresses.length - 1),
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
      FilledButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderSuccessPage())), child: const Text('Place Order')),
    ]),
  );
}

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});
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
        const Card(child: ListTile(title: Text('Order ID'), subtitle: Text('#TF1001'), trailing: Text('Today'))),
        const SizedBox(height: 18),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Shopping')),
      ]),
    )),
  );
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('My Orders', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    const SizedBox(height: 18),
    Card(child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.shopping_basket)),
      title: const Text('#TF1001', style: TextStyle(fontWeight: FontWeight.w800)),
      subtitle: const Text('Payment Confirmed • Preparing Order'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingPage())),
    )),
  ]);
}

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});
  @override
  Widget build(BuildContext context) {
    const steps = ['Order Placed', 'Payment Confirmed', 'Preparing Order', 'Out for Delivery', 'Delivered'];
    return Scaffold(
      appBar: AppBar(title: const Text('Order #TF1001')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        for (var i = 0; i < steps.length; i++) ListTile(
          leading: Icon(i < 3 ? Icons.check_circle : Icons.radio_button_unchecked, color: i < 3 ? const Color(0xFF168447) : Colors.black26),
          title: Text(steps[i], style: TextStyle(fontWeight: i == 2 ? FontWeight.w800 : FontWeight.w500)),
          subtitle: i == 2 ? const Text('In Progress') : null,
        ),
        const Card(child: ListTile(leading: Icon(Icons.local_shipping_outlined), title: Text('Estimated Delivery'), subtitle: Text('Today, 5:00 PM - 7:00 PM'))),
      ]),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.session, required this.addresses, required this.onManageAddresses, this.onSignOut});
  final CustomerSession session;
  final List<CustomerAddress> addresses;
  final VoidCallback onManageAddresses;
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
  const AddressBookPage({super.key, required this.addresses, required this.onChanged});
  final List<CustomerAddress> addresses;
  final VoidCallback onChanged;

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
    setState(() {
      if (index == null) {
        widget.addresses.add(result);
      } else {
        widget.addresses[index] = result;
      }
    });
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
    setState(() => widget.addresses.removeAt(index));
    widget.onChanged();
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
