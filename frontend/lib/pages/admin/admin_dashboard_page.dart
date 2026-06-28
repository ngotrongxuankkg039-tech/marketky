import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/admin_provider.dart';
import '../../provider/auth_provider.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_tile.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminProvider>().loadDashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('超级管理员后台'),
          actions: [
            IconButton(
              tooltip: '刷新',
              onPressed: () => context.read<AdminProvider>().loadDashboard(),
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: '退出登录',
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: '总览'),
              Tab(icon: Icon(Icons.people_alt_outlined), text: '用户'),
              Tab(icon: Icon(Icons.verified_user_outlined), text: '商家审核'),
              Tab(icon: Icon(Icons.category_outlined), text: '分类权限'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(stats: admin.stats),
            _UsersTab(users: admin.users),
            _MerchantAuditTab(applications: admin.merchantApplications),
            const _CategoryRoleTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        StatTile(
          label: '用户数',
          value: '${stats['users'] ?? 0}',
          icon: Icons.people_alt_outlined,
        ),
        StatTile(
          label: '店铺数',
          value: '${stats['shops'] ?? 0}',
          icon: Icons.storefront_outlined,
        ),
        StatTile(
          label: '订单数',
          value: '${stats['orders'] ?? 0}',
          icon: Icons.receipt_long_outlined,
        ),
        StatTile(
          label: '交易额',
          value: '¥${stats['sales'] ?? 0}',
          icon: Icons.payments_outlined,
        ),
      ],
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.users});

  final List<Map<String, dynamic>> users;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          title: '用户管理',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('姓名')),
                DataColumn(label: Text('邮箱')),
                DataColumn(label: Text('状态')),
                DataColumn(label: Text('操作')),
              ],
              rows: [
                for (final user in users)
                  DataRow(
                    cells: [
                      DataCell(Text('${user['id']}')),
                      DataCell(Text('${user['name']}')),
                      DataCell(Text('${user['email']}')),
                      DataCell(Text('${user['status']}')),
                      DataCell(
                        IconButton(
                          tooltip: '禁用/启用',
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '调用 PUT /admin/users/{id}/status',
                                  ),
                                ),
                              ),
                          icon: const Icon(Icons.block_outlined),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MerchantAuditTab extends StatelessWidget {
  const _MerchantAuditTab({required this.applications});

  final List<Map<String, dynamic>> applications;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          title: '商家入驻审核',
          child: Column(
            children: [
              for (final application in applications)
                ListTile(
                  leading: const Icon(Icons.store_mall_directory_outlined),
                  title: Text(
                    '${application['shopName'] ?? application['shop_name']}',
                  ),
                  subtitle: Text(
                    '申请人：${application['ownerName'] ?? application['owner_name']} · ${application['status']}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () =>
                            _audit(context, application['id'] as int, true),
                        child: const Text('通过'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            _audit(context, application['id'] as int, false),
                        child: const Text('驳回'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _audit(BuildContext context, int id, bool approved) async {
    try {
      await context.read<AdminProvider>().auditMerchant(id, approved);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('审核接口暂不可用，请启动后端服务')));
    }
  }
}

class _CategoryRoleTab extends StatelessWidget {
  const _CategoryRoleTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SectionCard(
          title: '商品分类管理',
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.category_outlined),
                title: Text('数码'),
                subtitle: Text('允许商家维护电子类商品'),
              ),
              ListTile(
                leading: Icon(Icons.category_outlined),
                title: Text('家居'),
                subtitle: Text('可编辑名称、排序、启停状态'),
              ),
            ],
          ),
        ),
        SectionCard(
          title: '系统权限控制',
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.security_outlined),
                title: Text('BUYER'),
                subtitle: Text('浏览、购物车、下单、评价'),
              ),
              ListTile(
                leading: Icon(Icons.security_outlined),
                title: Text('MERCHANT_ADMIN'),
                subtitle: Text('维护店铺、商品和订单'),
              ),
              ListTile(
                leading: Icon(Icons.security_outlined),
                title: Text('SUPER_ADMIN'),
                subtitle: Text('用户、商家、分类和权限管理'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
