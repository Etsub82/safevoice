import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/constants.dart';
import '../bloc/language_cubit.dart';

/// Allows user to change the app language at any time. Implements Req 9.2.
class LanguageSelectorScreen extends StatelessWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Language')),
      body: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, state) {
          return ListView(
            children: AppConstants.supportedLanguageCodes.map((code) {
              final name = AppConstants.languageNames[code] ?? code;
              final isSelected = state.languageCode == code;
              return ListTile(
                leading: isSelected
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : const Icon(Icons.radio_button_unchecked),
                title: Text(name),
                onTap: () => context.read<LanguageCubit>().changeLanguage(code),
                selected: isSelected,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
