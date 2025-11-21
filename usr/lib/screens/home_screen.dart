import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/mock_predictor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final MockPredictor _predictor = MockPredictor();
  String _status = "WAITING"; // WAITING, PREDICTING, RESULT
  double _currentPrediction = 0.00;
  double _confidence = 0.0;
  List<Map<String, dynamic>> _history = [];
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    // Start the simulation loop
    _startSimulationLoop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startSimulationLoop() {
    // Simulate the cycle of a round
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _runPredictionCycle();
    });
    // Run immediately for first time
    _runPredictionCycle();
  }

  Future<void> _runPredictionCycle() async {
    if (!mounted) return;

    // Phase 1: Waiting/Syncing
    setState(() {
      _status = "SYNCING DATA...";
      _currentPrediction = 0.00;
      _animationController.reverse();
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Phase 2: Predicting
    setState(() {
      _status = "CALCULATING...";
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Phase 3: Result
    final result = _predictor.generatePrediction();
    final confidence = _predictor.calculateConfidence();
    
    setState(() {
      _status = "NEXT ROUND PREDICTION";
      _currentPrediction = result;
      _confidence = confidence;
      _history.insert(0, {
        'multiplier': result,
        'time': DateTime.now(),
        'confidence': confidence,
      });
      if (_history.length > 10) _history.removeLast();
    });
    
    _animationController.forward();
  }

  Color _getMultiplierColor(double value) {
    if (value < 2.0) return Colors.blueAccent;
    if (value < 10.0) return Colors.purpleAccent;
    return const Color(0xFFE91E63); // Pink/Red for high
  }

  Future<void> _enableOverlay() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Overlay mode is only available on Android devices.")),
      );
      return;
    }

    if (Platform.isAndroid) {
      bool? status = await FlutterOverlayWindow.isPermissionGranted();
      if (status == false) {
        bool? granted = await FlutterOverlayWindow.requestPermission();
        if (granted != true) return;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Aviator Predictor",
        overlayContent: "Predicting...",
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.centerLeft,
        visibility: NotificationVisibility.visibilitySecret,
        positionGravity: PositionGravity.auto,
        height: 300,
        width: 300,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AVIATOR PREDICTOR AI"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            tooltip: "Floating Mode",
            onPressed: _enableOverlay,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: _status == "NEXT ROUND PREDICTION" 
                  ? Colors.green.withOpacity(0.2) 
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _status == "NEXT ROUND PREDICTION" 
                    ? Colors.green 
                    : Colors.orange,
                width: 1,
              ),
            ),
            child: Text(
              _status,
              style: TextStyle(
                color: _status == "NEXT ROUND PREDICTION" 
                    ? Colors.greenAccent 
                    : Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Main Prediction Display
          Expanded(
            flex: 2,
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentPrediction > 0) ...[
                      Text(
                        "${_currentPrediction.toStringAsFixed(2)}x",
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.w900,
                          color: _getMultiplierColor(_currentPrediction),
                          shadows: [
                            Shadow(
                              blurRadius: 20.0,
                              color: _getMultiplierColor(_currentPrediction).withOpacity(0.5),
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "CONFIDENCE: ${(_confidence * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ] else ...[
                      const CircularProgressIndicator(
                        color: Color(0xFFE91E63),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Analyzing patterns...",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // History Section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "RECENT PREDICTIONS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        Icon(Icons.history, color: Colors.white70),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final multiplier = item['multiplier'] as double;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getMultiplierColor(multiplier).withOpacity(0.2),
                            child: Icon(
                              Icons.trending_up,
                              color: _getMultiplierColor(multiplier),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            "${multiplier.toStringAsFixed(2)}x",
                            style: TextStyle(
                              color: _getMultiplierColor(multiplier),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            "Confidence: ${(item['confidence'] * 100).toStringAsFixed(1)}%",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          trailing: Text(
                            "${(item['time'] as DateTime).hour}:${(item['time'] as DateTime).minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(color: Colors.white38),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _timer?.cancel();
          _runPredictionCycle();
          _startSimulationLoop();
        },
        label: const Text("FORCE PREDICT"),
        icon: const Icon(Icons.radar),
        backgroundColor: const Color(0xFFE91E63),
      ),
    );
  }
}
