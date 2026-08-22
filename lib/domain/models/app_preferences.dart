enum MentorIntensity { mild, spicy, extreme }

class AppPreferences {
  const AppPreferences({
    required this.pushEnabled,
    required this.publicFailureEnabled,
    required this.systemChatAlertEnabled,
    required this.mentorIntensity,
  });

  final bool pushEnabled;
  final bool publicFailureEnabled;
  final bool systemChatAlertEnabled;
  final MentorIntensity mentorIntensity;

  AppPreferences copyWith({
    bool? pushEnabled,
    bool? publicFailureEnabled,
    bool? systemChatAlertEnabled,
    MentorIntensity? mentorIntensity,
  }) {
    return AppPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      publicFailureEnabled: publicFailureEnabled ?? this.publicFailureEnabled,
      systemChatAlertEnabled:
          systemChatAlertEnabled ?? this.systemChatAlertEnabled,
      mentorIntensity: mentorIntensity ?? this.mentorIntensity,
    );
  }
}
