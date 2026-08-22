import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/app/app_content_session.dart';
import 'package:pathetic_people/data/repositories/mock_app_repository.dart';
import 'package:pathetic_people/features/auth/domain/auth_user.dart';

void main() {
  test('authenticated user data is applied only to the matching session', () {
    final repository = _TrackingMockAppRepository();
    final session = AppContentSession(userId: 7, repository: repository);

    session.syncAuthenticatedUser(
      const AuthUser(
        id: 7,
        email: 'a@example.com',
        nickname: '사용자 A',
        profileImage: null,
        role: 'USER',
      ),
    );
    expect(repository.currentUser.displayName, '사용자 A');

    session.syncAuthenticatedUser(
      const AuthUser(
        id: 8,
        email: 'b@example.com',
        nickname: '사용자 B',
        profileImage: null,
        role: 'USER',
      ),
    );
    expect(repository.currentUser.displayName, '사용자 A');
  });

  test('dispose releases every content view model and repository once', () {
    final repository = _TrackingMockAppRepository();
    final session = AppContentSession(userId: 7, repository: repository);
    final viewModels = <ChangeNotifier>[
      session.feedViewModel,
      session.exploreViewModel,
      session.plannerViewModel,
      session.chatViewModel,
      session.profileViewModel,
    ];

    session.dispose();
    session.dispose();

    expect(session.isDisposed, isTrue);
    expect(repository.disposeCount, 1);
    for (final viewModel in viewModels) {
      expect(() => viewModel.addListener(_emptyListener), throwsFlutterError);
    }
  });
}

void _emptyListener() {}

class _TrackingMockAppRepository extends MockAppRepository {
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount += 1;
    super.dispose();
  }
}
