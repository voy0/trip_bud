import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trip_bud/services/auth_service.dart';
import 'package:trip_bud/l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChange;

  const ResetPasswordScreen({super.key, this.onLocaleChange});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    final loc = AppLocalizations.of(context);
    if (_emailController.text.isEmpty) {
      setState(() => _message = loc.pleaseEnterEmail);
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final authService = context.read<AuthService>();
      final success = await authService.resetPassword(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSuccess = success;
          _message = success
              ? 'Password reset email sent. Check your inbox.'
              : 'Failed to send reset email. Try again.';
        });

        if (success) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'An error occurred: ${e.toString()}';
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'pl':
        return 'Polski';
      default:
        return 'English';
    }
  }

  void _showLanguageSelector() {
    final loc = AppLocalizations.of(context);
    final currentLanguage = Localizations.localeOf(context).languageCode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(_getLanguageName('en')),
              trailing: currentLanguage == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                widget.onLocaleChange?.call(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(_getLanguageName('es')),
              trailing: currentLanguage == 'es'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                widget.onLocaleChange?.call(const Locale('es'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(_getLanguageName('pl')),
              trailing: currentLanguage == 'pl'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                widget.onLocaleChange?.call(const Locale('pl'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.resetPasswordTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSelector,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Animated Logo
            SvgPicture.asset(
              'assets/tripbud_logo.svg',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 32),
            const Text(
              'Reset Your Password',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email and we\'ll send you a link to reset your password',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleReset,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Send Reset Email',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
