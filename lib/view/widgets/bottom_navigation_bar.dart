import 'package:flutter/material.dart';
import 'package:supporthive1/controller/home_controller.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final HomeController controller;
  const CustomBottomNavigationBar({super.key, required this.controller});

  static const _brandGreen = Color(0xFF4A6741);

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Explore'),
    _NavItem(icon: Icons.favorite_outline, activeIcon: Icons.favorite_rounded, label: 'Counselling'),
    _NavItem(icon: Icons.sports_esports_outlined, activeIcon: Icons.sports_esports_rounded, label: 'Games'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(_items.length, (index) {
                  final isSelected = controller.selectedTabIndex == index;
                  return Expanded(
                    child: _NavBarButton(
                      item: _items[index],
                      isSelected: isSelected,
                      onTap: () => controller.setTabIndex(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Individual Nav Button
// ─────────────────────────────────────────────────────────
class _NavBarButton extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarButton> createState() => _NavBarButtonState();
}

class _NavBarButtonState extends State<_NavBarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _labelOpacity;

  static const _brandGreen = Color(0xFF4A6741);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.isSelected ? 1.0 : 0.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
    _labelOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeIn),
    );
  }

  @override
  void didUpdateWidget(_NavBarButton old) {
    super.didUpdateWidget(old);
    if (widget.isSelected != old.isSelected) {
      if (widget.isSelected) {
        _anim.forward();
      } else {
        _anim.reverse();
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isSelected ? 16 : 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? _brandGreen.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ScaleTransition(
                  scale: _scale,
                  child: Icon(
                    widget.isSelected
                        ? widget.item.activeIcon
                        : widget.item.icon,
                    color: widget.isSelected ? _brandGreen : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Label
              FadeTransition(
                opacity: _labelOpacity,
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: widget.isSelected ? _brandGreen : Colors.grey.shade400,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}