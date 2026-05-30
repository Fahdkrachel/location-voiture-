import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../data/models/income_record_model.dart';
import '../../data/models/expense_record_model.dart';

enum ChartPeriod { day, month, year }

class FinancialChartDataPoint {
  final String label;
  final DateTime date;
  final double income;
  final double expense;
  final double profit;

  const FinancialChartDataPoint({
    required this.label,
    required this.date,
    required this.income,
    required this.expense,
    required this.profit,
  });
}

class FinancialChart extends StatefulWidget {
  final List<IncomeRecordModel> incomes;
  final List<ExpenseRecordModel> expenses;

  const FinancialChart({
    super.key,
    required this.incomes,
    required this.expenses,
  });

  @override
  State<FinancialChart> createState() => _FinancialChartState();
}

class _FinancialChartState extends State<FinancialChart> {
  ChartPeriod _period = ChartPeriod.month;
  int? _hoveredIndex;
  Offset? _hoverPosition;

  List<FinancialChartDataPoint> _getAggregatedData() {
    final now = DateTime.now();
    final List<FinancialChartDataPoint> points = [];

    if (_period == ChartPeriod.day) {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final label = DateFormat('dd/MM').format(date);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        double incSum = 0;
        for (final inc in widget.incomes) {
          if (inc.recordedAt.startsWith(dateKey)) {
            incSum += inc.amount;
          }
        }

        double expSum = 0;
        for (final exp in widget.expenses) {
          if (exp.recordedAt.startsWith(dateKey)) {
            expSum += exp.amount;
          }
        }

        points.add(FinancialChartDataPoint(
          label: label,
          date: date,
          income: incSum,
          expense: expSum,
          profit: incSum - expSum,
        ));
      }
    } else if (_period == ChartPeriod.month) {
      // Last 12 months
      for (int i = 11; i >= 0; i--) {
        // Handle month subtraction correctly
        final yearOffset = (now.month - 1 - i) ~/ 12;
        int m = (now.month - i) % 12;
        if (m <= 0) m += 12;
        final y = now.year + (now.month - 1 - i < 0 ? yearOffset - 1 : yearOffset);
        
        final date = DateTime(y, m, 1);
        final label = _getMonthLabel(m, y);
        final monthKey = DateFormat('yyyy-MM').format(date);

        double incSum = 0;
        for (final inc in widget.incomes) {
          if (inc.recordedAt.startsWith(monthKey)) {
            incSum += inc.amount;
          }
        }

        double expSum = 0;
        for (final exp in widget.expenses) {
          if (exp.recordedAt.startsWith(monthKey)) {
            expSum += exp.amount;
          }
        }

        points.add(FinancialChartDataPoint(
          label: label,
          date: date,
          income: incSum,
          expense: expSum,
          profit: incSum - expSum,
        ));
      }
    } else {
      // Last 5 years
      for (int i = 4; i >= 0; i--) {
        final y = now.year - i;
        final date = DateTime(y, 1, 1);
        final label = y.toString();
        final yearKey = y.toString();

        double incSum = 0;
        for (final inc in widget.incomes) {
          if (inc.recordedAt.startsWith(yearKey)) {
            incSum += inc.amount;
          }
        }

        double expSum = 0;
        for (final exp in widget.expenses) {
          if (exp.recordedAt.startsWith(yearKey)) {
            expSum += exp.amount;
          }
        }

        points.add(FinancialChartDataPoint(
          label: label,
          date: date,
          income: incSum,
          expense: expSum,
          profit: incSum - expSum,
        ));
      }
    }

