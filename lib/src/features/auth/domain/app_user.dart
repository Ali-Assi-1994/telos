import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// The authenticated user, decoupled from any Supabase SDK type.
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    String? email,
    String? fullName,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
