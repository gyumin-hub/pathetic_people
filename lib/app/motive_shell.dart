import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/chat/view_models/chat_view_model.dart';
import '../features/explore/presentation/explore_page.dart';
import '../features/explore/view_models/explore_view_model.dart';
import '../features/feed/presentation/feed_page.dart';
import '../features/feed/view_models/feed_view_model.dart';
import '../features/planner/presentation/planner_page.dart';
import '../features/planner/view_models/planner_view_model.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/view_models/profile_view_model.dart';

class MotiveShell extends StatefulWidget {
  const MotiveShell({
    required this.feedViewModel,
    required this.exploreViewModel,
    required this.plannerViewModel,
    required this.chatViewModel,
    required this.profileViewModel,
    required this.onLogout,
    super.key,
  });

  final FeedViewModel feedViewModel;
  final ExploreViewModel exploreViewModel;
  final PlannerViewModel plannerViewModel;
  final ChatViewModel chatViewModel;
  final ProfileViewModel profileViewModel;
  final Future<void> Function() onLogout;

  @override
  State<MotiveShell> createState() => _MotiveShellState();
}

class _MotiveShellState extends State<MotiveShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _deadlineTimer;

  List<Widget> get _pages => [
    FeedPage(
      viewModel: widget.feedViewModel,
      onOpenPlanner: () => setState(() => _selectedIndex = 2),
      onOpenProfile: () => setState(() => _selectedIndex = 4),
    ),
    ExplorePage(viewModel: widget.exploreViewModel),
    PlannerPage(viewModel: widget.plannerViewModel),
    ChatPage(viewModel: widget.chatViewModel),
    ProfilePage(
      viewModel: widget.profileViewModel,
      onOpenPlanner: () => setState(() => _selectedIndex = 2),
      onOpenExplore: () => setState(() => _selectedIndex = 1),
      onLogout: widget.onLogout,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.plannerViewModel.evaluateOverduePlans();
    });
    _deadlineTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) widget.plannerViewModel.evaluateOverduePlans();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.plannerViewModel.evaluateOverduePlans();
    }
  }

  @override
  void dispose() {
    _deadlineTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppPalette.line)),
        ),
        child: AnimatedBuilder(
          animation: widget.chatViewModel,
          builder: (context, _) {
            return NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                if (index == 2) {
                  widget.plannerViewModel.evaluateOverduePlans();
                }
                setState(() => _selectedIndex = index);
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: '피드',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  selectedIcon: Icon(Icons.manage_search_rounded),
                  label: '탐색',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: '계획',
                ),
                NavigationDestination(
                  icon: _ChatNavigationIcon(
                    unreadCount: widget.chatViewModel.totalUnread,
                    selected: false,
                  ),
                  selectedIcon: _ChatNavigationIcon(
                    unreadCount: widget.chatViewModel.totalUnread,
                    selected: true,
                  ),
                  label: '채팅',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: '프로필',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChatNavigationIcon extends StatelessWidget {
  const _ChatNavigationIcon({
    required this.unreadCount,
    required this.selected,
  });

  final int unreadCount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
    );
    if (unreadCount == 0) return icon;
    return Badge.count(
      count: unreadCount > 99 ? 99 : unreadCount,
      backgroundColor: AppPalette.red,
      child: icon,
    );
  }
}
