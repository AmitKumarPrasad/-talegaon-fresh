import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_api.dart';
import 'ai_assistant.dart';
import 'customer_api.dart';
import 'product_api.dart';
import 'admin_ui.dart';
import 'widgets/freshora_logo.dart';
import 'landing_page.dart';
import 'location_service.dart';

void main() => runApp(TalegaonFreshApp(authRepository: _createAuthRepository()));

AuthRepository _createAuthRepository() =>
    const String.fromEnvironment('AUTH_MODE', defaultValue: 'remote') == 'remote'
        ? HttpAuthRepository()
        : const DemoAuthRepository();

class CustomerSession {
  const CustomerSession({required this.phone, required this.name, this.token, this.refreshToken});
  final String phone;
  final String name;
  final String? token;
  final String? refreshToken;
}

class Product {
  const Product({required this.name, required this.unit, required this.price, required this.icon, this.imageUrl});
  final String name, unit;
  final double price;
  final IconData icon;
  final String? imageUrl;
}

const Map<String, String> _productImageUrls = {
  'tomato': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Tomato_je.jpg/400px-Tomato_je.jpg',
  'potato': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Patates.jpg/400px-Patates.jpg',
  'onion': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Mixed_onions.jpg/400px-Mixed_onions.jpg',
  'carrot': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Vegetable-Carrot-Bundle-wStalks.jpg/400px-Vegetable-Carrot-Bundle-wStalks.jpg',
  'capsicum': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Green-Yellow-Red-Pepper-2009.jpg/400px-Green-Yellow-Red-Pepper-2009.jpg',
  'cabbage': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Cabbage_and_cross_section_on_white.jpg/400px-Cabbage_and_cross_section_on_white.jpg',
  'cauliflower': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Chou-fleur_02.jpg/400px-Chou-fleur_02.jpg',
  'ladyfinger': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Hong_Kong_Okra_Aug_25_2012.JPG/400px-Hong_Kong_Okra_Aug_25_2012.JPG',
  'green beans': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Heaps_of_beans.jpg/400px-Heaps_of_beans.jpg',
  'spinach': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Spinacia_oleracea_Spinazie_bloeiend.jpg/400px-Spinacia_oleracea_Spinazie_bloeiend.jpg',
  'coriander': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/Coriandrum_sativum_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-193.jpg/400px-Coriandrum_sativum_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-193.jpg',
  'green chilli': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Madame_Jeanette_and_other_chillies.jpg/400px-Madame_Jeanette_and_other_chillies.jpg',
  'ginger': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Koeh-146-no_text.jpg/400px-Koeh-146-no_text.jpg',
  'garlic': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Allium_sativum_Woodwill_1793.jpg/400px-Allium_sativum_Woodwill_1793.jpg',
  'banana': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Bananavarieties.jpg/400px-Bananavarieties.jpg',
  'apple': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Pink_lady_and_cross_section.jpg/400px-Pink_lady_and_cross_section.jpg',
  'orange': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Oranges_-_whole-halved-segment.jpg/400px-Oranges_-_whole-halved-segment.jpg',
  'grapes': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Grapes%2C_Rostov-on-Don%2C_Russia.jpg/400px-Grapes%2C_Rostov-on-Don%2C_Russia.jpg',
  'pomegranate': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Pomegranate_Juice_%282019%29.jpg/400px-Pomegranate_Juice_%282019%29.jpg',
  'papaya': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Carica_papaya_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-029.jpg/400px-Carica_papaya_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-029.jpg',
};

String? _imageUrlForProduct(String name) => _productImageUrls[name.toLowerCase()];

// Bundled brand photos take priority over the network fallback map above.
// Drop a file at mobile/assets/images/<key>.png to enable it, e.g. "tomato.png".
const Map<String, String> _productAssetPaths = {
  'tomato': 'assets/images/tomato.png',
  'potato': 'assets/images/potato.png',
  'onion': 'assets/images/onion.png',
  'carrot': 'assets/images/carrot.png',
  'capsicum': 'assets/images/capsicum.png',
  'cabbage': 'assets/images/cabbage.png',
  'cauliflower': 'assets/images/cauliflower.png',
  'ladyfinger': 'assets/images/ladyfinger.png',
  'green beans': 'assets/images/green_beans.png',
  'spinach': 'assets/images/spinach.png',
  'coriander': 'assets/images/coriander.png',
  'green chilli': 'assets/images/green_chilli.png',
  'ginger': 'assets/images/ginger.png',
  'garlic': 'assets/images/garlic.png',
  'banana': 'assets/images/banana.png',
  'apple': 'assets/images/apple.png',
  'orange': 'assets/images/orange.png',
  'grapes': 'assets/images/grapes.png',
  'pomegranate': 'assets/images/pomegranate.png',
  'papaya': 'assets/images/papaya.png',
};

String? _assetPathForProduct(String name) => _productAssetPaths[name.toLowerCase()];


