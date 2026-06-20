import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text;
    final password = _passwordController.text;

    final success = await context.read<AuthProvider>().login(email, password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.danger,
            content: Text(
              'Invalid credentials! Use admin@ktlbd.com or store@ktlbd.com with pass 123456.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 850;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ── Branding Left Panel (Desktop/Web only) ─────────────────────────
          if (!isMobile)
            Expanded(
              flex: 4,
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      // StitchOS Logo
                      const StitchOSLogoWidget(size: 110),
                      const SizedBox(height: 16),
                      const Text(
                        'StitchOS',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(flex: 1),
                      // Bullet Points
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBulletPoint('Unlimited Product Upload'),
                            const SizedBox(height: 12),
                            _buildBulletPoint('Fashion Manufacturers'),
                            const SizedBox(height: 12),
                            _buildBulletPoint('Solutions For Fashion Brands'),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ),

          // ── Login Form Right Panel (Full Screen on Mobile) ─────────────────
          Expanded(
            flex: 6,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mobile logo on top
                          if (isMobile) ...[
                            Center(
                              child: Column(
                                children: [
                                  const StitchOSLogoWidget(size: 80),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'StitchOS',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],

                          // Sign In Header
                          const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sign up With open Account', // Matched mockup wording
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Google + Apple ID Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  label: 'Google',
                                  logo: _buildGoogleLogo(),
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSocialButton(
                                  label: 'Apple ID',
                                  logo: const Icon(Icons.apple, color: Colors.black, size: 18),
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Email Input
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Enter Your Email',
                              prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF9CA3AF), size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Input
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              hintText: 'Enter Your Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF9CA3AF),
                                  size: 18,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Sign Up (Login) Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E7EB3), // Mockup color matching #5E7EB3
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Sign Up', // Matches Mockup Text "Sign Up"
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF818CF8), width: 1.5),
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: Color(0xFF818CF8),
              size: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget logo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    // Basic Google colored logo drawing using standard containers/painting
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

// ─── StitchOS logo painter ───────────────────────────────────────────────────
class StitchOSLogoWidget extends StatelessWidget {
  final double size;
  const StitchOSLogoWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StitchOSLogoPainter(),
      ),
    );
  }
}

class _StitchOSLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final paintBlue = Paint()
      ..color = const Color(0xFF1E3A8A) // StitchOS Dark Blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round;

    final paintMagenta = Paint()
      ..color = const Color(0xFFF472B6) // StitchOS Magenta
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round;

    // Draw two interlocking rounded diamond loops representing the logo
    final pathBlue = Path();
    final pathMagenta = Path();

    // Blue loop (tilted to the top right)
    pathBlue.moveTo(center.dx - w * 0.22, center.dy + h * 0.08);
    pathBlue.lineTo(center.dx - w * 0.08, center.dy - h * 0.22);
    pathBlue.quadraticBezierTo(center.dx, center.dy - h * 0.32, center.dx + w * 0.14, center.dy - h * 0.22);
    pathBlue.lineTo(center.dx + w * 0.28, center.dy - h * 0.04);
    pathBlue.quadraticBezierTo(center.dx + w * 0.32, center.dy + h * 0.06, center.dx + w * 0.22, center.dy + h * 0.14);
    pathBlue.lineTo(center.dx + w * 0.04, center.dy + h * 0.24);

    // Magenta loop (interlocking from bottom left)
    pathMagenta.moveTo(center.dx + w * 0.22, center.dy - h * 0.08);
    pathMagenta.lineTo(center.dx + w * 0.08, center.dy + h * 0.22);
    pathMagenta.quadraticBezierTo(center.dx, center.dy + h * 0.32, center.dx - w * 0.14, center.dy + h * 0.22);
    pathMagenta.lineTo(center.dx - w * 0.28, center.dy + h * 0.04);
    pathMagenta.quadraticBezierTo(center.dx - w * 0.32, center.dy - h * 0.06, center.dx - w * 0.22, center.dy - h * 0.14);
    pathMagenta.lineTo(center.dx - w * 0.04, center.dy - h * 0.24);

    // Draw paths with nice soft overlap shadow if possible, or just standard clean stroke
    canvas.drawPath(pathBlue, paintBlue);
    canvas.drawPath(pathMagenta, paintMagenta);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw Google colored segments (G-like circle arcs)
    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    // Red (Top segment)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.14 * 1.15, 3.14 * 0.7, false, paint);

    // Yellow (Left segment)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 3.14 * 0.65, 3.14 * 0.5, false, paint);

    // Green (Bottom segment)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 3.14 * 0.15, 3.14 * 0.5, false, paint);

    // Blue (Right segment & bar)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 3.14 * 1.85, 3.14 * 0.3, false, paint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.5, h * 0.4, w * 0.45, h * 0.2), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
