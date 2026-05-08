import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../data/models/car_model.dart';
import '../../data/models/contract_model.dart';
import '../../data/models/maintenance_model.dart';
import '../../data/repositories/car_repository.dart';
import '../../data/repositories/contract_repository.dart';
import '../../data/repositories/maintenance_repository.dart';

final dioProvider = Provider<Dio>((ref) => DioClient.build());
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

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository(ref.watch(dioProvider));
});

final maintenanceProvider = FutureProvider<List<MaintenanceModel>>((ref) async {
  return ref.watch(maintenanceRepositoryProvider).getMaintenance();
});
