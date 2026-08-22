import '../models/app_preferences.dart';
import '../models/plan_item.dart';

abstract final class MentorMessageService {
  static String failureFor(
    PlanItem plan, {
    MentorIntensity intensity = MentorIntensity.spicy,
  }) {
    final spicyMessage = switch (plan.category) {
      PlanCategory.health =>
        '몸은 거짓말을 안 하는데 핑계는 참 부지런하네요. ‘${plan.title}’부터 다시 시작하세요.',
      PlanCategory.study => '계획표만 보면 이미 합격인데, 공부한 시간은 아직 체험판이네요.',
      PlanCategory.routine => '작심삼일도 사흘은 해야 붙는 이름이에요. 오늘부터 다시 세세요.',
      PlanCategory.record => '기록을 미루면 핑계만 남습니다. 다섯 줄 쓸 시간은 이미 있었어요.',
    };
    return switch (intensity) {
      MentorIntensity.mild => '‘${plan.title}’ 계획을 놓쳤어요. 다음 회차는 작게라도 바로 시작해요.',
      MentorIntensity.spicy => spicyMessage,
      MentorIntensity.extreme =>
        '$spicyMessage 이번에도 핑계만 남기면 그건 계획이 아니라 희망사항이에요.',
    };
  }

  static String successFor(PlanItem plan) {
    return switch (plan.category) {
      PlanCategory.health => '오늘은 핑계보다 몸이 먼저 움직였네요. 이 리듬을 기억하세요.',
      PlanCategory.study => '말 대신 공부한 시간이 남았습니다. 오늘은 제대로 했어요.',
      PlanCategory.routine => '작은 약속을 지키는 사람이 결국 오래 갑니다.',
      PlanCategory.record => '기록하는 사람은 같은 핑계에 두 번 속지 않아요.',
    };
  }
}
