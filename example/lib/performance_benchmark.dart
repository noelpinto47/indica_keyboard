import 'package:flutter/material.dart';
import 'package:indica_keyboard/src/services/indica_native_service.dart';
import 'dart:developer' as developer;

/// Performance benchmark widget for testing native integration
class PerformanceBenchmark extends StatefulWidget {
  const PerformanceBenchmark({super.key});

  @override
  State<PerformanceBenchmark> createState() => _PerformanceBenchmarkState();
}

class _PerformanceBenchmarkState extends State<PerformanceBenchmark> {
  Map<String, dynamic>? _performanceMetrics;
  Map<String, dynamic>? _processingStats;
  bool _isRunning = false;
  final List<String> _benchmarkResults = [];

  @override
  void initState() {
    super.initState();
    _loadInitialStats();
  }

  Future<void> _loadInitialStats() async {
    try {
      final metrics = await IndicaNativeService.getAdvancedMetrics();
      final stats = IndicaNativeService.getProcessingStats();
      
      setState(() {
        _performanceMetrics = metrics;
        _processingStats = stats;
      });
    } catch (e) {
      developer.log('Error loading initial stats: $e', name: 'Benchmark');
    }
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _isRunning = true;
      _benchmarkResults.clear();
    });

    try {
      _benchmarkResults.add('🚀 Starting Performance Benchmark...\n');

      // Test 1: Single text processing
      final singleStart = DateTime.now();
      final testText = 'नमस्ते क्षत्रिय ज्ञान श्रुति';
      await IndicaNativeService.processText(text: testText, language: 'hi');
      final singleDuration = DateTime.now().difference(singleStart);
      
      _benchmarkResults.add('✅ Single Processing: ${singleDuration.inMicroseconds}μs');

      // Test 2: Batch processing
      final batchStart = DateTime.now();
      final batchTexts = List.generate(100, (i) => 'Test $i: क्षत्रिय ज्ञान श्रुति');
      await IndicaNativeService.batchProcessText(texts: batchTexts, language: 'hi');
      final batchDuration = DateTime.now().difference(batchStart);
      
      _benchmarkResults.add('✅ Batch Processing (100): ${batchDuration.inMilliseconds}ms');

      // Test 3: Cache warm-up
      final warmupStart = DateTime.now();
      await IndicaNativeService.warmUpCaches();
      final warmupDuration = DateTime.now().difference(warmupStart);
      
      _benchmarkResults.add('✅ Cache Warm-up: ${warmupDuration.inMilliseconds}ms');

      // Test 4: Performance metrics
      final metrics = await IndicaNativeService.getAdvancedMetrics();
      final stats = IndicaNativeService.getProcessingStats();
      
      _benchmarkResults.add('\n📊 Current Metrics:');
      _benchmarkResults.add('Platform: ${metrics['platform']}');
      _benchmarkResults.add('Optimization Score: ${metrics['optimizationScore']}/100');
      _benchmarkResults.add('Cache Hit Rate: ${metrics['cacheStatistics']['hitRate']}');
      _benchmarkResults.add('Native Usage: ${stats['nativePercentage']}%');

      setState(() {
        _performanceMetrics = metrics;
        _processingStats = stats;
      });

    } catch (e) {
      _benchmarkResults.add('❌ Error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Benchmark'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_performanceMetrics != null) ...[
                      Text('Platform: ${_performanceMetrics!['platform']}'),
                      Text('Native Support: ${_processingStats!['nativeSupported']}'),
                      Text('Processing Mode: ${_performanceMetrics!['processingMode']}'),
                      Text('Optimization Score: ${_performanceMetrics!['optimizationScore']}/100'),
                    ] else
                      const Text('Loading metrics...'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Benchmark Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _runBenchmark,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isRunning 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)),
                        SizedBox(width: 8),
                        Text('Running Benchmark...'),
                      ],
                    )
                  : const Text('Run Performance Benchmark', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            if (_benchmarkResults.isNotEmpty) ...[
              const Text('Benchmark Results:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _benchmarkResults.join('\n'),
                      style: const TextStyle(
                        color: Colors.green,
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}