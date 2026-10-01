import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TalegaonLandingPage extends StatelessWidget {
  const TalegaonLandingPage({
    super.key,
    required this.onCreateAccount,
    required this.onSignIn,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;

  static const _green = Color(0xFF0B5B2C);
  static const _brightGreen = Color(0xFF159447);
  static const _yellow = Color(0xFFFFD73F);
  static const _ink = Color(0xFF14251A);
  static const _page = Color(0xFFF6F8EF);

  Future<void> _orderOnWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/918788543135?text=${Uri.encodeComponent('Hi FRESHORA, I would like to place an order.')}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open WhatsApp on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _page,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final compact = viewport.maxWidth < 720;
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 32,
                        compact ? 14 : 24,
                        compact ? 16 : 32,
                        28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(compact),
                          const SizedBox(height: 22),
                          _hero(compact),
                          const SizedBox(height: 26),
                          _benefits(compact),
                          const SizedBox(height: 28),
                          _whatsAppBanner(context, compact),
                          const SizedBox(height: 30),
                          _howItWorks(compact),
                          const SizedBox(height: 28),
                          _footer(compact),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _header(bool compact) => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFDDF3DF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: _green, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FRESHORA',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Freshness from farm to home',
                  style: TextStyle(color: Color(0xFF667268), fontSize: 12),
                ),
              ],
            ),
          ),
          if (!compact)
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: _LocationPill(),
            ),
          TextButton(onPressed: onSignIn, child: const Text('Sign in')),
          const SizedBox(width: 6),
          if (!compact)
            FilledButton(
              onPressed: onCreateAccount,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create account'),
            ),
        ],
      );

  Widget _hero(bool compact) {
    final copy = Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const _LocationPill(light: true),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            style: TextStyle(
              color: Colors.white,
              height: 1.02,
              fontSize: compact ? 34 : 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
            children: const [
              TextSpan(text: 'Fresh food,\n'),
              TextSpan(
                text: 'right to your door.',
                style: TextStyle(color: _yellow),
              ),
            ],
          ),
          textAlign: compact ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 14),
        Text(
          'Farm-fresh fruits and vegetables, carefully picked for your family in Talegaon and nearby areas.',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .87),
            fontSize: compact ? 15 : 17,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onCreateAccount,
              icon: const Icon(Icons.shopping_basket_outlined),
              label: const Text('Start shopping'),
              style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign in'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: .65)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final visual = _ProduceCollage(compact: compact);
    return Container(
      padding: EdgeInsets.all(compact ? 22 : 34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A4C28), Color(0xFF168B45), Color(0xFF31A554)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24104F2C),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: compact
          ? Column(
              children: [
                copy,
                const SizedBox(height: 12),
                visual,
              ],
            )
          : Row(
              children: [
                Expanded(flex: 11, child: copy),
                const SizedBox(width: 10),
                Expanded(flex: 9, child: visual),
              ],
            ),
    );
  }

  Widget _benefits(bool compact) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 850 ? 4 : 2;
          const gap = 12.0;
          final cardWidth =
              (constraints.maxWidth - gap * (columns - 1)) / columns;
          final benefits = [
            (Icons.eco_rounded, 'Freshly selected', 'Picked with care'),
            (
              Icons.workspace_premium_rounded,
              'Good quality',
              'Quality you can trust'
            ),
            (
              Icons.local_shipping_rounded,
              'Local delivery',
              'Talegaon & nearby'
            ),
            (Icons.storefront_rounded, 'Wide variety', 'Everyday favourites'),
          ];
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < benefits.length; i++)
                SizedBox(
                  width: cardWidth,
                  child: _BenefitCard(
                    icon: benefits[i].$1,
                    title: benefits[i].$2,
                    detail: benefits[i].$3,
                    accent: i == 1 ? const Color(0xFFF2A900) : _brightGreen,
                  ),
                ),
            ],
          );
        },
      );

  Widget _whatsAppBanner(BuildContext context, bool compact) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 32,
          vertical: compact ? 22 : 25,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF078C42),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F07512A),
              blurRadius: 20,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: compact
            ? Column(
                children: [
                  _whatsAppCopy(),
                  const SizedBox(height: 16),
                  _whatsAppButton(context, wide: true),
                ],
              )
            : Row(
                children: [
                  const CircleAvatar(
                    radius: 31,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.chat_rounded,
                        color: Color(0xFF078C42), size: 34),
                  ),
                  const SizedBox(width: 17),
                  Expanded(child: _whatsAppCopy()),
                  const SizedBox(width: 16),
                  _whatsAppButton(context),
                ],
              ),
      );

  Widget _whatsAppCopy() => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prefer WhatsApp?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Order directly with our local team',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );

  Widget _whatsAppButton(BuildContext context, {bool wide = false}) =>
      FilledButton.icon(
        onPressed: () => _orderOnWhatsApp(context),
        icon: const Icon(Icons.chat_bubble_rounded),
        label: const Text('Order on WhatsApp  •  87885 43135'),
        style: FilledButton.styleFrom(
          minimumSize: Size(wide ? double.infinity : 0, 52),
          backgroundColor: Colors.white,
          foregroundColor: _green,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      );

  Widget _howItWorks(bool compact) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Good food, made simple',
                  style: TextStyle(
                    color: _ink,
                    fontSize: compact ? 23 : 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
              ),
              if (!compact) const _LocationPill(),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'From choosing your produce to a fresh delivery at home.',
            style: TextStyle(color: Color(0xFF667268), fontSize: 15),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 5
                  : constraints.maxWidth >= 560
                      ? 3
                      : 1;
              const gap = 10.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              final steps = [
                (Icons.shopping_cart_rounded, 'Browse', 'Choose your produce'),
                (Icons.chat_rounded, 'Place an order', 'App or WhatsApp'),
                (
                  Icons.fact_check_rounded,
                  'We confirm',
                  'Availability and price'
                ),
                (
                  Icons.payments_rounded,
                  'Choose payment',
                  'UPI or cash on delivery'
                ),
                (Icons.home_rounded, 'Enjoy at home', 'Freshness delivered'),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    SizedBox(
                      width: width,
                      child: _StepCard(
                        number: i + 1,
                        icon: steps[i].$1,
                        title: steps[i].$2,
                        detail: steps[i].$3,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );

  Widget _footer(bool compact) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 28,
          vertical: compact ? 18 : 20,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF073D24),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceAround,
          runAlignment: WrapAlignment.center,
          spacing: 22,
          runSpacing: 14,
          children: const [
            _FooterValue(icon: Icons.eco_rounded, label: 'Fresh produce'),
            _FooterValue(icon: Icons.favorite_rounded, label: 'Healthy choice'),
            _FooterValue(icon: Icons.groups_rounded, label: 'Local business'),
            _FooterValue(
                icon: Icons.handshake_rounded, label: 'Here for our community'),
          ],
        ),
      );
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: light ? Colors.white.withValues(alpha: .13) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: light
              ? Border.all(color: Colors.white.withValues(alpha: .23))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 17,
              color: light ? const Color(0xFFFFD73F) : const Color(0xFFE4423B),
            ),
            const SizedBox(width: 5),
            Text(
              'Talegaon & nearby areas',
              style: TextStyle(
                color: light ? Colors.white : const Color(0xFF37453A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _ProduceCollage extends StatelessWidget {
  const _ProduceCollage({required this.compact});

  final bool compact;

  Widget _fruit(String path, double size) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            alignment: const Alignment(0, .06),
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFFEAF5E6),
              child: Icon(Icons.eco_rounded, color: TalegaonLandingPage._green, size: 42),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return SizedBox(
            height: compact ? 270 : 310,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: width * .08,
                  right: width * .08,
                  bottom: 5,
                  child: Container(
                    height: compact ? 72 : 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9A5829), Color(0xFFD1904F)],
                      ),
                      border:
                          Border.all(color: const Color(0xFFFFD39A), width: 3),
                    ),
                  ),
                ),
                Positioned(
                    left: width * .04,
                    top: 94,
                    child:
                        _fruit('assets/images/banana.png', compact ? 98 : 112)),
                Positioned(
                    left: width * .34,
                    top: 28,
                    child: _fruit(
                        'assets/images/tomato.png', compact ? 126 : 146)),
                Positioned(
                    right: width * .02,
                    top: 101,
                    child: _fruit(
                        'assets/images/grapes.png', compact ? 100 : 118)),
                Positioned(
                    left: width * .18,
                    top: compact ? 150 : 164,
                    child:
                        _fruit('assets/images/apple.png', compact ? 104 : 120)),
                Positioned(
                    right: width * .19,
                    top: compact ? 158 : 174,
                    child:
                        _fruit('assets/images/carrot.png', compact ? 96 : 112)),
                Positioned(
                  right: width * .04,
                  top: 10,
                  child: Transform.rotate(
                    angle: .13,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD73F),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: const Text('PICKED FRESH',
                          style: TextStyle(
                              color: TalegaonLandingPage._ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: .5)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EDE5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF203326))),
                  const SizedBox(height: 3),
                  Text(detail,
                      style: const TextStyle(
                          color: Color(0xFF718075), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final int number;
  final IconData icon;
  final String title;
  final String detail;

  static const _colors = [
    Color(0xFF8FE23E),
    Color(0xFF18B553),
    Color(0xFFFFC436),
    Color(0xFF34B7DA),
    Color(0xFFF579A9),
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDE5)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _colors[(number - 1) % _colors.length],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF143623), size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$number. $title',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF203326))),
                  const SizedBox(height: 3),
                  Text(detail,
                      style: const TextStyle(
                          color: Color(0xFF718075), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FooterValue extends StatelessWidget {
  const _FooterValue({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF8FDF54), size: 22),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      );
}
