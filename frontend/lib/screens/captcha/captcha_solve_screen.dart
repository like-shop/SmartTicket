import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/task_provider.dart';

class CaptchaSolveScreen extends ConsumerStatefulWidget {
  const CaptchaSolveScreen({super.key});

  @override
  ConsumerState<CaptchaSolveScreen> createState() => _CaptchaSolveScreenState();
}

class _CaptchaSolveScreenState extends ConsumerState<CaptchaSolveScreen> {
  final _answerCtrl = TextEditingController();

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);
    final captcha = state.currentCaptcha;

    if (captcha == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('验证码')),
        body: const Center(child: Text('暂无验证码请求')),
      );
    }

    final imageBase64 = captcha['captcha_image_base64'] as String? ?? '';
    final captchaId = captcha['captcha_id'] as int? ?? 0;
    final taskId = captcha['task_id'] as int? ?? 0;
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(imageBase64);
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(title: const Text('验证码验证')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('请完成验证码验证', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (imageBytes != null)
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                child: Image.memory(imageBytes, height: 100, fit: BoxFit.contain),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _answerCtrl,
              decoration: const InputDecoration(labelText: '验证码答案', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final answer = _answerCtrl.text.trim();
                if (answer.isNotEmpty) {
                  ref.read(taskProvider.notifier).solveCaptcha(taskId, captchaId, answer);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text('提交验证', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
