import 'dart:io';

import 'package:dio/dio.dart';

import '../models/contract_model.dart';

class ContractRepository {
  final Dio dio;
  ContractRepository(this.dio);

  Future<List<ContractModel>> getContracts({int? carId}) async {
    final res = await dio.get('/contracts', queryParameters: carId == null ? null : {'carId': carId});
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ContractModel.fromJson).toList();
  }

  Future<ContractModel> getContractById(int id) async {
    final res = await dio.get('/contracts/$id');
    return ContractModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<ContractModel> createContract({
    required int carId,
    required int clientId,
    required String departureDatetime,
    required String expectedReturnDatetime,
    String? actualReturnDatetime,
    int? durationDays,
    double? pricePerHour,
    double? pricePerDay,
    double? pricePerWeek,
    double? pricePerMonth,
    bool withInsurance = true,
    double? totalPrice,
    double? supplement,
    required double totalGeneral,
    double? paymentCash,
    double? paymentCheck,
    double? paymentDeposit,
    String? departurePlace,
    String? returnPlace,
  }) async {
    final res = await dio.post(
      '/contracts',
      data: {
        'carId': carId,
        'clientId': clientId,
        'departureDatetime': departureDatetime,
        'expectedReturnDatetime': expectedReturnDatetime,
        'actualReturnDatetime': actualReturnDatetime,
        'durationDays': durationDays,
        'pricePerHour': pricePerHour,
        'pricePerDay': pricePerDay,
        'pricePerWeek': pricePerWeek,
        'pricePerMonth': pricePerMonth,
        'withInsurance': withInsurance,
        'totalPrice': totalPrice,
        'supplement': supplement,
        'totalGeneral': totalGeneral,
        'paymentCash': paymentCash,
        'paymentCheck': paymentCheck,
        'paymentDeposit': paymentDeposit,
        'departurePlace': departurePlace,
        'returnPlace': returnPlace,
      },
    );
    return ContractModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<ContractModel> registerReturn(int id) async {
    final res = await dio.put('/contracts/$id/return');
    return ContractModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<ContractModel> updateContractStatus(int id, String status) async {
    final res = await dio.patch('/contracts/$id/status', data: {'status': status});
    return ContractModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// URL absolue du PDF pour `launchUrl` (baseUrl Dio + `/contracts/{id}/pdf`).
  String contractPdfAbsoluteUrl(int id) {
    final root = dio.options.baseUrl.trim();
    final trimmed = root.endsWith('/') ? root.substring(0, root.length - 1) : root;
    return '$trimmed/contracts/$id/pdf';
  }

  Future<ContractModel> updateContract({
    required int id,
    required int carId,
    required int clientId,
    required String departureDatetime,
    required String expectedReturnDatetime,
    String? actualReturnDatetime,
    int? durationDays,
    double? pricePerHour,
    double? pricePerDay,
    double? pricePerWeek,
    double? pricePerMonth,
    bool withInsurance = true,
    double? totalPrice,
    double? supplement,
    required double totalGeneral,
    double? paymentCash,
    double? paymentCheck,
    double? paymentDeposit,
    String? departurePlace,
    String? returnPlace,
    String? additionalDriverName,
    String? additionalDriverLicense,
    String? additionalDriverPassport,
    String? vehicleConditionDeparture,
    String? vehicleConditionReturn,
    String? damagesIdentified,
  }) async {
    final data = <String, dynamic>{
      'carId': carId,
      'clientId': clientId,
      'departureDatetime': departureDatetime,
      'expectedReturnDatetime': expectedReturnDatetime,
      'durationDays': durationDays,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'pricePerWeek': pricePerWeek,
      'pricePerMonth': pricePerMonth,
      'withInsurance': withInsurance,
      'totalPrice': totalPrice,
      'supplement': supplement,
      'totalGeneral': totalGeneral,
      'paymentCash': paymentCash,
      'paymentCheck': paymentCheck,
      'paymentDeposit': paymentDeposit,
      'departurePlace': departurePlace,
      'returnPlace': returnPlace,
      'additionalDriverName': additionalDriverName,
      'additionalDriverLicense': additionalDriverLicense,
      'additionalDriverPassport': additionalDriverPassport,
      'vehicleConditionDeparture': vehicleConditionDeparture,
      'vehicleConditionReturn': vehicleConditionReturn,
      'damagesIdentified': damagesIdentified,
    };
    if (actualReturnDatetime != null && actualReturnDatetime.isNotEmpty) {
      data['actualReturnDatetime'] = actualReturnDatetime;
    }
    final res = await dio.put('/contracts/$id', data: data);
    return ContractModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> deleteContract(int id) async {
    await dio.delete('/contracts/$id');
  }

  Future<String> downloadContractPdf(int id) async {
    final res = await dio.get(
      '/contracts/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = List<int>.from(res.data as List);
    final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.current.path;
    final downloadsDir = Directory('$userHome/Downloads');
    final targetDir = await (await downloadsDir.exists() ? downloadsDir : Directory.current).create(recursive: true);
    final filePath = '${targetDir.path}${Platform.pathSeparator}contract-$id-${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
