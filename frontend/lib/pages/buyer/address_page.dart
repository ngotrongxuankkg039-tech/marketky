import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/address.dart';
import '../../provider/address_provider.dart';
import '../../widgets/section_card.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AddressProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('收货地址')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressDialog(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('新增地址'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionCard(
                  title: '地址管理',
                  child: provider.addresses.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('暂无收货地址')),
                        )
                      : Column(
                          children: [
                            for (final address in provider.addresses)
                              ListTile(
                                leading: Icon(
                                  address.isDefault
                                      ? Icons.location_on
                                      : Icons.location_on_outlined,
                                ),
                                title: Text(
                                  '${address.receiver} ${address.phone}',
                                ),
                                subtitle: Text(address.fullText),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      tooltip: '编辑',
                                      onPressed: () => _showAddressDialog(
                                        context,
                                        address: address,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: '删除',
                                      onPressed: () => _runAddressAction(
                                        context,
                                        () => context
                                            .read<AddressProvider>()
                                            .delete(address),
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _showAddressDialog(
    BuildContext context, {
    Address? address,
  }) async {
    final formKey = GlobalKey<FormState>();
    final receiver = TextEditingController(text: address?.receiver ?? '');
    final phone = TextEditingController(text: address?.phone ?? '');
    final province = TextEditingController(text: address?.province ?? '');
    final city = TextEditingController(text: address?.city ?? '');
    final detail = TextEditingController(text: address?.detail ?? '');
    var isDefault = address?.isDefault ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(address == null ? '新增地址' : '编辑地址'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: receiver,
                      decoration: const InputDecoration(labelText: '收货人'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: '电话'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: province,
                      decoration: const InputDecoration(labelText: '省份'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: city,
                      decoration: const InputDecoration(labelText: '城市'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: detail,
                      decoration: const InputDecoration(labelText: '详细地址'),
                      validator: _required,
                    ),
                    CheckboxListTile(
                      value: isDefault,
                      onChanged: (value) =>
                          setState(() => isDefault = value ?? false),
                      title: const Text('设为默认地址'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      await _runAddressAction(
        context,
        () => context.read<AddressProvider>().save(
          address: address,
          receiver: receiver.text.trim(),
          phone: phone.text.trim(),
          province: province.text.trim(),
          city: city.text.trim(),
          detail: detail.text.trim(),
          isDefault: isDefault,
        ),
      );
    }

    receiver.dispose();
    phone.dispose();
    province.dispose();
    city.dispose();
    detail.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? '必填' : null;

  Future<void> _runAddressAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('地址已保存')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
