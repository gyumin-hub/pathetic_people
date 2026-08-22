import 'package:flutter/foundation.dart';

import '../../domain/repositories/app_repository.dart';

abstract class RepositoryViewModel extends ChangeNotifier {
  RepositoryViewModel(this.repository) {
    repository.addListener(_onRepositoryChanged);
  }

  @protected
  final AppRepository repository;

  void _onRepositoryChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
