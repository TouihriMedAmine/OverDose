import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tunisia_product_search/main.dart';

void main() {
  testWidgets('App root builds', (WidgetTester tester) async {
    await tester.pumpWidget(const TunisiaProductApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    // First frame: loading or login
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
