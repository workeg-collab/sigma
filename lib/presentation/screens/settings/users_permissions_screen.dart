import 'package:flutter/material.dart';
import '../../../core/constants/permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/role_permission.dart';
import '../../../domain/models/user.dart';
import '../../widgets/financial_table.dart';

class UsersPermissionsScreen extends StatefulWidget {
  const UsersPermissionsScreen({super.key});

  @override
  State<UsersPermissionsScreen> createState() => _UsersPermissionsScreenState();
}

class _UsersPermissionsScreenState extends State<UsersPermissionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _userRepo = UserRepository();
  List<User> _users = [];
  List<Role> _roles = [];
  bool _isLoading = false;

  // Selected role for permissions matrix
  int _selectedRoleId = 1;
  List<String> _rolePermissions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await _userRepo.getAllUsers();
    final roles = await _userRepo.getAllRoles();
    final perms = await _userRepo.getPermissionsForRole(_selectedRoleId);

    setState(() {
      _users = users;
      _roles = roles;
      _rolePermissions = perms;
      _isLoading = false;
    });
  }

  Future<void> _selectRole(int roleId) async {
    setState(() => _selectedRoleId = roleId);
    final perms = await _userRepo.getPermissionsForRole(roleId);
    setState(() => _rolePermissions = perms);
  }

  void _openUserDialog([User? user]) {
    final usernameController = TextEditingController(text: user?.username ?? '');
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final pwdController = TextEditingController();
    int roleId = user?.roleId ?? 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(user == null ? 'إضافة مستخدم جديد' : 'تعديل المستخدم: ${user.username}'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    enabled: user == null,
                    decoration: const InputDecoration(labelText: 'اسم المستخدم (Login) *', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل *', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: roleId,
                    decoration: const InputDecoration(labelText: 'الدور والصلاحية', isDense: true),
                    items: _roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => roleId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pwdController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: user == null ? 'كلمة المرور *' : 'كلمة مرور جديدة (اتركه فارغاً للإبقاء)',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (usernameController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
                  if (user == null && pwdController.text.trim().isEmpty) return;

                  if (user == null) {
                    final u = User(
                      username: usernameController.text.trim(),
                      fullName: nameController.text.trim(),
                      email: emailController.text.trim(),
                      passwordHash: '',
                      roleId: roleId,
                    );
                    await _userRepo.createUser(u, pwdController.text.trim());
                  } else {
                    final u = User(
                      id: user.id,
                      username: user.username,
                      fullName: nameController.text.trim(),
                      email: emailController.text.trim(),
                      passwordHash: user.passwordHash,
                      roleId: roleId,
                      isActive: user.isActive,
                    );
                    await _userRepo.updateUser(u, newRawPassword: pwdController.text.trim().isNotEmpty ? pwdController.text.trim() : null);
                  }
                  Navigator.pop(ctx);
                  _loadData();
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userColumns = [
      FinancialTableColumn(title: 'اسم المستخدم', width: 140),
      FinancialTableColumn(title: 'الاسم الكامل', width: 220),
      FinancialTableColumn(title: 'البريد الإلكتروني', width: 200),
      FinancialTableColumn(title: 'الدور الوظيفي', width: 140),
      FinancialTableColumn(title: 'آخر تسجيل دخول', width: 160),
      FinancialTableColumn(title: 'الإجراءات', width: 100),
    ];

    final userRows = _users.map((u) {
      return [
        Text(u.username, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(u.email ?? '-'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(4)),
          child: Text(u.roleName ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
        ),
        Text(u.lastLoginAt != null ? u.lastLoginAt!.substring(0, 16).replaceAll('T', ' ') : '-'),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'تعديل',
          onPressed: () => _openUserDialog(u),
        ),
      ];
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'إدارة المستخدمين وحسابات الدخول'),
                    Tab(text: 'مصفوفة الصلاحيات والأدوار'),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openUserDialog(),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('إضافة مستخدم جديد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Users
                      FinancialTable(
                        columns: userColumns,
                        rows: userRows,
                        emptyMessage: 'لا يوجد مستخدمين مسجلين.',
                      ),

                      // Tab 2: Permissions Matrix
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Roles List
                          Container(
                            width: 220,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: ListView(
                              padding: const EdgeInsets.all(8),
                              children: _roles.map((r) {
                                final isSelected = r.id == _selectedRoleId;
                                return ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  tileColor: isSelected ? AppColors.primary.withAlpha(20) : null,
                                  title: Text(
                                    r.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                      color: isSelected ? AppColors.primaryLight : null,
                                    ),
                                  ),
                                  onTap: () => _selectRole(r.id!),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Granular Permissions Checklist
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'صلاحيات الدور: ${_roles.firstWhere((r) => r.id == _selectedRoleId, orElse: () => _roles.first).name}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView(
                                      children: AppPermissions.allPermissions.map((permKey) {
                                        final isGranted = _rolePermissions.contains(permKey);
                                        return CheckboxListTile(
                                          title: Text(AppPermissions.getPermissionLabelAr(permKey)),
                                          subtitle: Text(permKey, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                          value: isGranted,
                                          dense: true,
                                          onChanged: (val) async {
                                            List<String> updated = List.from(_rolePermissions);
                                            if (val == true) {
                                              updated.add(permKey);
                                            } else {
                                              updated.remove(permKey);
                                            }
                                            await _userRepo.updateRolePermissions(_selectedRoleId, updated);
                                            setState(() => _rolePermissions = updated);
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
