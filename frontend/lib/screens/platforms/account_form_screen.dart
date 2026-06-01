import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../providers/platform_provider.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final int? accountId;
  const AccountFormScreen({super.key, this.accountId});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  int? _selectedPlatformId;
  String? _selectedPlatformName;
  final _labelCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(platformProvider.notifier).createAccount({
      'platform_id': _selectedPlatformId,
      'account_label': _labelCtrl.text.trim(),
      'account_username': _usernameCtrl.text.trim(),
      'password': _passwordCtrl.text,
    });
    setState(() => _saving = false);
    if (ok && mounted) context.pop();
  }

  Future<void> _open12306() async {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'https://kyfw.12306.cn/otn/leftTicket/init',
          package: 'com.MobileTicket',
        );
        await intent.launch();
        return;
      } catch (_) {
        // App not installed, try website which may open in app
      }
    }
    // iOS: try URL scheme
    if (Platform.isIOS) {
      final appUri = Uri.parse('cn.12306.app://');
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    // Fallback to website
    final webUri = Uri.parse('https://kyfw.12306.cn/otn/leftTicket/init');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(platformProvider);
    final is12306 = _selectedPlatformName == 'train_12306' || _selectedPlatformName == '12306';

    return Scaffold(
      appBar: AppBar(title: const Text('添加平台账号')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('选择平台', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('请选择票务平台'),
              value: _selectedPlatformId,
              items: state.platforms.map((p) => DropdownMenuItem(
                value: p.id,
                child: Text(p.displayName),
                onTap: () => _selectedPlatformName = p.name,
              )).toList(),
              onChanged: (v) {
                setState(() => _selectedPlatformId = v);
                final plat = state.platforms.where((p) => p.id == v).firstOrNull;
                _selectedPlatformName = plat?.name;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(labelText: '账号标签（可选）', border: OutlineInputBorder(), hintText: '例如：我的12306账号'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: '12306账号/手机号', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: '12306密码', border: OutlineInputBorder()),
            ),
            if (is12306) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '请前往 12306 App 登录后绑定账号，若未安装将跳转官网',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _open12306,
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text('前往 12306 App 绑定', style: TextStyle(fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
