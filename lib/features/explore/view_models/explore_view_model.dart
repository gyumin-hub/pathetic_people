import '../../../core/view_models/repository_view_model.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/explore_item.dart';

class ExploreViewModel extends RepositoryViewModel {
  ExploreViewModel(super.repository);

  static const categories = ['추천', '갓생', '실패담', '운동', '공부'];

  String _selectedCategory = categories.first;
  String _query = '';

  String get selectedCategory => _selectedCategory;
  String get query => _query;

  List<ExploreItem> get items {
    final normalizedQuery = _query.trim().toLowerCase();
    return repository.exploreItems
        .where((item) {
          final matchesCategory =
              _selectedCategory == '추천' ||
              (_selectedCategory == '갓생' && item.outcome.name == 'success') ||
              item.category == _selectedCategory;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              item.title.toLowerCase().contains(normalizedQuery) ||
              item.label.toLowerCase().contains(normalizedQuery) ||
              item.category.toLowerCase().contains(normalizedQuery);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false)
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
  }

  List<AppUser> get recommendedUsers {
    return repository.users
        .where((user) => user.id != repository.currentUser.id)
        .toList(growable: false);
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void search(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void toggleFollow(String userId) => repository.toggleFollow(userId);
}
