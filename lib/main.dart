import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ 한국어 날짜 형식 지원용
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 날짜/시간 지역 데이터 초기화 (한국어)
  await initializeDateFormatting('ko_KR', null);

  // ✅ ProviderScope로 앱 실행
  runApp(const ProviderScope(child: CalutPosApp()));
}
