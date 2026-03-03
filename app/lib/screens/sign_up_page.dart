import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:biblio/l10n/app_localizations.dart';
import 'package:biblio/screens/home_page.dart';
import 'package:biblio/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _step = 0;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  String _email = '';
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _loading = true;
      _email = email;
    });

    final result = await sendOtp(email);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.sent) {
      setState(() => _step = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.codeSent)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to send code')),
      );
    }
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() => _loading = true);

    final result = await verifyOtp(_email, otp);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.userId != null && result.email != null) {
      await context.read<MyAppState>().setSignedIn(result.userId!, result.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.signUpSuccess)),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Invalid code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signUp),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _step == 0 ? _buildEmailStep(l10n) : _buildOtpStep(l10n),
      ),
    );
  }

  Widget _buildEmailStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.signUpDescription,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.email,
            hintText: 'you@example.com',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _sendCode,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.sendCode),
        ),
      ],
    );
  }

  Widget _buildOtpStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.enterCodeDescription(_email),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: l10n.enterCode,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _verify,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.verify),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  setState(() {
                    _step = 0;
                    _otpController.clear();
                  });
                },
          child: Text(l10n.useDifferentEmail),
        ),
      ],
    );
  }
}
