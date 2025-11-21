import 'dart:math';

class MockPredictor {
  final Random _random = Random();

  /// Generates a simulated multiplier prediction.
  /// The logic mimics the distribution of crash games:
  /// - High probability of low multipliers (1.00x - 2.00x)
  /// - Medium probability of medium multipliers (2.00x - 10.00x)
  /// - Low probability of high multipliers (10.00x +)
  double generatePrediction() {
    double chance = _random.nextDouble();
    
    if (chance < 0.50) {
      // 50% chance: 1.00x - 1.99x (Safe/Low)
      return 1.00 + _random.nextDouble(); 
    } else if (chance < 0.80) {
      // 30% chance: 2.00x - 5.00x (Medium)
      return 2.00 + (_random.nextDouble() * 3.0);
    } else if (chance < 0.95) {
      // 15% chance: 5.00x - 15.00x (High)
      return 5.00 + (_random.nextDouble() * 10.0);
    } else {
      // 5% chance: 15.00x - 100.00x (Jackpot)
      return 15.00 + (_random.nextDouble() * 85.0);
    }
  }

  /// Generates a fake "confidence" score for the prediction.
  /// Usually high to satisfy the user's request for "accuracy".
  double calculateConfidence() {
    // Returns a value between 0.85 and 0.99
    return 0.85 + (_random.nextDouble() * 0.14);
  }
}
