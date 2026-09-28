import 'package:flutter/material.dart';

void main() => runApp(const TalegaonFreshApp());

class Product {
  const Product({required this.name, required this.unit, required this.price, required this.icon});
  final String name, unit;
  final double price;
  final IconData icon;
}

const products = <Product>[
  Product(name: 'Tomato', unit: '1 kg', price: 30, icon: Icons.circle),
  Product(name: 'Potato', unit: '1 kg', price: 25, icon: Icons.circle_outlined),
  Product(name: 'Onion', unit: '1 kg', price: 28, icon: Icons.spa),
  Product(name: 'Carrot', unit: '500 g', price: 32, icon: Icons.eco),
  Product(name: 'Capsicum', unit: '500 g', price: 40, icon: Icons.local_florist),
  Product(name: 'Cabbage', unit: '1 pc', price: 25, icon: Icons.grass),
];

class CartItem {
  CartItem(this.product, this.quantity);
  final Product product;
  int quantity;
}

class TalegaonFreshApp extends StatelessWidget {
  const TalegaonFreshApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Talegaon Fresh',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168447)),
      scaffoldBackgroundColor: const Color(0xFFF7FAF5),
    ),
    home: const AppShell(),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  final cart = <CartItem>[];

  void add(Product p) {
    setState(() {
      final matches = cart.where((x) => x.product.name == p.name);
      if (matches.isEmpty) {
        cart.add(CartItem(p, 1));
      } else {
        matches.first.quantity++;
      }
    });
  }

  int get count => cart.fold(0, (sum, x) => sum + x.quantity);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onAdd: add),
      ProductsPage(onAdd: add),
      CartPage(cart: cart, onChanged: () => setState(() {})),
      const OrdersPage(),
      const ProfilePage(),
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
  const HomePage({super.key, required this.onAdd});
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
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .82),
          delegate: SliverChildBuilderDelegate((context, i) => ProductCard(product: products[i], onAdd: onAdd), childCount: 4),
        ),
      ),
    ],
  );
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key, required this.onAdd});
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
  const CartPage({super.key, required this.cart, required this.onChanged});
  final List<CartItem> cart;
  final VoidCallback onChanged;

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
        FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(total: total))), child: const Text('Proceed to Checkout')),
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
  const CheckoutPage({super.key, required this.total});
  final double total;
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String payment = 'UPI';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      const Card(child: ListTile(leading: Icon(Icons.location_on, color: Color(0xFF168447)), title: Text('Home'), subtitle: Text('Talegaon, Maharashtra - 410507'))),
      const SizedBox(height: 22),
      const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      RadioListTile(value: 'UPI', groupValue: payment, onChanged: (v) => setState(() => payment = v!), title: const Text('UPI'), subtitle: const Text('Google Pay / PhonePe / Paytm')),
      RadioListTile(value: 'COD', groupValue: payment, onChanged: (v) => setState(() => payment = v!), title: const Text('Cash on Delivery')),
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
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('My Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    const SizedBox(height: 20),
    const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
    const SizedBox(height: 10),
    const Center(child: Text('Customer', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
    const SizedBox(height: 22),
    ...['My Orders', 'My Addresses', 'Payment Methods', 'Notifications', 'Help & Support', 'About Talegaon Fresh']
      .map((x) => Card(child: ListTile(title: Text(x), trailing: const Icon(Icons.chevron_right)))),
  ]);
}
