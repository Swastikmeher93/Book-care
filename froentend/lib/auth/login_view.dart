import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

@immutable
class LoginState {
  const LoginState({this.isSigningIn = false, this.errorMessage});

  final bool isSigningIn;
  final String? errorMessage;

  LoginState copyWith({bool? isSigningIn, String? errorMessage}) {
    return LoginState(
      isSigningIn: isSigningIn ?? this.isSigningIn,
      errorMessage: errorMessage,
    );
  }
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() {
    return const LoginState();
  }

  Future<void> signInWithGoogle() async {
    if (state.isSigningIn) {
      return;
    }

    state = const LoginState(isSigningIn: true);

    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
      state = const LoginState();
    } catch (_) {
      state = const LoginState(
        errorMessage: 'Unable to start Google sign in. Please try again.',
      );
    }
  }
}

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      final errorMessage = next.errorMessage;
      if (errorMessage == null || errorMessage == previous?.errorMessage) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    final loginState = ref.watch(loginControllerProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = width.clamp(0.0, 430.0);

            return SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      const _HeroHeader(),
                      Transform.translate(
                        offset: const Offset(0, -42),
                        child: _SignInCard(
                          isSigningIn: loginState.isSigningIn,
                          onGooglePressed: () => ref
                              .read(loginControllerProvider.notifier)
                              .signInWithGoogle(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const _BenefitsRow(),
                      SizedBox(
                        height: (constraints.maxHeight - 760).clamp(
                          76.0,
                          224.0,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 14),
                        child: _AgreementText(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 342,
      decoration: const BoxDecoration(
        color: Color(0xFF2F80FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(46),
          bottomRight: Radius.circular(46),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'CareBook',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Healthcare booking made simple',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({required this.isSigningIn, required this.onGooglePressed});

  final bool isSigningIn;
  final VoidCallback onGooglePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 64).clamp(0.0, 318.0),
      height: 272,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6E6EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome back',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF07080C),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Sign in to book and manage your\nhealthcare services',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7E7E89),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          _GoogleButton(
            isLoading: isSigningIn,
            onPressed: isSigningIn ? null : onGooglePressed,
          ),
          const SizedBox(height: 12),
          const _DividerLabel(),
          const SizedBox(height: 10),
          const _SecurityBadge(),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF111216),
          side: const BorderSide(color: Color(0xFFE2E3E8), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          backgroundColor: Colors.white,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('google-loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Row(
                  key: ValueKey('google-label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GoogleMark(),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Continue with Google',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/googlelogo.png',
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE4E5EA), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Secure sign in',
            style: TextStyle(
              color: const Color(0xFF7E7E89).withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE4E5EA), thickness: 1)),
      ],
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF2F80FF),
            size: 19,
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Your data is encrypted & protected',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF22232A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsRow extends StatelessWidget {
  const _BenefitsRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: _BenefitItem(
              icon: Icons.event_available_outlined,
              label: 'Easy booking',
            ),
          ),
          Expanded(
            child: _BenefitItem(
              icon: Icons.medical_services_outlined,
              label: 'Trusted care',
            ),
          ),
          Expanded(
            child: _BenefitItem(
              icon: Icons.access_time_outlined,
              label: '24/7 access',
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F4F6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2F80FF), size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7E7E89),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AgreementText extends StatelessWidget {
  const _AgreementText();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'By continuing you agree to our ',
        style: const TextStyle(
          color: Color(0xFF7E7E89),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: 'Terms',
            style: const TextStyle(
              color: Color(0xFF2F80FF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: '&'),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
              color: Color(0xFF2F80FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
