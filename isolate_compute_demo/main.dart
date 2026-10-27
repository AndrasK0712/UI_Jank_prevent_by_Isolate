import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// Số vòng lặp của tác vụ nặng. Tăng/giảm để phù hợp với thiết bị demo
/// (mục tiêu: chạy khoảng 2-5 giây).
const int kIterations = 200000000;

/// TÁC VỤ NẶNG.
/// Bắt buộc là hàm top-level (hoặc static) để `compute` có thể gửi sang Isolate khác.
double heavyComputation(int iterations) {
  double result = 0;
  for (int i = 1; i <= iterations; i++) {
    result += math.sqrt(i) * math.sin(i);
  }
  return result;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isolate & compute demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _isRunning = false;
  String _status = 'Sẵn sàng. Hãy bấm một nút và quan sát hiệu ứng xoay.';
  String _elapsed = '-';

  @override
  void initState() {
    super.initState();
    // Animation chạy liên tục để làm "thước đo" độ mượt của UI.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Nút 1: chạy trực tiếp trên Main Thread -> UI bị đơ.
  Future<void> _runOnMainThread() async {
    setState(() {
      _isRunning = true;
      _status = 'Đang chạy trên MAIN THREAD...';
    });
    // Chờ một khung hình để Flutter kịp vẽ dòng trạng thái ở trên
    // trước khi Main Thread bị chiếm dụng.
    await Future.delayed(const Duration(milliseconds: 100));

    final sw = Stopwatch()..start();
    final result = heavyComputation(kIterations); // CHẶN Main Thread
    sw.stop();

    _finish('Main Thread', result, sw.elapsed);
  }

  /// Nút 2: đẩy sang Isolate khác bằng compute -> UI vẫn mượt.
  Future<void> _runWithCompute() async {
    setState(() {
      _isRunning = true;
      _status = 'Đang chạy trên ISOLATE (compute)...';
    });

    final sw = Stopwatch()..start();
    final result = await compute(heavyComputation, kIterations);
    sw.stop();

    _finish('compute (Isolate)', result, sw.elapsed);
  }

  void _finish(String mode, double result, Duration elapsed) {
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _status = 'Xong [$mode]. Kết quả = ${result.toStringAsFixed(4)}';
      _elapsed = '${(elapsed.inMilliseconds / 1000).toStringAsFixed(2)} giây';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UI Jank vs Isolate (compute)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hiệu ứng 1: icon xoay liên tục (do AnimationController điều khiển).
            Center(
              child: RotationTransition(
                turns: _controller,
                child: const Icon(Icons.sync, size: 80, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 24),
            // Hiệu ứng 2: CircularProgressIndicator (indeterminate).
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 32),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Thời gian tính toán: $_elapsed',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isRunning ? null : _runOnMainThread,
              icon: const Icon(Icons.warning_amber),
              label: const Text('Nút 1: Chạy trên Main Thread (gây đơ)'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isRunning ? null : _runWithCompute,
              icon: const Icon(Icons.bolt),
              label: const Text('Nút 2: Chạy bằng compute (mượt)'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
