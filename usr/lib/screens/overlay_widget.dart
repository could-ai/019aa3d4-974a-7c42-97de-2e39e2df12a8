import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mock_predictor.dart';

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> with SingleTickerProviderStateMixin {
  final MockPredictor _predictor = MockPredictor();
  String _status = "WAITING";
  double _currentPrediction = 0.00;
  double _confidence = 0.0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _startSimulationLoop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startSimulationLoop() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _runPredictionCycle();
    });
    _runPredictionCycle();
  }

  Future<void> _runPredictionCycle() async {
    if (!mounted) return;

    setState(() {
      _status = "SYNC...";
      _currentPrediction = 0.00;
      _animationController.reverse();
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _status = "CALC...";
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final result = _predictor.generatePrediction();
    final confidence = _predictor.calculateConfidence();
    
    setState(() {
      _status = "NEXT";
      _currentPrediction = result;
      _confidence = confidence;
    });
    
    _animationController.forward();
  }

  Color _getMultiplierColor(double value) {
    if (value < 2.0) return Colors.blueAccent;
    if (value < 10.0) return Colors.purpleAccent;
    return const Color(0xFFE91E63);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE91E63), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _status == "NEXT" ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status == "NEXT" ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            ScaleTransition(
              scale: _scaleAnimation,
              child: _currentPrediction > 0
                  ? Column(
                      children: [
                        Text(
                          "${_currentPrediction.toStringAsFixed(2)}x",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: _getMultiplierColor(_currentPrediction),
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: _getMultiplierColor(_currentPrediction).withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${(_confidence * 100).toStringAsFixed(0)}% SAFE",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFE91E63),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
