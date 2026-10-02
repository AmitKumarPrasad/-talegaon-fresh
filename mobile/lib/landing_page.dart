import 'package:flutter/material.dart';
import 'widgets/freshora_logo.dart';

class TalegaonLandingPage extends StatelessWidget {
  const TalegaonLandingPage({
    super.key,
    required this.onCreateAccount,
    required this.onSignIn,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;

  static const _green = Color(0xFF0B5B2C);
  static const _yellow = Color(0xFFFFD73F);
  static const _ink = Color(0xFF14251A);
  static const _page = Color(0xFFF6F8EF);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _page,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final compact = viewport.maxWidth < 720;
              final horizontalPadding = compact ? 16.0 : 32.0;
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 14 : 24,
                        horizontalPadding,
                        28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(compact),
                          const SizedBox(height: 32),
                          _hero(compact),
                          const SizedBox(height: 20),
                          const Text(
                            'Fresh fruits and vegetables, simply delivered.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF667268), fontSize: 15),
                          ),
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
          const FreshoraLogo(size: 48),
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
            FilledButton(
              onPressed: onCreateAccount,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create account'),
            )
          else
            TextButton(onPressed: onSignIn, child: const Text('Sign in')),
        ],
      );

  Widget _hero(bool compact) {
    final copy = Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const FreshoraLogo(size: 56),
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
          'Farm-fresh fruits and vegetables, carefully picked for your family, every day.',
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
                        _fruit('assets/images/products/banana.png', compact ? 98 : 112)),
                Positioned(
                    left: width * .34,
                    top: 28,
                    child: _fruit(
                        'assets/images/products/tomatoes.png', compact ? 126 : 146)),
                Positioned(
                    right: width * .02,
                    top: 101,
                    child: _fruit(
                        'assets/images/products/green_grapes.png', compact ? 100 : 118)),
                Positioned(
                    left: width * .18,
                    top: compact ? 150 : 164,
                    child:
                        _fruit('assets/images/products/apples.png', compact ? 104 : 120)),
                Positioned(
                    right: width * .19,
                    top: compact ? 158 : 174,
                    child:
                        _fruit('assets/images/products/carrots.png', compact ? 96 : 112)),
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

