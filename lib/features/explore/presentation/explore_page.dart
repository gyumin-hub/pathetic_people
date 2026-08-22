import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/section_header.dart';
import '../../../domain/models/app_user.dart';
import '../view_models/explore_view_model.dart';
import 'widgets/explore_detail_sheet.dart';
import 'widgets/explore_grid_tile.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({required this.viewModel, super.key});

  final ExploreViewModel viewModel;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.viewModel.query);
  }

  @override
  void didUpdateWidget(covariant ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel == widget.viewModel) return;
    _searchController.text = widget.viewModel.query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _searchController.clear();
    widget.viewModel
      ..search('')
      ..selectCategory(ExploreViewModel.categories.first);
  }

  List<AppUser> _visibleUsers() {
    final query = widget.viewModel.query.trim().toLowerCase();
    final normalizedQuery = query.startsWith('@') ? query.substring(1) : query;
    if (normalizedQuery.isEmpty) {
      return widget.viewModel.recommendedUsers.take(6).toList(growable: false);
    }
    return widget.viewModel.recommendedUsers
        .where((user) {
          return user.username.toLowerCase().contains(normalizedQuery) ||
              user.displayName.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final items = widget.viewModel.items;
            final users = _visibleUsers();
            final isSearching = widget.viewModel.query.trim().isNotEmpty;
            return CustomScrollView(
              key: const PageStorageKey<String>('explore-page'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: PageHeader(
                    eyebrow: 'DISCOVER',
                    title: '탐색',
                    trailing: IconButton(
                      onPressed: () => _showFilterGuide(context),
                      tooltip: '탐색 설정',
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 13),
                    child: TextField(
                      controller: _searchController,
                      onChanged: widget.viewModel.search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: '사용자, 계획, 기록, 태그 검색',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: widget.viewModel.query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  widget.viewModel.search('');
                                },
                                tooltip: '검색어 지우기',
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                ),
                if (users.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _RecommendedUsersSection(
                      users: users,
                      isSearching: isSearching,
                      onFollow: widget.viewModel.toggleFollow,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _CategoryBar(
                    categories: ExploreViewModel.categories,
                    selectedCategory: widget.viewModel.selectedCategory,
                    onSelected: widget.viewModel.selectCategory,
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyExplore(
                      hasUserResults: users.isNotEmpty,
                      onReset: _resetFilters,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 12),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                            childAspectRatio: 1,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ExploreGridTile(
                          key: ValueKey(item.id),
                          item: item,
                          onTap: () =>
                              showExploreDetailSheet(context, item: item),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFilterGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '탐색 기준',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  '관심 카테고리와 인기도를 함께 반영해 다양한 성공·실패 기록을 보여줘요.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetFilters();
                    },
                    child: const Text('필터 초기화'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecommendedUsersSection extends StatelessWidget {
  const _RecommendedUsersSection({
    required this.users,
    required this.isSearching,
    required this.onFollow,
  });

  final List<AppUser> users;
  final bool isSearching;
  final ValueChanged<String> onFollow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(title: isSearching ? '계정' : '추천 계정'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final user = users[index];
                return _RecommendedUserCard(
                  user: user,
                  onFollow: () => onFollow(user.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedUserCard extends StatelessWidget {
  const _RecommendedUserCard({required this.user, required this.onFollow});

  final AppUser user;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 272,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppPalette.background,
          border: Border.all(color: AppPalette.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              AppAvatar.user(user, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '@${user.username} · Lv.${user.level}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _FollowButton(isFollowing: user.isFollowing, onPressed: onFollow),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.isFollowing, required this.onPressed});

  final bool isFollowing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
    );
    return SizedBox(
      width: 68,
      height: 34,
      child: isFollowing
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.ink,
                padding: EdgeInsets.zero,
                side: const BorderSide(color: AppPalette.line),
                shape: shape,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('팔로잉'),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: shape,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('팔로우'),
            ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? AppPalette.ink : AppPalette.line,
            ),
            backgroundColor: AppPalette.background,
            selectedColor: AppPalette.ink,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppPalette.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyExplore extends StatelessWidget {
  const _EmptyExplore({required this.hasUserResults, required this.onReset});

  final bool hasUserResults;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppPalette.muted,
            ),
            const SizedBox(height: 14),
            Text(
              hasUserResults ? '일치하는 콘텐츠가 없어요' : '검색 결과가 없어요',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              hasUserResults
                  ? '위 계정을 확인하거나 콘텐츠 카테고리를 바꿔 보세요.'
                  : '다른 검색어를 입력하거나 카테고리를 바꿔 보세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            TextButton(onPressed: onReset, child: const Text('필터 초기화')),
          ],
        ),
      ),
    );
  }
}
