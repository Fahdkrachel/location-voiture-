import 'package:dio/dio.dart';

import '../models/contract_model.dart';

class ContractRepository {
  final Dio dio;
  ContractRepository(this.dio);

  Future<List<ContractModel>> getContracts() async {
    final res = await dio.get('/contracts');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ContractModel.fromJson).toList();
  }
}
