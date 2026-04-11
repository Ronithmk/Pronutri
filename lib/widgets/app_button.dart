import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Color? color;
  final IconData? icon;

  const AppButton({super.key, required this.label, this.onTap, this.loading = false, this.color, this.icon});

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? AppColors.primary;

    return GestureDetector(
      onTapDown: (_) { if (!widget.loading && widget.onTap != null) _ctrl.forward(); },
      onTapUp: (_) { _ctrl.reverse(); },
      onTapCancel: () { _ctrl.reverse(); },
      onTap: widget.loading ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [baseColor, baseColor.withBlue((baseColor.blue + 30).clamp(0, 255))],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.loading || widget.onTap == null
                ? []
                : [
                    BoxShadow(
                      color: baseColor.withOpacity(0.38),
                      blurRadius: 20,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.25),
                      blurRadius: 6,
                      spreadRadius: -2,
                      offset: const Offset(-2, -2),
                    ),
                  ],
          ),
          child: widget.loading
              ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: Colors.white), const SizedBox(width: 8)],
                  Text(widget.label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2)),
                ]),
        ),
      ),
    );
  }
}
