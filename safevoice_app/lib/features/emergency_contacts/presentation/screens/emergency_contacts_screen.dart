import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/constants.dart';
import '../bloc/emergency_contact_cubit.dart';
import '../bloc/emergency_contact_state.dart';

/// Manage up to 5 emergency contacts. Implements Req 6.5.
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EmergencyContactCubit>().loadContacts();
  }

  void _showAddDialog(BuildContext context) {
    final cubitState = context.read<EmergencyContactCubit>().state;
    if (cubitState is EmergencyContactLoaded &&
        cubitState.contacts.length >= AppConstants.maxEmergencyContacts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Maximum 5 emergency contacts allowed')),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isNotEmpty && phone.isNotEmpty) {
                context
                    .read<EmergencyContactCubit>()
                    .addContact(name: name, phoneNumber: phone);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<EmergencyContactCubit, EmergencyContactState>(
        listener: (context, state) {
          if (state is EmergencyContactError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is EmergencyContactLoading ||
              state is EmergencyContactInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EmergencyContactLoaded) {
            if (state.contacts.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No emergency contacts added',
                        style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(
                      'Add up to 5 people who will be\nnotified when you trigger SOS',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.contacts.length,
              itemBuilder: (ctx, i) {
                final c = state.contacts[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(c.name),
                  subtitle: Text(c.phoneNumber),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => context
                        .read<EmergencyContactCubit>()
                        .deleteContact(c.id),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
