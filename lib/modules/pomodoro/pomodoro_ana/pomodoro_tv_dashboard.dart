import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:focus_flow/data/models/session_stat.dart';

class PomodoroTvDashboard extends StatelessWidget {
  final List<SessionStat> stats;
  const PomodoroTvDashboard({super.key, required this.stats});

  /* ────────────── 1) Línea de minutos trabajados ────────────── */
  Widget _workedLine() {
    final spots = List.generate(
      stats.length,
      (i) => FlSpot(i.toDouble(), stats[i].workedMinutes.toDouble()),
    );

    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: _daysTitles),
          leftTitles: AxisTitles(sideTitles: _sideNumericTitles),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 4,
            color: Colors.orangeAccent,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  /* ────────────── 2) Barras de minutos de descanso ────────────── */
  Widget _breakBar() {
    final barGroups = List.generate(
      stats.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: stats[i].breakMinutes.toDouble(),
            width: 18,
            borderRadius: BorderRadius.circular(4),
            color: Colors.lightBlueAccent,
          ),
        ],
      ),
    );

    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: _daysTitles),
          leftTitles: AxisTitles(sideTitles: _sideNumericTitles),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  /* ────────────── 3) Barras de pomodoros completados ────────────── */
  Widget _pomosBar() {
    final barGroups = List.generate(
      stats.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: stats[i].pomodorosCompleted.toDouble(),
            width: 18,
            borderRadius: BorderRadius.circular(4),
            color: Colors.greenAccent,
          ),
        ],
      ),
    );

    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: _daysTitles),
          leftTitles: AxisTitles(sideTitles: _sideNumericTitles),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  /* ────────────── 4) Radar resumen último día ────────────── */
  Widget _radar() {
    final last = stats.last; // día más reciente
    return RadarChart(
      RadarChartData(
        radarBackgroundColor: Colors.transparent,
        tickCount: 3,
        radarShape: RadarShape.polygon,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
        getTitle: (i, _) => RadarChartTitle(
          text: ['Trabajo (h)', 'Descanso (m)', 'Pomodoros'][i],
        ),
        dataSets: [
          RadarDataSet(
            borderColor: Colors.purpleAccent,
            fillColor: Colors.purpleAccent.withValues(alpha: 0.4),
            borderWidth: 2,
            entryRadius: 3,
            dataEntries: [
              RadarEntry(value: last.workedMinutes / 60), // horas trabajadas
              RadarEntry(value: last.breakMinutes.toDouble()),
              RadarEntry(value: last.pomodorosCompleted.toDouble()),
            ],
          ),
        ],
      ),
    );
  }

  /* ────────────── Helpers de ejes ────────────── */
  SideTitles get _daysTitles => SideTitles(
    showTitles: true,
    reservedSize: 30,
    getTitlesWidget: (value, _) {
      final i = value.toInt();
      if (i < 0 || i >= stats.length) return const SizedBox.shrink();
      return Text(
        DateFormat.E().format(stats[i].start), // “Mon”, “Tue”, …
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      );
    },
  );

  SideTitles get _sideNumericTitles => SideTitles(
    showTitles: true,
    reservedSize: 28,
    getTitlesWidget: (value, _) => Text(
      value.toInt().toString(),
      style: const TextStyle(color: Colors.white54, fontSize: 10),
    ),
  );

  /* ────────────── Build ────────────── */
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      padding: const EdgeInsets.all(20),
      children: [
        _card('Minutos trabajados', _workedLine()),
        _card('Minutos de descanso', _breakBar()),
        _card('Pomodoros completados', _pomosBar()),
        _card('Resumen del día', _radar()),
      ],
    );
  }

  Widget _card(String title, Widget chart) => Card(
    color: Colors.black87,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: chart),
        ],
      ),
    ),
  );
}
