import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/main.dart';

void main() {
  testWidgets('Ana ekran temel aksiyonlari gosterir', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SudokuApp());

    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Yeni Oyun'), findsOneWidget);
    expect(find.text('Çözülemeyenler'), findsOneWidget);
  });
}
