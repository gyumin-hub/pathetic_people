abstract final class AppDateUtils {
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  static bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static String hourMinute(DateTime dateTime) {
    final period = dateTime.hour < 12 ? '오전' : '오후';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  static String monthTitle(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월';
  }

  static String fullDate(DateTime dateTime) {
    return '${dateTime.month}월 ${dateTime.day}일 ${_weekdays[dateTime.weekday - 1]}요일';
  }

  static String relativeTime(DateTime dateTime, {DateTime? now}) {
    final difference = (now ?? DateTime.now()).difference(dateTime);
    if (difference.inMinutes < 1) return '방금';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays == 1) return '어제';
    return '${dateTime.month}월 ${dateTime.day}일';
  }

  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