class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onAuthenticated, this.authRepository = const DemoAuthRepository(), this.onBack, this.initialRegisterMode = false});
  final ValueChanged<CustomerSession> onAuthenticated;
  final AuthRepository authRepository;
  final VoidCallback? onBack;
  final bool initialRegisterMode;
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final pin = TextEditingController();
  final name = TextEditingController();
  late bool registerMode;
  bool loading = false, obscure = true;
  String? error;

  @override
  void initState() {
    super.initState();
    registerMode = widget.initialRegisterMode;
  }

  @override void dispose() { phone.dispose(); pin.dispose(); name.dispose(); super.dispose(); }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    final normalized = phone.text.replaceAll(RegExp(r'\D'), '');
    if (normalized.length != 10) { setState(() => error = 'Enter a valid 10-digit mobile number.'); return; }
    if (!RegExp(r'^\d{6}$').hasMatch(pin.text)) { setState(() => error = 'PIN must contain exactly 6 digits.'); return; }
    if (registerMode && name.text.trim().isEmpty) { setState(() => error = 'Enter your name.'); return; }
    setState(() { loading = true; error = null; });
    try {
      final session = registerMode
          ? await widget.authRepository.register(normalized, pin.text, name.text.trim())
          : await widget.authRepository.login(normalized, pin.text);
      if (!mounted) return;
      widget.onAuthenticated(session);
    } on AuthException catch (e) {
      if (mounted) setState(() { loading = false; error = e.message; });
    } catch (_) {
      if (mounted) setState(() { loading = false; error = 'Something went wrong. Please try again.'; });
    }
  }

  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (widget.onBack != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Back to home',
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(22)),
                      child: Icon(Icons.eco_rounded, size: 42, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(height: 20),
                    Text('FRESHORA', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(registerMode ? 'Create your secure customer account.' : 'Welcome back. Sign in securely.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 22),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Sign in'), icon: Icon(Icons.login_rounded)),
                        ButtonSegment(value: true, label: Text('Create account'), icon: Icon(Icons.person_add_alt_1_rounded)),
                      ],
                      selected: {registerMode},
                      onSelectionChanged: loading ? null : (v) => setState(() { registerMode = v.first; error = null; }),
                    ),
                    const SizedBox(height: 22),
                    if (registerMode) ...[
                      TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded))),
                      const SizedBox(height: 14),
                    ],
                    TextField(controller: phone, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91 ', counterText: '', prefixIcon: Icon(Icons.phone_android_rounded))),
                    const SizedBox(height: 14),
                    TextField(
                      controller: pin,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: '6-digit PIN',
                        counterText: '',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                      child: const Row(children: [
                        Icon(Icons.verified_user_outlined, size: 19),
                        SizedBox(width: 10),
                        Expanded(child: Text('Your PIN is protected with one-way password hashing. Session tokens stay in secure device storage.', style: TextStyle(fontSize: 12.5))),
                      ]),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      Text(error!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: loading ? null : submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(registerMode ? 'Create secure account' : 'Sign in'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginPage())),
                      icon: const Icon(Icons.storefront_outlined, size: 18),
                      label: const Text('Store Admin Login'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    this.status = "CONFIRMED",
    this.items = const [],
    this.paymentLinkUrl,
  });

  final String id;
  final double total;
  final String payment;
  final String address;
  final String status;
  final DateTime createdAt;
  final List<OrderLine> items;
  final String? paymentLinkUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'total': total,
    'payment': payment,
    'address': address,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'paymentLinkUrl': paymentLinkUrl,
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
      createdAt: DateTime.tryParse(value['created_at'] is String ? value['created_at'] as String : '') ?? DateTime.now(),
      status: value['status'] is String ? value['status'] as String : 'CONFIRMED',
      items: items,
      paymentLinkUrl: value['payment_link_url'] is String ? value['payment_link_url'] as String : null,
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
    return OrderRecord(
      id: id,
      total: total.toDouble(),
      payment: payment,
      address: address,
      createdAt: date,
      status: value['status'] is String ? value['status'] as String : 'CONFIRMED',
      items: items,
      paymentLinkUrl: value['paymentLinkUrl'] is String ? value['paymentLinkUrl'] as String : null,
    );
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
  bool showSplash = true;
  bool showAuthentication = false;
  bool startWithCreateAccount = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => showSplash = false);
    });
  }

  Future<void> _restoreSession() async {
    try {
      final restored = await widget.authRepository.restoreSession();
      if (mounted && restored != null) setState(() => session = restored);
    } catch (_) {}
  }

  Future<void> _handleAuthenticated(CustomerSession value) async {
    if (mounted) {
      setState(() {
        session = value;
        showAuthentication = false;
      });
    }
  }

  void _openAuthentication({required bool createAccount}) {
    setState(() {
      startWithCreateAccount = createAccount;
      showAuthentication = true;
    });
  }

  Future<void> _signOut() async {
    await widget.authRepository.logout();
    if (mounted) {
      setState(() {
        session = null;
        showAuthentication = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FRESHORA',
    debugShowCheckedModeBanner: false,
    theme: _buildTheme(),
    home: showSplash
        ? const SplashScreen()
        : session == null
            ? showAuthentication
                ? LoginPage(
                    onAuthenticated: _handleAuthenticated,
                    authRepository: widget.authRepository,
                    initialRegisterMode: startWithCreateAccount,
                    onBack: () => setState(() => showAuthentication = false),
                  )
                : TalegaonLandingPage(
                    onCreateAccount: () => _openAuthentication(createAccount: true),
                    onSignIn: () => _openAuthentication(createAccount: false),
                  )
            : AppShell(session: session!, onSignOut: _signOut),
  );
}

const _brandGreen = Color(0xFF168447);
const _brandGreenDark = Color(0xFF0D5C30);
const _surfaceTint = Color(0xFFF7FAF5);

ThemeData _buildTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: _brandGreen);
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _surfaceTint,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: _surfaceTint,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _brandGreenDark,
        side: const BorderSide(color: _brandGreen, width: 1.3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _brandGreenDark),
    ),
    chipTheme: ChipThemeData(
      selectedColor: _brandGreen,
      backgroundColor: Colors.white,
      disabledColor: const Color(0xFFF0F3F1),
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      side: const BorderSide(color: Color(0xFFD7E0DA)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE1E8E3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _brandGreen, width: 1.6)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
        color: states.contains(WidgetState.selected) ? _brandGreenDark : Colors.black54,
      )),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFF8F0), Color(0xFFD8EFDD)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.eco, size: 72, color: Color(0xFF168447)),
            ),
            const SizedBox(height: 24),
            const Text('FRESHORA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF168447))),
            const SizedBox(height: 8),
            const Text('Fresh. Local. For a Healthier You.', style: TextStyle(fontSize: 15, color: Colors.black54)),
          ],
        ),
      ),
    ),
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
  // Production starts with no synthetic customer address. Remote addresses are loaded from the backend.
  // This prevents demo data from appearing when the backend is unavailable or still loading.
  final addresses = <CustomerAddress>[];
  final orders = <OrderRecord>[];
  late final HttpCustomerRepository customerApi;

  bool get _useRemoteCustomerApi => (widget.session.token ?? '').split('.').length == 3;
  final favorites = <String>{};
  String? cartSyncError;
  String? detectedLocation;

  @override
  void initState() {
    super.initState();
    customerApi = HttpCustomerRepository(token: widget.session.token ?? '');
    _loadProducts();
    _loadCart();
    _loadOrders();
    _loadAddresses();
    _loadFavorites();
    _clearRemoteLocalState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    final label = await detectCurrentLocationLabel();
    if (mounted && label != null) setState(() => detectedLocation = label);
  }

  String get _cartStorageKey => 'talegaon_fresh_cart_${widget.session.phone}';
  String get _ordersStorageKey => 'talegaon_fresh_orders_${widget.session.phone}';
  String get _addressesStorageKey => 'talegaon_fresh_addresses_${widget.session.phone}';
  String get _favoritesStorageKey => 'talegaon_fresh_favorites_${widget.session.phone}';

  Future<void> _clearRemoteLocalState() async {
    if (!_useRemoteCustomerApi) return;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_cartStorageKey),
      prefs.remove(_ordersStorageKey),
      prefs.remove(_addressesStorageKey),
    ]);
  }

  Future<void> _loadCart() async {
    if (_useRemoteCustomerApi) {
      try {
        final remote = await customerApi.getCart(products);
        if (mounted) {
          setState(() {
            cart..clear()..addAll(remote);
            cartSyncError = null;
          });
        }
        return;
      } on CustomerApiException catch (e) {
        if (e.statusCode == 401) {
          widget.onSignOut?.call();
          return;
        }
        if (mounted) setState(() => cartSyncError = e.message);
        return;
      } catch (_) {
        if (mounted) setState(() => cartSyncError = 'Could not load your cart. Please retry.');
        return;
      }
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
            imageUrl: _imageUrlForProduct(name),
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
    if (_useRemoteCustomerApi) {
      try {
        final remote = await customerApi.getAddresses();
        if (mounted) setState(() => addresses..clear()..addAll(remote));
      } on CustomerApiException catch (e) {
        if (e.statusCode == 401) {
          widget.onSignOut?.call();
          return;
        }
        if (mounted) setState(() => addresses.clear());
      } catch (_) {
        if (mounted) setState(() => addresses.clear());
      }
      return;
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
    }
  }

  Future<void> _persistAddresses() async {
    if (_useRemoteCustomerApi) return;
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
    if (_useRemoteCustomerApi) {
      try {
        final remote = await customerApi.getOrders();
        if (mounted) setState(() => orders..clear()..addAll(remote));
      } on CustomerApiException catch (e) {
        if (e.statusCode == 401) {
          widget.onSignOut?.call();
          return;
        }
        if (mounted) setState(() => orders.clear());
      } catch (_) {
        if (mounted) setState(() => orders.clear());
      }
      return;
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
    if (_useRemoteCustomerApi) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ordersStorageKey, jsonEncode(orders.map((order) => order.toJson()).toList()));
  }

  Future<void> _persistCart() async {
    if (_useRemoteCustomerApi) {
      try {
        await customerApi.replaceCart(cart);
        if (mounted && cartSyncError != null) setState(() => cartSyncError = null);
      } on CustomerApiException catch (e) {
        if (e.statusCode == 401) {
          widget.onSignOut?.call();
          return;
        }
        if (mounted) setState(() => cartSyncError = e.message);
      } catch (_) {
        if (mounted) setState(() => cartSyncError = 'Could not sync your cart. Please retry.');
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final data = cart.map((item) => <String, dynamic>{
      'name': item.product.name,
      'unit': item.product.unit,
      'price': item.product.price,
      'quantity': item.quantity,
    }).toList();
    await prefs.setString(_cartStorageKey, jsonEncode(data));
  }

  Future<OrderRecord> _completeOrder(String payment, CustomerAddress address, double total) async {
    if (_useRemoteCustomerApi) {
      final created = await customerApi.createOrder(List<CartItem>.from(cart), address, payment);
      setState(() { orders.insert(0, created); cart.clear(); });
      await customerApi.clearCart();
      if (payment == 'UPI') {
        final paymentUrl = await customerApi.createPaymentLink(int.parse(created.id));
        return OrderRecord(id: created.id, total: created.total, payment: created.payment, address: created.address, createdAt: created.createdAt, status: created.status, items: created.items, paymentLinkUrl: paymentUrl);
      }
      return created;
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
    return order;
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
                  imageUrl: p.imageUrl ?? _imageUrlForProduct(p.name),
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

  void _incrementCartItem(CartItem item) {
    setState(() => item.quantity++);
    _persistCart();
  }

  void _decrementCartItem(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        cart.remove(item);
      }
    });
    _persistCart();
  }

  void _removeCartItem(CartItem item) {
    setState(() => cart.remove(item));
    _persistCart();
  }

  int get count => cart.fold(0, (sum, x) => sum + x.quantity);

  void _openProduct(Product product) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product, onAdd: add)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(products: products, loading: loading, error: error, onRetry: _loadProducts, onAdd: add, onOpenProduct: _openProduct, favorites: favorites, onToggleFavorite: toggleFavorite, location: detectedLocation),
      ProductsPage(products: products, loading: loading, error: error, onRetry: _loadProducts, onAdd: add, onOpenProduct: _openProduct, favorites: favorites, onToggleFavorite: toggleFavorite),
      CartPage(cart: cart, onIncrement: _incrementCartItem, onDecrement: _decrementCartItem, onRemove: _removeCartItem, syncError: cartSyncError, onRetrySync: _persistCart, addresses: addresses, onOrderPlaced: _completeOrder, api: _useRemoteCustomerApi ? customerApi : null),
      OrdersPage(orders: orders, api: _useRemoteCustomerApi ? customerApi : null),
      AiAssistantPage(token: widget.session.token ?? ''),
      ProfilePage(
        session: widget.session,
        addresses: addresses,
        onManageAddresses: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddressBookPage(addresses: addresses, api: _useRemoteCustomerApi ? customerApi : null, onChanged: () { setState(() {}); _persistAddresses(); }))),
        onManageFavorites: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesPage(products: products.where((p) => favorites.contains(p.name)).toList(), onAdd: add, onToggleFavorite: toggleFavorite))),
        onViewOrders: () => setState(() => tab = 3),
        onSignOut: _signOut,
      ),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            indicatorColor: const Color(0xFFDCF2E1),
            backgroundColor: Colors.white,
            elevation: 0,
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Products'),
              NavigationDestination(
                icon: Badge(isLabelVisible: count > 0, label: Text(count.toString()), child: const Icon(Icons.shopping_cart_outlined)),
                selectedIcon: const Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
              const NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'AI'),
              const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.products, required this.loading, this.error, required this.onRetry, required this.onAdd, required this.onOpenProduct, required this.favorites, required this.onToggleFavorite, this.location});
  final List<Product> products;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onOpenProduct;
  final Set<String> favorites;
  final ValueChanged<Product> onToggleFavorite;
  final String? location;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Row(children: [
            const FreshoraLogo(size: 46),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('FRESHORA', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Row(children: [
                if (location != null) ...[
                  const Icon(Icons.location_on, size: 14, color: Colors.black54),
                  const SizedBox(width: 2),
                ],
                Flexible(child: Text(location ?? 'Freshness from farm to home', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54))),
              ]),
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

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Choose a category to narrow your fresh produce.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['All', 'Vegetables', 'Fruits', 'Leafy Greens'].map((value) => ChoiceChip(
                  label: Text(
                    value,
                    style: TextStyle(
                      color: category == value ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  selected: category == value,
                  selectedColor: _brandGreen,
                  checkmarkColor: Colors.white,
                  onSelected: (_) {
                    setSheetState(() => category = value);
                    setState(() {});
                  },
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply filter'),
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
    final query = searchController.text.trim().toLowerCase();
    final filtered = widget.products.where((product) {
      final matchesSearch = query.isEmpty || product.name.toLowerCase().contains(query) || product.unit.toLowerCase().contains(query);
      return matchesSearch && matchesCategory(product);
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _surfaceTint,
          surfaceTintColor: Colors.transparent,
          title: const Text('Fresh Products'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                onPressed: _showFilters,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _brandGreenDark,
                  side: const BorderSide(color: _brandGreen),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE5DE)),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search tomato, apple, spinach...',
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: Icon(Icons.mic_none_rounded),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const Spacer(),
                Text('${filtered.length} items', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD7E0DA)),
            ),
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  const values = ['All', 'Vegetables', 'Fruits', 'Leafy Greens'];
                  final value = values[index];
                  return ChoiceChip(
                    label: Text(
                      value,
                      style: TextStyle(
                        color: category == value ? Colors.white : _brandGreenDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    selected: category == value,
                    selectedColor: _brandGreen,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD7E0DA)),
                    onSelected: (_) => setState(() => category = value),
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.loading)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())))
        else if (widget.error != null)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: ErrorCard(message: widget.error!, onRetry: widget.onRetry)))
        else if (filtered.isEmpty)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No products match your search. Try another category or search term.'))))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: .70,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => ProductCard(
                  product: filtered[i],
                  onAdd: widget.onAdd,
                  onOpen: widget.onOpenProduct,
                  isFavorite: widget.favorites.contains(filtered[i].name),
                  onToggleFavorite: widget.onToggleFavorite,
                ),
                childCount: filtered.length,
              ),
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

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product, this.size = 62, this.borderRadius = 14});
  final Product product;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetPathForProduct(product.name);
    final url = product.imageUrl;
    Widget image;
    if (assetPath != null) {
      image = Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => url == null
            ? Icon(product.icon, size: size, color: const Color(0xFF2E9B55))
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(product.icon, size: size, color: const Color(0xFF2E9B55)),
              ),
      );
    } else if (url != null) {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Center(child: SizedBox(width: size * 0.4, height: size * 0.4, child: const CircularProgressIndicator(strokeWidth: 2))),
        errorBuilder: (context, error, stackTrace) => Icon(product.icon, size: size, color: const Color(0xFF2E9B55)),
      );
    } else {
      image = Icon(product.icon, size: size, color: const Color(0xFF2E9B55));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFEAF6EA),
        child: image,
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onAdd, required this.onOpen, required this.isFavorite, required this.onToggleFavorite});
  final Product product;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onOpen;
  final bool isFavorite;
  final ValueChanged<Product> onToggleFavorite;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpen(product),
        child: Stack(
          children: [
            Padding(
            padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Stack(children: [
            Positioned.fill(child: ProductImage(product: product)),
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF168447), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.eco, size: 11, color: Colors.white),
                  SizedBox(width: 3),
                  Text('Fresh', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ])),
          const SizedBox(height: 10),
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('₹' + product.price.toStringAsFixed(0) + '/' + product.unit, style: const TextStyle(color: Color(0xFF168447), fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: () => onAdd(product),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
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
        SizedBox(
          height: 260,
          width: double.infinity,
          child: ProductImage(product: widget.product, size: 120, borderRadius: 24),
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

/// Local promo codes: code -> (percentage off 0-1, flat max cap in rupees, flat discount if percent is null).
const Map<String, _PromoOffer> _promoCodes = {
  'FRESH10': _PromoOffer(percentOff: 0.10, maxOff: 50),
  'WELCOME50': _PromoOffer(flatOff: 50, minOrder: 199),
  'FRESHORA20': _PromoOffer(percentOff: 0.20, maxOff: 100, minOrder: 499),
};

class _PromoOffer {
  const _PromoOffer({this.percentOff, this.maxOff, this.flatOff, this.minOrder = 0});
  final double? percentOff;
  final double? maxOff;
  final double? flatOff;
  final double minOrder;

  double discountFor(double subtotal) {
    if (subtotal < minOrder) return 0;
    if (flatOff != null) return flatOff!;
    final raw = subtotal * (percentOff ?? 0);
    return maxOff == null ? raw : (raw > maxOff! ? maxOff! : raw);
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.cart, required this.onIncrement, required this.onDecrement, required this.onRemove, this.syncError, this.onRetrySync, required this.addresses, required this.onOrderPlaced, this.api});
  final List<CartItem> cart;
  final ValueChanged<CartItem> onIncrement;
  final ValueChanged<CartItem> onDecrement;
  final ValueChanged<CartItem> onRemove;
  final String? syncError;
  final Future<void> Function()? onRetrySync;
  final List<CustomerAddress> addresses;
  final Future<OrderRecord> Function(String payment, CustomerAddress address, double total) onOrderPlaced;
  final HttpCustomerRepository? api;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _promoController = TextEditingController();
  String? _appliedCode;
  String? _promoError;

  double get subtotal => widget.cart.fold(0, (sum, x) => sum + x.product.price * x.quantity);

  double get discount {
    final code = _appliedCode;
    if (code == null) return 0;
    return _promoCodes[code]!.discountFor(subtotal);
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    final offer = _promoCodes[code];
    setState(() {
      if (code.isEmpty) {
        _promoError = 'Enter a promo code';
        _appliedCode = null;
      } else if (offer == null) {
        _promoError = 'Invalid promo code';
        _appliedCode = null;
      } else if (subtotal < offer.minOrder) {
        _promoError = 'Add ₹${offer.minOrder.toStringAsFixed(0)} more to use this code';
        _appliedCode = null;
      } else {
        _promoError = null;
        _appliedCode = code;
      }
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cart.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.black26),
        SizedBox(height: 12),
        Text('Your cart is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text('Add fresh products to get started.'),
      ]));
    }
    final delivery = subtotal >= 199 ? 20.0 : 0.0;
    final total = subtotal + delivery - discount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text('My Cart', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        if (widget.syncError != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.onErrorContainer),
              title: const Text('Cart sync failed'),
              subtitle: Text(widget.syncError!),
              trailing: TextButton(onPressed: widget.onRetrySync, child: const Text('Retry')),
            ),
          ),
        if (widget.syncError != null) const SizedBox(height: 10),
        ...widget.cart.map((item) => Card(
          elevation: 0, child: ListTile(
            leading: SizedBox(width: 44, height: 44, child: ProductImage(product: item.product, size: 26, borderRadius: 10)),
            title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('₹' + item.product.price.toStringAsFixed(0) + ' / ' + item.product.unit),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(onPressed: () => widget.onDecrement(item), icon: const Icon(Icons.remove_circle_outline)),
              Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
              IconButton(onPressed: () => widget.onIncrement(item), icon: const Icon(Icons.add_circle_outline)),
              IconButton(onPressed: () => widget.onRemove(item), icon: const Icon(Icons.delete_outline), tooltip: 'Remove'),
            ]),
          ),
        )),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Promo code',
                errorText: _promoError,
                suffixIcon: _appliedCode != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
              ),
              onSubmitted: (_) => _applyPromo(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(onPressed: _applyPromo, child: const Text('Apply')),
        ]),
        const SizedBox(height: 16),
        SummaryRow(label: 'Subtotal', value: subtotal),
        SummaryRow(label: 'Delivery Fee', value: delivery),
        if (discount > 0) SummaryRow(label: 'Discount ($_appliedCode)', value: -discount),
        const Divider(height: 28),
        SummaryRow(label: 'Total', value: total, bold: true),
        const SizedBox(height: 18),
        FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(total: total, addresses: widget.addresses, onOrderPlaced: widget.onOrderPlaced, api: widget.api))), child: const Text('Proceed to Checkout')),
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
  const CheckoutPage({super.key, required this.total, required this.addresses, required this.onOrderPlaced, this.api});
  final double total;
  final List<CustomerAddress> addresses;
  final Future<OrderRecord> Function(String payment, CustomerAddress address, double total) onOrderPlaced;
  final HttpCustomerRepository? api;
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String payment = 'UPI';
  int selectedAddress = 0;
  bool savingAddress = false;

  Future<void> _addAddress() async {
    final result = await showDialog<CustomerAddress>(
      context: context,
      builder: (_) => const _AddressFormDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => savingAddress = true);
    try {
      final saved = widget.api == null ? result : await widget.api!.createAddress(result);
      if (!mounted) return;
      setState(() {
        widget.addresses.add(saved);
        selectedAddress = widget.addresses.length - 1;
        savingAddress = false;
      });
    } on CustomerApiException catch (e) {
      if (!mounted) return;
      setState(() => savingAddress = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => savingAddress = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save address. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      if (widget.addresses.isEmpty)
        const Card(child: ListTile(leading: Icon(Icons.location_off_outlined), title: Text('No saved address'), subtitle: Text('Add a delivery address to continue.')))
      else
        ...[
          for (var i = 0; i < widget.addresses.length; i++)
            Card(
              elevation: 0,
              color: selectedAddress == i ? const Color(0xFFE1F4E6) : Colors.white,
              child: ListTile(
                leading: Icon(selectedAddress == i ? Icons.radio_button_checked : Icons.radio_button_off, color: const Color(0xFF168447)),
                title: Text(widget.addresses[i].label, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(widget.addresses[i].displayAddress),
                onTap: () => setState(() => selectedAddress = i),
              ),
            ),
        ],
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: savingAddress ? null : _addAddress,
        icon: savingAddress ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
        label: Text(savingAddress ? 'Saving…' : '+ Add New Address'),
      ),
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
          try {
            final order = await widget.onOrderPlaced(payment, widget.addresses[selectedAddress.clamp(0, widget.addresses.length - 1)], widget.total);
            if (!context.mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessPage(order: order, api: widget.api)));
          } on CustomerApiException catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed, but payment setup could not be completed. Please check My Orders.')));
          }
        },
        child: const Text('Place Order'),
      ),
    ]),
  );
}

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key, required this.order, this.api});
  final OrderRecord order;
  final HttpCustomerRepository? api;

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  late OrderRecord order;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    order = widget.order;
  }

  Future<void> _refreshPayment() async {
    final api = widget.api;
    final id = int.tryParse(order.id);
    if (api == null || id == null || order.payment != 'UPI') return;
    setState(() => refreshing = true);
    try {
      final updated = await api.getOrder(id);
      if (mounted) setState(() => order = updated);
    } on CustomerApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> _pay(BuildContext context) async {
    final url = order.paymentLinkUrl;
    if (url == null) return;
    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the payment page.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(order.status == 'CONFIRMED' ? Icons.check_circle : Icons.payment, size: 56, color: const Color(0xFF168447)),
        const SizedBox(height: 22),
        Text(order.status == 'CONFIRMED' ? 'Order Placed Successfully!' : 'Order Created — Payment Pending', textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(order.status == 'CONFIRMED' ? 'Thank you for shopping with FRESHORA.' : 'Complete your UPI payment to confirm the order.', textAlign: TextAlign.center),
        const SizedBox(height: 26),
        Card(child: ListTile(title: const Text('Order ID'), subtitle: Text('#'+order.id), trailing: Text('₹'+order.total.toStringAsFixed(0)))),
        if (order.paymentLinkUrl != null) ...[
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: () => _pay(context), icon: const Icon(Icons.open_in_new), label: const Text('Pay with UPI')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: refreshing ? null : _refreshPayment, icon: const Icon(Icons.refresh), label: Text(refreshing ? 'Refreshing…' : 'Refresh payment status')),
        ],
        const SizedBox(height: 12),
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Continue Shopping')),
      ]),
    )),
  );
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.orders, this.api});
  final List<OrderRecord> orders;
  final HttpCustomerRepository? api;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool refreshing = false;

  Future<void> _refreshOrders() async {
    final api = widget.api;
    if (api == null) return;
    setState(() => refreshing = true);
    try {
      final latest = await api.getOrders();
      if (mounted) {
        setState(() {
          widget.orders
            ..clear()
            ..addAll(latest);
        });
      }
    } on CustomerApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Orders'),
      actions: [
        if (widget.api != null)
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: refreshing ? null : _refreshOrders,
            icon: refreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.orders.isEmpty)
            const Card(child: ListTile(
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('No orders yet'),
              subtitle: Text('Your completed orders will appear here.'),
            ))
          else
            ...widget.orders.map((order) => Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.shopping_basket)),
              title: Text('#' + order.id, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(order.payment + ' • ' + order.status + ' • ₹' + order.total.toStringAsFixed(0)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsPage(order: order, api: widget.api))),
            ))),
        ],
      ),
    ),
  );
}

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.order, this.api});

  final OrderRecord order;
  final HttpCustomerRepository? api;

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
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingPage(order: order, api: api))),
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

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key, required this.order, this.api});
  final OrderRecord order;
  final HttpCustomerRepository? api;

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late OrderRecord order;
  bool loading = false;
  String? error;
  OrderTracking? tracking;
  List<OrderChatMessage> messages = [];
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();
  bool _sendingMessage = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    order = widget.order;
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _refreshTrackingAndMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final api = widget.api;
    if (api == null || order.id.isEmpty) return;
    final id = int.tryParse(order.id);
    if (id == null) return;
    setState(() { loading = true; error = null; });
    try {
      final updated = await api.getOrder(id);
      if (mounted) setState(() => order = updated);
    } on CustomerApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
    await _refreshTrackingAndMessages();
  }

  Future<void> _refreshTrackingAndMessages() async {
    final api = widget.api;
    final id = int.tryParse(order.id);
    if (api == null || id == null || !mounted) return;
    try {
      final t = await api.getTracking(id);
      final m = await api.getMessages(id);
      if (mounted) setState(() { tracking = t; messages = m; });
      _scrollChatToBottom();
    } catch (_) {
      // Silently ignore polling failures.
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final api = widget.api;
    final id = int.tryParse(order.id);
    final text = _chatController.text.trim();
    if (api == null || id == null || text.isEmpty || _sendingMessage) return;
    setState(() => _sendingMessage = true);
    _chatController.clear();
    try {
      await api.sendMessage(id, text);
      await _refreshTrackingAndMessages();
    } on CustomerApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  Future<void> _openMap() async {
    final t = tracking;
    if (t == null || !t.hasLiveLocation) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${t.lat},${t.lng}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
    }
  }

  Future<void> _callDeliveryPerson() async {
    final phone = tracking?.deliveryPersonPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open dialer.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = ['PENDING', 'ADDRESS_CONFIRMED', 'PAYMENT_PENDING', 'CONFIRMED', 'PACKING', 'OUT_FOR_DELIVERY', 'DELIVERED'];
    final current = steps.indexOf(order.status);
    final effectiveIndex = current < 0 ? 0 : current;
    final t = tracking;
    return Scaffold(
      appBar: AppBar(title: Text('Order #' + order.id), actions: [IconButton(onPressed: loading ? null : _refresh, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
        for (var i = 0; i < steps.length; i++) ListTile(
          leading: Icon(i <= effectiveIndex ? Icons.check_circle : Icons.radio_button_unchecked, color: i <= effectiveIndex ? const Color(0xFF168447) : Colors.black26),
          title: Text(steps[i], style: TextStyle(fontWeight: i == effectiveIndex ? FontWeight.w800 : FontWeight.w500)),
          subtitle: i == effectiveIndex ? const Text('Current status') : null,
        ),
        Card(child: ListTile(leading: const Icon(Icons.local_shipping_outlined), title: const Text('Delivery Address'), subtitle: Text(order.address))),
        if (t != null && t.deliveryPersonName != null) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your Delivery Partner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                Row(children: [
                  const CircleAvatar(child: Icon(Icons.delivery_dining)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t.deliveryPersonName!, style: const TextStyle(fontWeight: FontWeight.w700))),
                  IconButton(onPressed: _callDeliveryPerson, icon: const Icon(Icons.call, color: Color(0xFF168447))),
                ]),
                if (t.hasLiveLocation) ...[
                  const SizedBox(height: 10),
                  Text(
                    t.updatedAt != null ? 'Location updated ${_formatDate(t.updatedAt!)}' : 'Live location available',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: _openMap, icon: const Icon(Icons.map_outlined), label: const Text('View Live Location on Map')),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Waiting for the delivery partner to share their location.', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Chat with Delivery Partner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 220,
                  child: messages.isEmpty
                      ? const Center(child: Text('No messages yet.', style: TextStyle(color: Colors.black45)))
                      : ListView.builder(
                          controller: _chatScrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final m = messages[index];
                            return Align(
                              alignment: m.fromCustomer ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                constraints: const BoxConstraints(maxWidth: 260),
                                decoration: BoxDecoration(
                                  color: m.fromCustomer ? const Color(0xFF168447) : const Color(0xFFEAF6EA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(m.message, style: TextStyle(color: m.fromCustomer ? Colors.white : Colors.black87)),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(hintText: 'Message your delivery partner…'),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _sendingMessage ? null : _sendMessage, icon: const Icon(Icons.send)),
                ]),
              ]),
            ),
          ),
        ],
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
  const ProfilePage({super.key, required this.session, required this.addresses, required this.onManageAddresses, required this.onManageFavorites, required this.onViewOrders, this.onSignOut});
  final CustomerSession session;
  final List<CustomerAddress> addresses;
  final VoidCallback onManageAddresses;
  final VoidCallback onManageFavorites;
  final VoidCallback onViewOrders;
  final VoidCallback? onSignOut;

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }

  String get _referralCode {
    final digits = session.phone.replaceAll(RegExp(r'\D'), '');
    final suffix = digits.length >= 4 ? digits.substring(digits.length - 4) : digits.padLeft(4, '0');
    return 'FRESHORA$suffix';
  }

  Future<void> _copyReferralCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _referralCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied')));
  }

  Future<void> _shareReferralCode(BuildContext context) async {
    final message = 'Get fresh fruits & veggies delivered with FRESHORA! '
        'Use my code $_referralCode to get a discount on your first order. '
        'Download the app and start shopping fresh today.';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp on this device.')));
    }
  }

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
        color: const Color(0xFFEAF6EA),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.card_giftcard, color: Color(0xFF0B5B2C)),
              SizedBox(width: 8),
              Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            const SizedBox(height: 6),
            const Text('Share FRESHORA with friends and family. They get a discount, you get rewarded.'),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0B5B2C), style: BorderStyle.solid),
                  ),
                  child: Text(_referralCode, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: () => _copyReferralCode(context), icon: const Icon(Icons.copy), tooltip: 'Copy code'),
            ]),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _shareReferralCode(context),
              icon: const Icon(Icons.share),
              label: const Text('Invite friends'),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 14),
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
      ...['My Orders', 'Payment Methods', 'Notifications', 'Help & Support', 'About FRESHORA']
        .map((x) => Card(child: ListTile(
          title: Text(x),
          trailing: const Icon(Icons.chevron_right),
          onTap: x == 'My Orders' ? onViewOrders : () => _showComingSoon(context, x),
        ))),
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
              id: widget.existing?.id,
              label: label.text.trim(),
              fullAddress: address.text.trim(),
              city: city.text.trim(),
              pincode: pincode.text.trim(),
              landmark: landmark.text.trim(),
              isDefault: widget.existing?.isDefault ?? false,
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
