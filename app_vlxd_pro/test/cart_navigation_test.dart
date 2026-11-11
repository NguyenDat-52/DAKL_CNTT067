import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_vlxd_pro/viewmodels/auth_viewmodel.dart';
import 'package:app_vlxd_pro/viewmodels/cart_viewmodel.dart';
import 'package:app_vlxd_pro/viewmodels/order_viewmodel.dart';
import 'package:app_vlxd_pro/viewmodels/product_viewmodel.dart';
import 'package:app_vlxd_pro/views/cart_screen.dart';
import 'package:app_vlxd_pro/views/main_navigation_screen.dart';

Widget _wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ChangeNotifierProvider(create: (_) => ProductViewModel()),
      ChangeNotifierProvider(create: (_) => CartViewModel()),
      ChangeNotifierProvider(create: (_) => OrderViewModel()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Empty Cart Navigation Tests', () {
    testWidgets(
      'Triggers onNavigateToHome callback when tapped in CartScreen',
      (WidgetTester tester) async {
        var navigatedHome = false;

        await tester.pumpWidget(
          _wrapWithProviders(
            CartScreen(
              onNavigateToHome: () {
                navigatedHome = true;
              },
            ),
          ),
        );
        await tester.pump();

        final exploreButton = find.widgetWithText(
          ElevatedButton,
          'KHÁM PHÁ VẬT LIỆU NGAY',
        );
        expect(exploreButton, findsOneWidget);

        await tester.tap(exploreButton);
        await tester.pump();

        expect(navigatedHome, isTrue);
      },
    );

    testWidgets(
      'Switches BottomNavigationBar index from Cart (3) to Home (0) in MainNavigationScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapWithProviders(const MainNavigationScreen(initialIndex: 3)),
        );
        await tester.pump();

        final navBarBefore = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBarBefore.currentIndex, equals(3));

        final exploreButton = find.widgetWithText(
          ElevatedButton,
          'KHÁM PHÁ VẬT LIỆU NGAY',
        );
        expect(exploreButton, findsOneWidget);

        await tester.tap(exploreButton);
        await tester.pumpAndSettle();

        final navBarAfter = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBarAfter.currentIndex, equals(0));
      },
    );

    testWidgets(
      'Pops pushed CartScreen and switches underlying MainNavigationScreen tab to Home (0)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapWithProviders(const MainNavigationScreen(initialIndex: 1)),
        );
        await tester.pump();

        // Push CartScreen on top of MainNavigationScreen while on tab 1
        final rootScaffoldContext = tester.element(find.byType(Scaffold).first);
        Navigator.of(rootScaffoldContext).push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
        await tester.pumpAndSettle();

        final exploreButton = find.widgetWithText(
          ElevatedButton,
          'KHÁM PHÁ VẬT LIỆU NGAY',
        );
        expect(exploreButton, findsOneWidget);

        await tester.tap(exploreButton);
        await tester.pumpAndSettle();

        // Should pop back to MainNavigationScreen and select tab 0 (Home)
        final navBarAfter = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBarAfter.currentIndex, equals(0));
      },
    );
  });
}
