import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_api.dart';

const _brandGreen = Color(0xFF168447);

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _tokenController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _restoreToken();
  }

  Future<void> _restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('talegaon_fresh_admin_token');
    if (saved != null && saved.isNotEmpty && mounted) {
      _tokenController.text = saved;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Enter the admin access token.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = HttpAdminRepository(token: token);
      await repo.listOrders();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('talegaon_fresh_admin_token', token);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboardPage(token: token)),
      );
    } on AdminApiException catch (e) {
      setState(() => _error = e.statusCode == 401 ? 'Invalid admin token.' : e.message);
    } catch (_) {
      setState(() => _error = 'Could not connect. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Access')),
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
                  const Icon(Icons.admin_panel_settings, size: 48, color: _brandGreen),
                  const SizedBox(height: 12),
                  const Text(
                    'Talegaon Fresh Admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the store admin access token to manage orders, stock and prices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _tokenController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Admin token',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Checking…' : 'Sign in'),
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

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.token});
  final String token;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _tab = 0;
  late final HttpAdminRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = HttpAdminRepository(token: widget.token);
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('talegaon_fresh_admin_token');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminSummaryTab(repo: _repo),
      AdminOrdersTab(repo: _repo),
      AdminInventoryTab(repo: _repo),
      AdminPricesTab(repo: _repo),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [IconButton(onPressed: _signOut, icon: const Icon(Icons.logout), tooltip: 'Sign out')],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.sell_outlined), selectedIcon: Icon(Icons.sell), label: 'Prices'),
        ],
      ),
    );
  }
}

class AdminSummaryTab extends StatefulWidget {
  const AdminSummaryTab({super.key, required this.repo});
  final HttpAdminRepository repo;

  @override
  State<AdminSummaryTab> createState() => _AdminSummaryTabState();
}

class _AdminSummaryTabState extends State<AdminSummaryTab> {
  bool _loading = true;
  String? _error;
  AdminDashboardSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await widget.repo.getDashboardSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } on AdminApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load dashboard.';
        _loading = false;
      });
    }
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(_error!)))]),
      );
    }
    final s = _summary!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Today's Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(children: [
            _statCard('Orders today', s.todaysOrderCount.toString(), Icons.receipt_long, _brandGreen),
            const SizedBox(width: 12),
            _statCard('Revenue today', '₹${s.todaysRevenue.toStringAsFixed(0)}', Icons.currency_rupee, _brandGreen),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _statCard('Active orders', s.pendingOrders.toString(), Icons.local_shipping_outlined, Colors.orange),
            const SizedBox(width: 12),
            _statCard('Out of stock', s.outOfStockCount.toString(), Icons.warning_amber_rounded, Colors.red),
          ]),
          const SizedBox(height: 20),
          Text('Products (${s.totalProducts})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (s.lowStockProducts.isEmpty)
            const Text('No products are low on stock.', style: TextStyle(color: Colors.black54))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Low stock (≤10 units)', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ...s.lowStockProducts.map((name) => Text('• $name')),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key, required this.repo});
  final HttpAdminRepository repo;

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  static const _statuses = ['ALL', 'PENDING', 'ADDRESS_CONFIRMED', 'PAYMENT_PENDING', 'CONFIRMED', 'PACKING', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'];
  String _status = 'ALL';
  bool _loading = true;
  String? _error;
  List<AdminOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await widget.repo.listOrders(status: _status);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } on AdminApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load orders.';
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(AdminOrder order, String status) async {
    try {
      await widget.repo.updateOrderStatus(order.orderId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order #${order.orderId} updated to $status')));
      _load();
    } on AdminApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _statuses.map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s.replaceAll('_', ' ')),
                selected: _status == s,
                onSelected: (_) {
                  setState(() => _status = s);
                  _load();
                },
              ),
            )).toList(),
          ),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(_error!)))])
                  : _orders.isEmpty
                      ? ListView(children: const [Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No orders found.')))])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _orders.length,
                          itemBuilder: (context, i) {
                            final order = _orders[i];
                            return Card(
                              child: ExpansionTile(
                                title: Text('Order #${order.orderId}  •  ${order.customerId}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text('${order.status}  •  ₹${order.total.toStringAsFixed(0)}${order.paymentMethod != null ? '  •  ${order.paymentMethod}' : ''}'),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Delivery: ${order.address}', style: const TextStyle(color: Colors.black54)),
                                        const SizedBox(height: 8),
                                        for (final item in order.items)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Text('${item.quantity} × ${item.name} — ₹${item.lineTotal.toStringAsFixed(0)}'),
                                          ),
                                        const SizedBox(height: 12),
                                        if (order.allowedNextStatuses.isEmpty)
                                          const Text('No further status changes available.', style: TextStyle(color: Colors.black45))
                                        else
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: order.allowedNextStatuses.map((s) => OutlinedButton(
                                              onPressed: () => _updateStatus(order, s),
                                              child: Text('Mark ${s.replaceAll('_', ' ')}'),
                                            )).toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ),
    ],
  );
}

