import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';
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
          const SectionCard(
            title: '默认收货地址',
            child: ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text('张三 13800000000'),
              subtitle: Text('北京市海淀区 学院路 1 号'),
            ),
          ),
        ],
      ),
    );
  }
}
