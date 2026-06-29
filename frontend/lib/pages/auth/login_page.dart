import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/app_constants.dart';
import '../../provider/auth_provider.dart';
import '../../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MarketKy Shop',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '基于 MarketKy 商城模板改造的 Flutter Web 购物管理系统，支持买家、商家管理员和超级管理员。',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => auth.useDemoRole(AppRoles.buyer),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('买家演示'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                auth.useDemoRole(AppRoles.merchant),
                            icon: const Icon(
                              Icons.store_mall_directory_outlined,
                            ),
                            label: const Text('商家演示'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => auth.useDemoRole(AppRoles.admin),
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            label: const Text('超管演示'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '账号登录',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: '邮箱',
                              ),
                              validator: (value) =>
                                  value == null || !value.contains('@')
                                  ? '请输入有效邮箱'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: '密码',
                              ),
                              validator: (value) =>
                                  value == null || value.length < 6
                                  ? '密码至少 6 位'
                                  : null,
                            ),
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                auth.errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _login(context),
                                child: auth.isLoading
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('登录'),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.register),
                              child: const Text('没有账号？注册 / 商家入驻'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录失败，请确认后端服务和账号信息')));
    }
  }
}
