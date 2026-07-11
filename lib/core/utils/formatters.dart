/// Formatting helpers for prices and course durations.
class Formatters {
  /// Formats a whole-rupee amount with Indian digit grouping, e.g.
  /// 2499 -> "2,499", 100000 -> "1,00,000".
  static String rupees(num amount) {
    final n = amount.round();
    final s = n.abs().toString();
    if (s.length <= 3) return '${n < 0 ? '-' : ''}$s';

    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    while (rest.length > 2) {
      buf.write(',${rest.substring(rest.length - 2)}');
      rest = rest.substring(0, rest.length - 2);
    }
    final grouped = '$rest$buf,$last3';
    return '${n < 0 ? '-' : ''}$grouped';
  }

  /// Price with the ₹ symbol, or "Free" when zero.
  static String price(num amount) =>
      amount <= 0 ? 'Free' : '₹${rupees(amount)}';

  /// Total course length from minutes -> "Xh Ym" / "Ym".
  static String duration(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// "1 lesson" / "8 lessons".
  static String lessons(int count) => '$count ${count == 1 ? 'lesson' : 'lessons'}';

  /// Rating shown as "4.8 (12)".
  static String rating(double value, int count) =>
      '${value.toStringAsFixed(1)} ($count)';

  /// "10:32 AM" — used for chat bubble timestamps.
  static String timeOfDay(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Conversation-list timestamp: time for today, "Yesterday", a weekday
  /// name within the last week, or "12 Jun" further back.
  static String chatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) return timeOfDay(local);

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (isYesterday) return 'Yesterday';

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (now.difference(local).inDays < 7) return weekdays[local.weekday - 1];

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]}';
  }
}
