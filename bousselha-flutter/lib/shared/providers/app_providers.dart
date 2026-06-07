import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/models/car_model.dart';
import '../../data/models/client_model.dart';
import '../../data/models/contract_model.dart';
import '../../data/models/dashboard_alert_model.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/models/maintenance_model.dart';
import '../../data/models/expense_record_model.dart';
import '../../data/models/income_record_model.dart';
import '../../data/models/admin_model.dart';
import '../../data/repositories/car_repository.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/contract_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/financial_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../data/repositories/admin_repository.dart';

final dioProvider = Provider<Dio>((ref) => DioClient.build());

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

final adminsProvider = FutureProvider<List<AdminModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAdmins();
});

final carRepositoryProvider = Provider<CarRepository>((ref) {
  return CarRepository(ref.watch(dioProvider));
});


final carsProvider = FutureProvider<List<CarModel>>((ref) async {
  return ref.watch(carRepositoryProvider).getCars();
});

final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  return ContractRepository(ref.watch(dioProvider));
});

final contractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  return ref.watch(contractRepositoryProvider).getContracts();
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(dioProvider));
});

final clientsProvider = FutureProvider<List<ClientModel>>((ref) async {
  return ref.watch(clientRepositoryProvider).getClients();
});

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository(ref.watch(dioProvider));
});

final maintenanceProvider = FutureProvider<List<MaintenanceModel>>((ref) async {
  return ref.watch(maintenanceRepositoryProvider).getMaintenance();
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  return FinancialRepository(ref.watch(dioProvider));
});

final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getStats();
});

final dashboardCalendarProvider = FutureProvider<List<ContractModel>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getCalendar();
});

final dashboardAlertsProvider = FutureProvider<List<DashboardAlertModel>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getAlerts();
});

final dashboardFutureReservationsProvider = FutureProvider<List<ContractModel>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getFutureReservations();
});

final incomeProvider = FutureProvider<List<IncomeRecordModel>>((ref) async {
  return ref.watch(financialRepositoryProvider).getIncome();
});

final expensesProvider = FutureProvider<List<ExpenseRecordModel>>((ref) async {
  return ref.watch(financialRepositoryProvider).getExpenses();
});

void invalidateAllBoushelhaProviders(dynamic ref) {
  ref.invalidate(carsProvider);
  ref.invalidate(maintenanceProvider);
  ref.invalidate(contractsProvider);
  ref.invalidate(clientsProvider);
  ref.invalidate(dashboardStatsProvider);
  ref.invalidate(dashboardCalendarProvider);
  ref.invalidate(dashboardAlertsProvider);
  ref.invalidate(dashboardFutureReservationsProvider);
  ref.invalidate(incomeProvider);
  ref.invalidate(expensesProvider);
  ref.invalidate(adminsProvider);
}
