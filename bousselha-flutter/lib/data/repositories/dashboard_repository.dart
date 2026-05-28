import 'package:dio/dio.dart';

import '../models/contract_model.dart';
import '../models/dashboard_alert_model.dart';
import '../models/dashboard_stats_model.dart';

class DashboardRepository {
  final Dio dio;
  DashboardRepository(this.dio);

  Future<DashboardStatsModel> getStats() async {
    final res = await dio.get('/dashboard/stats');
    return DashboardStatsModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<List<ContractModel>> getCalendar() async {
    final res = await dio.get('/dashboard/calendar');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ContractModel.fromJson).toList();
  }

  Future<List<DashboardAlertModel>> getAlerts() async {
    final res = await dio.get('/dashboard/alerts');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(DashboardAlertModel.fromJson).toList();
  }
}
