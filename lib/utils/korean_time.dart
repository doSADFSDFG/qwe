/// 한국 표준시(KST, UTC+9) 관련 유틸리티

const Duration _koreanOffset = Duration(hours: 9);

/// 현재 시간을 한국 표준시(KST)로 반환.
/// UTC → +9h 오프셋을 적용한 "naive local" DateTime.
DateTime nowInKoreanTime() {
  final utcNow = DateTime.now().toUtc();
  final kst = utcNow.add(_koreanOffset);
  return DateTime(
    kst.year,
    kst.month,
    kst.day,
    kst.hour,
    kst.minute,
    kst.second,
    kst.millisecond,
    kst.microsecond,
  );
}

/// 입력된 날짜(또는 현재 시각)의 한국시간 자정 반환.
DateTime startOfKoreanDay([DateTime? dateTime]) {
  final date = dateTime ?? nowInKoreanTime();
  return DateTime(date.year, date.month, date.day);
}

/// 한국시간 DateTime을 ISO8601 문자열 +09:00 오프셋 포함 형식으로 반환.
String koreanIsoString(DateTime dateTime) {
  return '${dateTime.toIso8601String()}+09:00'; // ✅ 보간(interpolation) 사용
}
