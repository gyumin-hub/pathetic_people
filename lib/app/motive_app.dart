import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/mock_app_repository.dart';
import '../features/chat/view_models/chat_view_model.dart';
import '../features/explore/view_models/explore_view_model.dart';
import '../features/feed/view_models/feed_view_model.dart';
import '../features/planner/view_models/planner_view_model.dart';
import '../features/profile/view_models/profile_view_model.dart';
import 'motive_shell.dart';

class MotiveApp extends StatefulWidget {
  const MotiveApp({super.key});

  @override
  State<MotiveApp> createState() => _MotiveAppState();
}

class _MotiveAppState extends State<MotiveApp> {
  late final MockAppRepository _repository;
  late final FeedViewModel _feedViewModel;
  late final ExploreViewModel _exploreViewModel;
  late final PlannerViewModel _plannerViewModel;
  late final ChatViewModel _chatViewModel;
  late final ProfileViewModel _profileViewModel;

  @override
  void initState() {
    super.initState();
    _repository = MockAppRepository();
    _feedViewModel = FeedViewModel(_repository);
    _exploreViewModel = ExploreViewModel(_repository);
    _plannerViewModel = PlannerViewModel(_repository);
    _chatViewModel = ChatViewModel(_repository);
    _profileViewModel = ProfileViewModel(_repository);
  }

  @override
  void dispose() {
    _feedViewModel.dispose();
    _exploreViewModel.dispose();
    _plannerViewModel.dispose();
    _chatViewModel.dispose();
    _profileViewModel.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'motive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MotiveShell(
        feedViewModel: _feedViewModel,
        exploreViewModel: _exploreViewModel,
        plannerViewModel: _plannerViewModel,
        chatViewModel: _chatViewModel,
        profileViewModel: _profileViewModel,
      ),
    );
  }
}