class AdminInventoryTab extends StatefulWidget {
  const AdminInventoryTab({super.key, required this.repo});
  final HttpAdminRepository repo;

  @override
  State<AdminInventoryTab> createState() => _AdminInventoryTabState();
}

class _AdminInventoryTabState extends State<AdminInventoryTab> {
  bool _loading = true;
  String? _error;
  List<AdminProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await widget.repo.listInventory();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } on AdminApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load inventory.';
        _loading = false;
      });
    }
  }

  Future<void> _editStock(AdminProduct product) async {
    final controller = TextEditingController(text: (product.stockQuantity ?? 0).toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update stock — ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value >= 0) Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await widget.repo.updateStock(product.id, result);
      _load();
    } on AdminApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _createProduct() async {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final imageUrlController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Product'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit (e.g. 1 kg)')),
            TextField(controller: priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price (₹)')),
            TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial stock quantity')),
            TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Image URL (optional)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (result != true) return;
    final price = double.tryParse(priceController.text.trim());
    final stock = int.tryParse(stockController.text.trim()) ?? 0;
    if (nameController.text.trim().isEmpty || unitController.text.trim().isEmpty || price == null || price <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid name, unit and price.')));
      return;
    }
    try {
      await widget.repo.createProduct(
        name: nameController.text.trim(),
        unit: unitController.text.trim(),
        price: price,
        stockQuantity: stock,
        imageUrl: imageUrlController.text.trim().isEmpty ? null : imageUrlController.text.trim(),
      );
      _load();
    } on AdminApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteProduct(AdminProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove ${product.name} from the catalog? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repo.deleteProduct(product.id);
      _load();
    } on AdminApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: _createProduct, icon: const Icon(Icons.add), label: const Text('New Product')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(_error!)))])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemCount: _products.length,
                  itemBuilder: (context, i) {
                    final product = _products[i];
                    return Card(
                      child: ListTile(
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${product.unit}  •  ${product.inStock ? "In stock" : "Out of stock"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${product.stockQuantity ?? 0}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editStock(product)),
                            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteProduct(product)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    ),
  );
}

class AdminPricesTab extends StatefulWidget {
  const AdminPricesTab({super.key, required this.repo});
  final HttpAdminRepository repo;

  @override
  State<AdminPricesTab> createState() => _AdminPricesTabState();
}

class _AdminPricesTabState extends State<AdminPricesTab> {
  bool _loading = true;
  String? _error;
  List<AdminProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await widget.repo.listPrices();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } on AdminApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load prices.';
        _loading = false;
      });
    }
  }

  Future<void> _editPrice(AdminProduct product) async {
    final controller = TextEditingController(text: (product.price ?? 0).toStringAsFixed(0));
    final imageUrlController = TextEditingController(text: product.imageUrl ?? '');
    bool inStock = product.inStock;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update price — ${product.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price (₹)'),
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('In stock'),
                  value: inStock,
                  onChanged: (v) => setDialogState(() => inStock = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                if (value != null && value > 0) {
                  Navigator.pop(context, {'price': value, 'inStock': inStock, 'imageUrl': imageUrlController.text.trim()});
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    try {
      final imageUrl = (result['imageUrl'] as String).isEmpty ? null : result['imageUrl'] as String;
      await widget.repo.updatePrice(product.id, result['price'] as double, inStock: result['inStock'] as bool, imageUrl: imageUrl);
      _load();
    } on AdminApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(_error!)))])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: _products.length,
                itemBuilder: (context, i) {
                  final product = _products[i];
                  return Card(
                    child: ListTile(
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(product.inStock ? 'In stock' : 'Out of stock'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${(product.price ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _brandGreen)),
                          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editPrice(product)),
                        ],
                      ),
                    ),
                  );
                },
              ),
  );
}
