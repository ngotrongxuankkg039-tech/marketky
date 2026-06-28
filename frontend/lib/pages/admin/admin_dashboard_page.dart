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
            _CategoryRoleTab(categories: admin.categories),
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
                          tooltip: user['status'] == 'ACTIVE' ? '禁用' : '启用',
                          onPressed: () {
                            final nextStatus = user['status'] == 'ACTIVE'
                                ? 'DISABLED'
                                : 'ACTIVE';
                            _runAdminAction(
                              context,
                              () => context
                                  .read<AdminProvider>()
                                  .updateUserStatus(
                                    int.parse(user['id'].toString()),
                                    nextStatus,
                                  ),
                              success: nextStatus == 'ACTIVE'
                                  ? '用户已启用'
                                  : '用户已禁用',
                            );
                          },
                          icon: Icon(
                            user['status'] == 'ACTIVE'
                                ? Icons.block_outlined
                                : Icons.check_circle_outline,
                          ),
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
                        onPressed: application['status'] == 'PENDING'
                            ? () => _audit(
                                context,
                                int.parse(application['id'].toString()),
                                true,
                              )
                            : null,
                        child: const Text('通过'),
                      ),
                      FilledButton.tonal(
                        onPressed: application['status'] == 'PENDING'
                            ? () => _audit(
                                context,
                                int.parse(application['id'].toString()),
                                false,
                              )
                            : null,
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
  const _CategoryRoleTab({required this.categories});

  final List<Map<String, dynamic>> categories;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          title: '商品分类管理',
          trailing: FilledButton.icon(
            onPressed: () => _showCategoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('新增分类'),
          ),
          child: categories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无分类')),
                )
              : Column(
                  children: [
                    for (final category in categories)
                      ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: Text(category['name']?.toString() ?? ''),
                        subtitle: Text(
                          '排序 ${category['sortOrder'] ?? category['sort_order'] ?? 0} · ${_categoryStatusText(category['status']?.toString() ?? '')}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: '编辑',
                              onPressed: () => _showCategoryDialog(
                                context,
                                category: category,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: category['status'] == 'ENABLED'
                                  ? '禁用'
                                  : '启用',
                              onPressed: () {
                                final nextStatus =
                                    category['status'] == 'ENABLED'
                                    ? 'DISABLED'
                                    : 'ENABLED';
                                _runAdminAction(
                                  context,
                                  () => context
                                      .read<AdminProvider>()
                                      .saveCategory(
                                        id: int.parse(
                                          category['id'].toString(),
                                        ),
                                        parentId: _optionalInt(
                                          category['parentId'],
                                        ),
                                        name:
                                            category['name']?.toString() ?? '',
                                        sortOrder:
                                            int.tryParse(
                                              (category['sortOrder'] ??
                                                      category['sort_order'] ??
                                                      0)
                                                  .toString(),
                                            ) ??
                                            0,
                                        status: nextStatus,
                                      ),
                                  success: nextStatus == 'ENABLED'
                                      ? '分类已启用'
                                      : '分类已禁用',
                                );
                              },
                              icon: Icon(
                                category['status'] == 'ENABLED'
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SectionCard(
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

  Future<void> _showCategoryDialog(
    BuildContext context, {
    Map<String, dynamic>? category,
  }) async {
    final nameController = TextEditingController(
      text: category?['name']?.toString() ?? '',
    );
    final sortController = TextEditingController(
      text: (category?['sortOrder'] ?? category?['sort_order'] ?? 0).toString(),
    );
    var status = category?['status']?.toString() ?? 'ENABLED';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? '新增分类' : '编辑分类'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '分类名称'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sortController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '排序值'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ENABLED', label: Text('启用')),
                    ButtonSegment(value: 'DISABLED', label: Text('禁用')),
                  ],
                  selected: {status},
                  onSelectionChanged: (value) =>
                      setState(() => status = value.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    final name = nameController.text.trim();
    final sortOrder = int.tryParse(sortController.text) ?? 0;
    nameController.dispose();
    sortController.dispose();
    if (saved != true || name.isEmpty || !context.mounted) return;
    await _runAdminAction(
      context,
      () => context.read<AdminProvider>().saveCategory(
        id: category == null ? null : int.parse(category['id'].toString()),
        parentId: _optionalInt(category?['parentId']),
        name: name,
        sortOrder: sortOrder,
        status: status,
      ),
      success: category == null ? '分类已新增' : '分类已保存',
    );
  }
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

String _categoryStatusText(String status) {
  return switch (status) {
    'ENABLED' => '已启用',
    'DISABLED' => '已禁用',
    _ => status,
  };
}

Future<void> _runAdminAction(
  BuildContext context,
  Future<void> Function() action, {
  required String success,
}) async {
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success)));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
