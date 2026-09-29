import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The artboard size of the design.
const phoneSize = Size(390, 844);

/// Sets the test view to the frame of the design.
///
/// The default test view is 800 by 600. A phone screen is taller and narrower,
/// so a list that fits the design scrolls out of view in the default frame.
/// Call this in `setUp` and call [resetPhoneFrame] in `tearDown`.
void usePhoneFrame(WidgetTester tester) {
  tester.view.physicalSize = phoneSize * 3;
  tester.view.devicePixelRatio = 3;
}

void resetPhoneFrame(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}
