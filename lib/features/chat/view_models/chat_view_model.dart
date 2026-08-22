import '../../../core/view_models/repository_view_model.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/chat.dart';
import '../../../domain/models/plan_item.dart';

enum ChatFilter { all, direct, group }

class ChatViewModel extends RepositoryViewModel {
  ChatViewModel(super.repository);

  ChatFilter _filter = ChatFilter.all;
  String _query = '';

  ChatFilter get filter => _filter;

  List<ChatRoom> get rooms {
    final query = _query.trim().toLowerCase();
    return repository.chatRooms
        .where((room) {
          final matchesFilter = switch (_filter) {
            ChatFilter.all => true,
            ChatFilter.direct => room.kind == ChatRoomKind.direct,
            ChatFilter.group => room.kind == ChatRoomKind.group,
          };
          final matchesQuery =
              query.isEmpty ||
              room.title.toLowerCase().contains(query) ||
              room.subtitle.toLowerCase().contains(query);
          return matchesFilter && matchesQuery;
        })
        .toList(growable: false);
  }

  int get totalUnread {
    return repository.chatRooms.fold(0, (sum, room) => sum + room.unreadCount);
  }

  List<AppUser> get availableUsers {
    return repository.users
        .where((user) => user.id != repository.currentUser.id)
        .toList(growable: false);
  }

  List<PlanItem> get completedPlans {
    final plans = repository.plans
        .where((plan) => plan.progress == PlanProgress.completed)
        .toList();
    plans.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return plans;
  }

  void selectFilter(ChatFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void search(String value) {
    _query = value;
    notifyListeners();
  }

  List<ChatMessage> messagesFor(String roomId) {
    return repository.messagesForRoom(roomId);
  }

  void openRoom(String roomId) => repository.readRoom(roomId);

  void sendMessage(String roomId, String message) {
    repository.sendMessage(roomId, message);
  }

  ChatRoom createDirectRoom(String userId) {
    return repository.createDirectRoom(userId);
  }

  ChatRoom createGroupRoom(String title, List<String> userIds) {
    return repository.createGroupRoom(title, userIds);
  }
}
