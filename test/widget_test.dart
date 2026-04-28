import 'package:flutter_test/flutter_test.dart';
import 'package:focuspal/models/mood.dart';

void main() {
  test('Mood state ordering is correct', () {
    expect(MoodState.ecstatic.index < MoodState.sad.index, isTrue);
    expect(MoodState.values.length, 6);
  });
}
