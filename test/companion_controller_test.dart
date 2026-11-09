import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ai/companion/companion_controller.dart';
import 'package:nexus_ai/companion/companion_state.dart';

void main() {
  group('CompanionController', () {
    test('disposed controller ignores delayed and external reactions', () async {
      final controller = CompanionController();
      controller.tapCompanion();
      controller.dispose();
      controller.triggerMessageSentReaction();
      controller.triggerResponseStarted();
      controller.triggerResponseFinished();
      controller.tapCompanion();
      await Future<void>.delayed(const Duration(milliseconds: 1000));
    });

    test('loop profiles use whole cycles at the repeat boundary', () {
      for (final state in CompanionState.values) {
        final profile = CompanionBehaviorProfile.forState(state);
        expect(profile.hoverCycles, profile.hoverCycles.roundToDouble());
        expect(profile.haloSpeedMultiplier,
            profile.haloSpeedMultiplier.roundToDouble());
      }
    });

    test('starts in idle neutral state', () {
      final controller = CompanionController();
      addTearDown(controller.dispose);

      expect(controller.state, CompanionState.idle);
      expect(controller.mood, CompanionMood.neutral);
      expect(controller.gazeOffset, Offset.zero);
      expect(controller.interactionCount, 0);
    });

    test('clamps gaze coordinates within [-1, 1]', () {
      final controller = CompanionController();
      addTearDown(controller.dispose);

      controller.updateGaze(const Offset(3.5, -2.4));
      expect(controller.gazeOffset, const Offset(1.0, -1.0));

      controller.resetGaze();
      expect(controller.gazeOffset, Offset.zero);
    });

    test('transitions reacting -> thinking -> speaking -> waiting -> idle', () async {
      final controller = CompanionController();
      addTearDown(controller.dispose);

      controller.triggerMessageSentReaction();
      expect(controller.state, CompanionState.reacting);
      expect(controller.interactionCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(controller.state, CompanionState.thinking);

      controller.triggerResponseStarted();
      expect(controller.state, CompanionState.speaking);

      controller.triggerResponseFinished();
      expect(controller.state, CompanionState.waiting);

      await Future<void>.delayed(const Duration(milliseconds: 2700));
      expect(controller.state, CompanionState.idle);
    });
  });
}
