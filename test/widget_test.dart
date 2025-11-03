// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:traverse_flutter/utils/icon_standards.dart';

void main() {
  testWidgets('Icon standards work correctly', (WidgetTester tester) async {
  // Test that IconStandards.getUIIcon returns an IconData for known and unknown keys
  expect(IconStandards.getUIIcon('video'), isA<IconData>());
  expect(IconStandards.getUIIcon('group'), isA<IconData>());
  expect(IconStandards.getUIIcon('chart'), isA<IconData>());
  expect(IconStandards.getUIIcon('planning'), isA<IconData>());
  expect(IconStandards.getUIIcon('travel_planning'), isA<IconData>());
  expect(IconStandards.getUIIcon('account_balance_wallet'), isA<IconData>());
  expect(IconStandards.getUIIcon('camera'), isA<IconData>());

  // Unknown icons should still return an IconData (fallback)
  expect(IconStandards.getUIIcon('unknown_icon'), isA<IconData>());
  });
}
