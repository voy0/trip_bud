import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/services/auth_service.dart';
import 'package:trip_bud/l10n/app_localizations.dart';

class UserProfileScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChange;

  const UserProfileScreen({super.key, this.onLocaleChange});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = false;
  final Color _accentColor = const Color.fromARGB(255, 0, 200, 120);

  void _handleLogout() async {
    final loc = AppLocalizations.of(context);
    final authService = context.read<AuthService>();
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.logout),
        content: Text(loc.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);

              try {
                await authService.logout();

                if (!mounted) return;
                navigator.pushReplacementNamed('/login');
              } catch (e) {
                if (!mounted) return;
                scaffold.showSnackBar(
                  SnackBar(
                    content: Text('${AppLocalizations.of(context).error}$e'),
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: Text(loc.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
    final authService = context.read<AuthService>();
    final currentUser = authService.getCurrentUser();
    final loc = AppLocalizations.of(context);
    final currentLanguage = Localizations.localeOf(context).languageCode;
    final onLocaleChange = widget.onLocaleChange;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(_getLanguageName('en')),
              trailing: currentLanguage == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                if (currentUser != null) {
                  await authService.updateUserLanguage(currentUser.id, 'en');
                }
                if (mounted) {
                  onLocaleChange?.call(const Locale('en'));
                  // ignore: use_build_context_synchronously
                  Navigator.pop(dialogContext);
                }
              },
            ),
            ListTile(
              title: Text(_getLanguageName('es')),
              trailing: currentLanguage == 'es'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                if (currentUser != null) {
                  await authService.updateUserLanguage(currentUser.id, 'es');
                }
                if (mounted) {
                  onLocaleChange?.call(const Locale('es'));
                  // ignore: use_build_context_synchronously
                  Navigator.pop(dialogContext);
                }
              },
            ),
            ListTile(
              title: Text(_getLanguageName('pl')),
              trailing: currentLanguage == 'pl'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                if (currentUser != null) {
                  await authService.updateUserLanguage(currentUser.id, 'pl');
                }
                if (mounted) {
                  onLocaleChange?.call(const Locale('pl'));
                  // ignore: use_build_context_synchronously
                  Navigator.pop(dialogContext);
                }
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
    final authService = context.read<AuthService>();
    final currentUser = authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(title: Text(loc.settings), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withValues(alpha: 0.2),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: _accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // User Info
                          Text(
                            currentUser?.displayName ?? 'Trip Buddy',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentUser?.email ?? 'No email',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Settings Section
                  Text(
                    loc.settings,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Language Setting
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(loc.language),
                    subtitle: Text(
                      _getLanguageName(
                        Localizations.localeOf(context).languageCode,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showLanguageSelector,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // About Section
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(loc.about),
                    subtitle: Text(loc.version),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        loc.logout,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
