import 'package:flutter/material.dart';

class BottomNavbar extends StatefulWidget {
  final int currentIndex;

  const BottomNavbar({super.key, required this.currentIndex});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar>
    with TickerProviderStateMixin {
  late List<AnimationController> _iconControllers;
  late AnimationController _kameraController;
  late Animation<double> _kameraPulse;

  @override
  void initState() {
    super.initState();

    // Controller untuk tiap icon navbar (0=Beranda,1=Katalog,2=Notifikasi,3=Profil)
    _iconControllers = List.generate(4, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      // Icon yang aktif saat pertama langsung "terasa" sudah dipilih
      if (i == widget.currentIndex) ctrl.value = 1.0;
      return ctrl;
    });

    // Controller untuk tombol kamera — pulse terus-menerus
    _kameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _kameraPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _kameraController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(BottomNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Reset icon lama, bounce icon baru
      _iconControllers[oldWidget.currentIndex].reverse();
      _bounceIcon(widget.currentIndex);
    }
  }

  void _bounceIcon(int index) {
    final ctrl = _iconControllers[index];
    ctrl.reset();
    ctrl.forward();
  }

  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;
    _bounceIcon(index);
    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, '/beranda'); break;
      case 1: Navigator.pushReplacementNamed(context, '/katalog'); break;
      case 2: Navigator.pushReplacementNamed(context, '/notifikasi'); break;
      case 3: Navigator.pushReplacementNamed(context, '/profil'); break;
    }
  }

  @override
  void dispose() {
    for (final c in _iconControllers) c.dispose();
    _kameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Navbar dengan notch ──
          CustomPaint(
            size: Size(w, 72),
            painter: _NotchPainter(),
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Beranda',
                    isActive: widget.currentIndex == 0,
                    controller: _iconControllers[0],
                    onTap: () => _onTap(context, 0),
                  ),
                  _NavItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: 'Katalog',
                    isActive: widget.currentIndex == 1,
                    controller: _iconControllers[1],
                    onTap: () => _onTap(context, 1),
                  ),
                  const Expanded(child: SizedBox()),
                  _NavItem(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications_rounded,
                    label: 'Notifikasi',
                    isActive: widget.currentIndex == 2,
                    controller: _iconControllers[2],
                    onTap: () => _onTap(context, 2),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profil',
                    isActive: widget.currentIndex == 3,
                    controller: _iconControllers[3],
                    onTap: () => _onTap(context, 3),
                  ),
                ],
              ),
            ),
          ),

          // ── Floating kamera button dengan pulse ──
          Positioned(
            top: -24,
            child: ScaleTransition(
              scale: _kameraPulse,
              child: _KameraButton(
                onTap: () {
                  // Bounce sekali saat di tap
                  _kameraController.stop();
                  _kameraController.forward(from: 0).then((_) {
                    _kameraController.repeat(reverse: true);
                  });
                  Navigator.pushNamed(context, '/kamera');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kamera button ──
class _KameraButton extends StatefulWidget {
  final VoidCallback onTap;
  const _KameraButton({required this.onTap});

  @override
  State<_KameraButton> createState() => _KameraButtonState();
}

class _KameraButtonState extends State<_KameraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) {
        _tapCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapCtrl.reverse(),
      child: ScaleTransition(
        scale: _tapScale,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8956A), Color(0xFFD4865A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4865A).withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// ── Nav item dengan spring bounce ──
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final AnimationController controller;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Spring bounce: scale 1 → 1.35 → 1.1 → 1.0
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(controller);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (_, child) => Transform.scale(
                scale: scaleAnim.value,
                child: child,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? const Color(0xFFD4865A)
                    : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? const Color(0xFFD4865A)
                    : Colors.grey.shade400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Painter: notch shape ──
class _NotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    const double notchRadius = 36;
    final double centerX = size.width / 2;
    const double cornerRadius = 28;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.lineTo(centerX - notchRadius - 20, 0);
    path.cubicTo(
      centerX - notchRadius, 0,
      centerX - notchRadius, notchRadius + 8,
      centerX, notchRadius + 8,
    );
    path.cubicTo(
      centerX + notchRadius, notchRadius + 8,
      centerX + notchRadius, 0,
      centerX + notchRadius + 20, 0,
    );
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}