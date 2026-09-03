import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/language_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          BlocBuilder<LanguageCubit, LanguageState>(
            builder: (context, langState) {
              return ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(AppConstants.languageNames[langState.languageCode] ?? langState.languageCode),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.language),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.contacts_outlined),
            title: const Text('Emergency Contacts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.emergencyContacts),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AuthCubit>().logout();
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
