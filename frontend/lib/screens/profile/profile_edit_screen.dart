import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;
  const ProfileEditScreen({super.key, required this.userData});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;
  String? _avatarColor;

  static const _avatarColors = [
    'E53935', 'D81B60', '8E24AA', '5E35B1', '3949AB', '1E88E5',
    '00ACC1', '00897B', '43A047', 'FF8F00', 'F4511E', '6D4C41',
  ];

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.userData['nickname'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.userData['phone'] ?? '');
    _avatarColor = widget.userData['avatar'] as String?;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _initials() {
    final name = _nicknameCtrl.text;
    if (name.isEmpty) return '?';
    return name.characters.take(2).toString();
  }

  Color _avatarBg() {
    if (_avatarColor != null && _avatarColor!.isNotEmpty) {
      final hex = _avatarColor!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }
    final hash = _nicknameCtrl.text.hashCode.abs();
    final h = _avatarColors[hash % _avatarColors.length];
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      await dio.put('/api/v1/auth/me', data: {
        'nickname': _nicknameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'avatar': _avatarColor ?? '',
      });
      if (mounted) {
        ref.read(authProvider.notifier).onProfileUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('资料已更新'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编辑个人资料')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: _avatarBg(),
                    child: Text(
                      _initials(),
                      style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      radius: 16, backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 16, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('选择头像颜色', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8, runSpacing: 8,
              children: _avatarColors.map((hex) {
                final color = Color(int.parse('FF$hex', radix: 16));
                final selected = _avatarColor == '#$hex';
                return GestureDetector(
                  onTap: () => setState(() => _avatarColor = '#$hex'),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: selected ? Border.all(color: Colors.white, width: 2) : null,
                      boxShadow: selected
                          ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                          : null,
                    ),
                    child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nicknameCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: '昵称', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '手机号', prefixIcon: Icon(Icons.phone_android), border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('保存', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
