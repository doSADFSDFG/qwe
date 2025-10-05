import 'package:intl/intl.dart';

/// 상대 시간(몇 분 전/몇 시간 전)을 한국어로 포맷하는 헬퍼.
String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(dateTime);

  if (difference.inSeconds < 60) {
    return '방금 추가됨';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}분 전 추가';
  }

  if (difference.inHours < 24) {
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    if (minutes == 0) {
      return '${hours}시간 전 추가';
    }
    return '${hours}시간 ${minutes}분 전 추가';
  }

  final days = difference.inDays;
  if (days < 7) {
    final hours = difference.inHours.remainder(24);
    if (hours == 0) {
      return '${days}일 전 추가';
    }
    return '${days}일 ${hours}시간 전 추가';
  }

  return DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
}
