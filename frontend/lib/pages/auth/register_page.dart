import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _licenseNoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isMerchant = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _descriptionController.dispose();
    _licenseNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('账号注册')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.person_outline),
                          label: Text('买家注册'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.storefront_outlined),
                          label: Text('商家入驻'),
                        ),
                      ],
                      selected: {_isMerchant},
                      onSelectionChanged: (value) {
                        setState(() => _isMerchant = value.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '姓名'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? '请输入姓名'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: '邮箱'),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? '请输入有效邮箱'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '密码'),
                      validator: (value) =>
                          value == null || value.length < 8 ? '密码至少 8 位' : null,
                    ),
                    if (_isMerchant) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(labelText: '店铺名称'),
                        validator: _requiredWhenMerchant,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _licenseNoController,
                        decoration: const InputDecoration(
                          labelText: '营业执照/资质编号',
                        ),
                        validator: _requiredWhenMerchant,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: '店铺简介'),
                        maxLines: 3,
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => _register(context),
                        child: Text(_isMerchant ? '提交入驻申请并登录' : '注册并登录'),
                      ),
                    ),
                    if (_isMerchant) ...[
                      const SizedBox(height: 12),
                      Text(
                        '商家账号提交后需超级管理员审核，通过后重新登录即可进入商家后台。',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      if (_isMerchant) {
        await context.read<AuthProvider>().registerMerchant(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          shopName: _shopNameController.text.trim(),
          description: _descriptionController.text.trim(),
          licenseNo: _licenseNoController.text.trim(),
        );
      } else {
        await context.read<AuthProvider>().register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      final message =
          context.read<AuthProvider>().errorMessage ?? '注册失败，请检查后端服务';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String? _requiredWhenMerchant(String? value) {
    if (!_isMerchant) return null;
    return value == null || value.trim().isEmpty ? '必填' : null;
  }
}