    return points;
  }

  String _getMonthLabel(int month, int year) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];
    return '${months[month - 1]} ${year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final dataPoints = _getAggregatedData();

    // Sum totals for the displayed period
    double totalIncome = dataPoints.fold(0, (sum, p) => sum + p.income);
    double totalExpense = dataPoints.fold(0, (sum, p) => sum + p.expense);
    double totalProfit = totalIncome - totalExpense;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Title and Selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Graphique Financier Global',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analyse des revenus, dépenses et rentabilité',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                // Period Toggle Buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _periodButton(ChartPeriod.day, 'Jour'),
                      _periodButton(ChartPeriod.month, 'Mois'),
                      _periodButton(ChartPeriod.year, 'Année'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Financial Summary for Period
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryStat('Revenus', totalIncome, const Color(0xFF10B981)),
                _summaryStat('Dépenses', totalExpense, const Color(0xFFEF4444)),
                _summaryStat(
                  'Bénéfice Net',
                  totalProfit,
                  totalProfit >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFD97706),
                  isProfit: true,
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1),

            // Chart Canvas
            LayoutBuilder(
              builder: (context, constraints) {
                final double chartWidth = constraints.maxWidth;
                const double chartHeight = 260;

                return MouseRegion(
                  onHover: (event) {
                    final localX = event.localPosition.dx;
                    // Calculate closest point index
                    const double paddingLeft = 50;
                    const double paddingRight = 20;
                    final double drawableWidth = chartWidth - paddingLeft - paddingRight;
                    final double stepX = drawableWidth / (dataPoints.length - 1);

                    int index = ((localX - paddingLeft) / stepX).round();
                    index = index.clamp(0, dataPoints.length - 1);

                    setState(() {
                      _hoveredIndex = index;
                      _hoverPosition = event.localPosition;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoveredIndex = null;
                      _hoverPosition = null;
                    });
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // The custom painter
                      SizedBox(
                        width: chartWidth,
                        height: chartHeight,
                        child: CustomPaint(
                          painter: _ChartPainter(
                            dataPoints: dataPoints,
                            hoveredIndex: _hoveredIndex,
                          ),
                        ),
                      ),
                      // Tooltip Overlay
                      if (_hoveredIndex != null && _hoverPosition != null)
                        _buildTooltip(dataPoints[_hoveredIndex!], chartWidth),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem('Revenus', const Color(0xFF10B981)),
                const SizedBox(width: 20),
                _legendItem('Dépenses', const Color(0xFFEF4444)),
                const SizedBox(width: 20),
                _legendItem('Bénéfice Net', const Color(0xFF3B82F6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodButton(ChartPeriod period, String label) {
    final active = _period == period;
    return InkWell(
      onTap: () {
        setState(() {
          _period = period;
          _hoveredIndex = null;
          _hoverPosition = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? const Color(0xFF1A2B4A) : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _summaryStat(String label, double val, Color color, {bool isProfit = false}) {
    final prefix = (isProfit && val > 0) ? '+' : '';
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          '$prefix${val.toStringAsFixed(2)} DH',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildTooltip(FinancialChartDataPoint pt, double width) {
    final double left = _hoverPosition!.dx;
    final double top = _hoverPosition!.dy;

    // Shift tooltip to prevent clipping on right side
    final isLeft = left > (width * 0.65);
    final offsetLeft = isLeft ? left - 190 : left + 20;

    return Positioned(
      left: offsetLeft,
      top: top - 50,
      child: IgnorePointer(
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pt.label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A2B4A)),
              ),
              const Divider(height: 8, thickness: 0.5),
              _tooltipRow('Revenu:', pt.income, const Color(0xFF10B981)),
              _tooltipRow('Dépense:', pt.expense, const Color(0xFFEF4444)),
              _tooltipRow('Profit:', pt.profit, pt.profit >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFD97706)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tooltipRow(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(
            '${val.toStringAsFixed(1)} DH',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<FinancialChartDataPoint> dataPoints;
  final int? hoveredIndex;

  _ChartPainter({required this.dataPoints, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    const double paddingLeft = 50;
    const double paddingRight = 20;
    const double paddingTop = 20;
    const double paddingBottom = 30;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    // Find min and max values to dynamically scale the Y-axis
    double maxVal = 1000.0;
    double minVal = 0.0;

    for (final p in dataPoints) {
      maxVal = math.max(maxVal, p.income);
      maxVal = math.max(maxVal, p.expense);
      maxVal = math.max(maxVal, p.profit);

      minVal = math.min(minVal, p.income);
      minVal = math.min(minVal, p.expense);
      minVal = math.min(minVal, p.profit);
    }

    // Add some padding to bounds
    final double spread = maxVal - minVal;
    maxVal += spread * 0.1;
    minVal -= spread * 0.1;
    if (minVal > 0) minVal = 0; // always keep 0 on grid if possible

    final double range = maxVal - minVal;

    // 1. Draw Gridlines & Y-Axis Labels
    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const int gridLinesCount = 5;
    for (int i = 0; i < gridLinesCount; i++) {
      final double ratio = i / (gridLinesCount - 1);
      final double y = paddingTop + height * (1 - ratio);

      // Draw horizontal grid line
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Draw Y label
      final double val = minVal + range * ratio;
      textPainter.text = TextSpan(
        text: _formatCompactDh(val),
        style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // 2. Draw X-Axis Labels
    final double stepX = width / (dataPoints.length - 1);
    for (int i = 0; i < dataPoints.length; i++) {
      final double x = paddingLeft + i * stepX;
      
      textPainter.text = TextSpan(
        text: dataPoints[i].label,
        style: TextStyle(
          color: i == hoveredIndex ? const Color(0xFF1A2B4A) : Colors.grey.shade600,
          fontSize: 10,
          fontWeight: i == hoveredIndex ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - paddingBottom + 6),
      );
    }

    Offset mapToCanvas(int i, double val) {
      final double x = paddingLeft + i * stepX;
      final double y = paddingTop + height * (1 - (val - minVal) / range);
      return Offset(x, y);
    }

    // 3. Draw Lines & Areas
    final Paint lineIncome = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final Paint lineExpense = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final Paint lineProfit = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final Path pathIncome = Path();
    final Path pathExpense = Path();
    final Path pathProfit = Path();

    pathIncome.moveTo(paddingLeft, mapToCanvas(0, dataPoints[0].income).dy);
    pathExpense.moveTo(paddingLeft, mapToCanvas(0, dataPoints[0].expense).dy);
    pathProfit.moveTo(paddingLeft, mapToCanvas(0, dataPoints[0].profit).dy);

    for (int i = 1; i < dataPoints.length; i++) {
      pathIncome.lineTo(mapToCanvas(i, dataPoints[i].income).dx, mapToCanvas(i, dataPoints[i].income).dy);
      pathExpense.lineTo(mapToCanvas(i, dataPoints[i].expense).dx, mapToCanvas(i, dataPoints[i].expense).dy);
      pathProfit.lineTo(mapToCanvas(i, dataPoints[i].profit).dx, mapToCanvas(i, dataPoints[i].profit).dy);
    }

    canvas.drawPath(pathIncome, lineIncome);
    canvas.drawPath(pathExpense, lineExpense);
    canvas.drawPath(pathProfit, lineProfit);

    // 4. Highlight points and draw Hover Indicators
    final Paint pointPaint = Paint()..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;

    for (int i = 0; i < dataPoints.length; i++) {
      final isHovered = i == hoveredIndex;
      final double profit = dataPoints[i].profit;
      final Offset offsetProfit = mapToCanvas(i, profit);
      
      // Highlight profitable vs unprofitable points dynamically
      // Profitable = green dot under/on curve, Unprofitable = red dot
      final Color indicatorColor = profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

      if (isHovered) {
        // Draw vertical hover tracker line
        final Paint hoverLinePaint = Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(offsetProfit.dx, paddingTop),
          Offset(offsetProfit.dx, size.height - paddingBottom),
          hoverLinePaint,
        );

        // Hovered Profit Dot (Large pulse)
        canvas.drawCircle(offsetProfit, 8, Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.35));
        canvas.drawCircle(offsetProfit, 5, Paint()..color = const Color(0xFF3B82F6));
        canvas.drawCircle(offsetProfit, 5, borderPaint);

        // Hovered Income dot
        final Offset offsetInc = mapToCanvas(i, dataPoints[i].income);
        canvas.drawCircle(offsetInc, 5, Paint()..color = const Color(0xFF10B981));
        canvas.drawCircle(offsetInc, 5, borderPaint);

        // Hovered Expense dot
        final Offset offsetExp = mapToCanvas(i, dataPoints[i].expense);
        canvas.drawCircle(offsetExp, 5, Paint()..color = const Color(0xFFEF4444));
        canvas.drawCircle(offsetExp, 5, borderPaint);
      } else {
        // Profit indicator point (green/red dot depending on profit)
        pointPaint.color = indicatorColor;
        canvas.drawCircle(offsetProfit, 4.5, pointPaint);
        canvas.drawCircle(offsetProfit, 4.5, borderPaint);
      }
    }
  }

  String _formatCompactDh(double val) {
    if (val.abs() >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M DH';
    }
    if (val.abs() >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k DH';
    }
    return '${val.round()} DH';
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints || oldDelegate.hoveredIndex != hoveredIndex;
  }
}
