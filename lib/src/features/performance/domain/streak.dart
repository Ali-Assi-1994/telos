import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak.freezed.dart';
part 'streak.g.dart';

@freezed
abstract class Streak with _$Streak {
  const factory Streak({
    required int currentStreak,
    required int longestStreak,
  }) = _Streak;

  factory Streak.fromJson(Map<String, dynamic> json) => _$StreakFromJson(json);
}
