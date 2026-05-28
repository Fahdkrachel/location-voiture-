import 'package:dio/dio.dart';

import '../models/expense_record_model.dart';
import '../models/income_record_model.dart';

class FinancialRepository {
  final Dio dio;
  FinancialRepository(this.dio);

  Future<List<IncomeRecordModel>> getIncome({
    String? from,
    String? to,
    String? source,
    double? minAmount,
    double? maxAmount,
  }) async {
    final res = await dio.get(
      '/financial/income',
      queryParameters: {
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        if (source != null && source.isNotEmpty) 'source': source,
        if (minAmount != null) 'minAmount': minAmount,
        if (maxAmount != null) 'maxAmount': maxAmount,
      },
    );
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(IncomeRecordModel.fromJson).toList();
  }

  Future<List<ExpenseRecordModel>> getExpenses({
    String? from,
    String? to,
    String? source,
    String? category,
  }) async {
    final res = await dio.get(
      '/financial/expenses',
      queryParameters: {
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        if (source != null && source.isNotEmpty) 'source': source,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ExpenseRecordModel.fromJson).toList();
  }
}
