import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  late StreamSubscription<StepCount> _stepCountStream;
  int _initialStepCount = 0;
  int _currentStepCount = 0;

  /// Request permission to access step count
  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  /// Start listening to step count
  /// Returns a stream of step count values
  Stream<int> getStepCountStream() async* {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        yield 0;
        return;
      }

      _stepCountStream = Pedometer.stepCountStream.listen((StepCount event) {
        _currentStepCount = event.steps;
        if (_initialStepCount == 0) {
          _initialStepCount = event.steps;
        }
      });

      // Emit initial value
      yield 0;

      // Continue emitting values through a periodic check
      int lastEmitted = 0;
      while (true) {
        final stepsDuringTrip = _currentStepCount - _initialStepCount;
        final stepsToEmit = stepsDuringTrip > 0 ? stepsDuringTrip : 0;

        if (stepsToEmit != lastEmitted) {
          yield stepsToEmit;
          lastEmitted = stepsToEmit;
        }

        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      // Error accessing pedometer - yield 0
      yield 0;
    }
  }

  /// Get current step count for the active trip
  int getCurrentSteps() {
    final stepsDuringTrip = _currentStepCount - _initialStepCount;
    return stepsDuringTrip > 0 ? stepsDuringTrip : 0;
  }

  /// Reset the step counter (call when starting a new trip)
  void resetStepCounter() {
    _initialStepCount = _currentStepCount;
  }

  /// Stop listening to step count
  void stopListening() {
    _stepCountStream.cancel();
  }
}
