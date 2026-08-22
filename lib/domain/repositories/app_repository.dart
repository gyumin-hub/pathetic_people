import 'package:flutter/foundation.dart';

import '../models/app_preferences.dart';
import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/explore_item.dart';
import '../models/feed_post.dart';
import '../models/plan_item.dart';

abstract interface class AppRepository implements Listenable {
  AppUser get currentUser;
  AppPreferences get preferences;
  List<AppUser> get users;
  List<FeedPost> get posts;
  List<ExploreItem> get exploreItems;
  List<PlanItem> get plans;
  List<ChatRoom> get chatRooms;

  AppUser? userById(String id);
  List<ChatMessage> messagesForRoom(String roomId);

  void togglePostLike(String postId);
  void togglePostSave(String postId);
  void addComment(String postId, String message);
  void toggleFollow(String userId);
  void updateCurrentUser({
    required String displayName,
    required String username,
    required String bio,
  });
  void updatePreferences({
    bool? pushEnabled,
    bool? publicFailureEnabled,
    bool? systemChatAlertEnabled,
    MentorIntensity? mentorIntensity,
  });

  void addPlan(PlanDraft draft);
  void updatePlan(String planId, PlanDraft draft);
  void deletePlan(String planId);
  void startPlan(String planId, PlanProofDraft proofDraft);
  void completePlan(String planId, PlanProofDraft proofDraft);
  void markOverduePlans(DateTime now);

  void readRoom(String roomId);
  void sendMessage(String roomId, String message);
  ChatRoom createDirectRoom(String userId);
  ChatRoom createGroupRoom(String title, List<String> userIds);

  void dispose();
}
