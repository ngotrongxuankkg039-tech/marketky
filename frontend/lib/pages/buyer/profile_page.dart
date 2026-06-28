import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/section_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            title: '账号信息',
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(user?.name ?? ''),
              subtitle: Text(
                '${user?.email ?? ''} · ${user?.roles.join(', ') ?? ''}',
              ),
            ),
          ),
          SectionCard(
            title: '默认收货地址',
            trailing: TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.addresses),
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('管理'),
            ),
            child: const ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text('默认地址由后端读取'),
              subtitle: Text('下单时会自动使用默认收货地址'),
            ),
          ),
        ],
      ),
    );
  }
}
