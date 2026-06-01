import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/platform_provider.dart';

class PlatformListScreen extends ConsumerWidget {
  const PlatformListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(platformProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('平台账号管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/platforms/add'),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.accounts.isEmpty
              ? const Center(child: Text('暂无绑定账号，点击右下角添加'))
              : ListView.builder(
                  itemCount: state.accounts.length,
                  itemBuilder: (ctx, i) {
                    final account = state.accounts[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text((account.platform?.displayName ?? '?')[0])),
                      title: Text(account.accountLabel.isNotEmpty ? account.accountLabel : account.accountUsername),
                      subtitle: Text(account.platform?.displayName ?? ''),
                      trailing: account.isVerified
                          ? const Icon(Icons.verified, color: Colors.green, size: 20)
                          : const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      onTap: () => context.push('/platforms/${account.id}/edit'),
                    );
                  },
                ),
    );
  }
}
