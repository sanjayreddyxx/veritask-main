import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final taskService = TaskService();
    final authService = AuthService();
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: kPrimary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAdmin ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isAdmin ? kWarning.withAlpha(77) : kInfo.withAlpha(77)),
                    ),
                    child: Text(
                      isAdmin ? 'ADMINISTRATOR' : 'LEARNER',
                      style: TextStyle(
                        color: isAdmin ? kWarning : kInfo,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Stats Card
                  _buildStatsCard(isAdmin, taskService),
                  const SizedBox(height: 24),

                  // Account Settings
                  _buildSettingsHeader('Account Control'),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => _navigateToEditProfile(context),
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notification Hub',
                      onTap: () => _navigateToDetail(context, 'Notifications', Icons.notifications_active_rounded, 'Customize your administrative alerts for course enrollments and student submissions.'),
                    ),
                    if (isAdmin)
                      _SettingsTile(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Organization Details',
                        onTap: () => _navigateToDetail(context, 'Organization Settings', Icons.business_rounded, 'Configure institution-wide policies, branding, and teacher permissions.'),
                      ),
                  ]),
                  const SizedBox(height: 24),

                  _buildSettingsHeader('Support'),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help Center',
                      onTap: () => _navigateToDetail(context, 'Support Center', Icons.support_agent_rounded, 'Access documentation, video tutorials, and live community support.'),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'About Veritask AI',
                      onTap: () => _navigateToDetail(context, 'About App', Icons.info_rounded, 'LearnSphere AI v2.4.0 - Modernizing Education Management with AI.'),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      label: 'Terminate Session',
                      color: kDanger,
                      onTap: () async => await authService.signOut(),
                    ),
                  ]),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _AccountSettingsScreen(user: user!),
        ),
      );
    }
  }

  void _navigateToDetail(BuildContext context, String title, IconData icon, String desc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProfileDetailScreen(title: title, icon: icon, description: desc),
      ),
    );
  }

  Widget _buildSettingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isAdmin, TaskService taskService) {
    if (!isAdmin) {
      if (user == null) return const SizedBox.shrink();
      return FutureBuilder<Map<String, int>>(
        future: taskService.getUserTaskStats(user!.uid),
        builder: (ctx, snap) {
          final stats = snap.data ?? {};
          return _StatsContainer(title: 'Learning Progress', children: [
            _StatItem('Total', stats['total']?.toString() ?? '0', kPrimary),
            _StatItem('Done', stats['verified']?.toString() ?? '0', kSuccess),
            _StatItem('Wait', stats['submitted']?.toString() ?? '0', kInfo),
          ]);
        },
      );
    }

    // For Admin: Show Review Stats
    return StreamBuilder<List<TaskModel>>(
      stream: taskService.getReviewableTasks(),
      builder: (ctx, snap) {
        final pending = snap.data?.length ?? 0;
        return _StatsContainer(title: 'Management Metrics', children: [
          _StatItem('To Review', pending.toString(), kWarning),
          _StatItem('Active Courses', 'Registry', kPrimary),
          _StatItem('Platform', 'Live', kSuccess),
        ]);
      },
    );
  }
}

class _StatsContainer extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _StatsContainer({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          Row(children: children),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF374151);
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title:
          Text(label, style: TextStyle(fontSize: 14, color: c)),
      trailing: color == null
          ? const Icon(Icons.chevron_right,
              color: Color(0xFFCBD5E1))
          : null,
      onTap: onTap,
    );
  }
}

class _ProfileDetailScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _ProfileDetailScreen({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withAlpha(26),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.construction_rounded, size: 18, color: Color(0xFF475569)),
                    SizedBox(width: 8),
                    Text(
                      'SECTION UNDER OPTIMIZATION',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSettingsScreen extends StatefulWidget {
  final UserModel user;
  const _AccountSettingsScreen({required this.user});

  @override
  State<_AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<_AccountSettingsScreen> {
  late TextEditingController _nameCtrl;
  final _passCtrl = TextEditingController();
  bool _loading = false;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
  }

  Future<void> _update() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    
    setState(() => _loading = true);
    try {
      if (_nameCtrl.text.trim() != widget.user.name) {
        await _auth.updateProfileName(widget.user.uid, _nameCtrl.text.trim());
      }
      if (_passCtrl.text.trim().isNotEmpty) {
        if (_passCtrl.text.trim().length < 6) {
           throw 'Password must be at least 6 characters';
        }
        await _auth.updateAccountPassword(_passCtrl.text.trim());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: kSuccess),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: kDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Account Settings'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: widget.user.email),
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email Address (Read-only)',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Leave empty to keep current',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 40),
            PremiumButton(
              onPressed: _update,
              label: 'Save Profile Changes',
              icon: Icons.save_rounded,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
