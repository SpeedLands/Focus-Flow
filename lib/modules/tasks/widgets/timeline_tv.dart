import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class TimelineViewTV extends StatefulWidget {
  final TaskController controller;
  const TimelineViewTV({super.key, required this.controller});

  @override
  TimelineViewTVState createState() => TimelineViewTVState();
}

class TimelineViewTVState extends State<TimelineViewTV> {
  String? _hoveredTaskId;

  // --- WIDGETS AUXILIARES PARA EL NUEVO DISEÑO ---

  /// Da formato a la fecha de forma más humana.
  String _formatDayHeader(DateTime day) {
    final now = DateTime.now();
    if (day.year == now.year && day.month == now.month && day.day == now.day) {
      return 'Hoy';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (day.year == tomorrow.year &&
        day.month == tomorrow.month &&
        day.day == tomorrow.day) {
      return 'Mañana';
    }
    // Para otros días, usa un formato legible
    return DateFormat('EEE, dd MMM', 'es_ES').format(day);
  }

  /// Devuelve un color basado en la prioridad.
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.alta:
        return Colors.red.shade400;
      case TaskPriority.media:
        return Colors.orange.shade400;
      case TaskPriority.baja:
        return Colors.blue.shade400;
    }
  }

  /// Estado vacío para toda la vista de timeline.
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_view_day_rounded,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 24),
          Text(
            'No hay tareas con fechas próximas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Asigna fechas de entrega a tus tareas para verlas aquí.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  /// La nueva tarjeta de tarea, interactiva y limpia.
  Widget _buildTimelineTaskCard(TaskModel task) {
    final isHovered = _hoveredTaskId == task.id;
    final priorityColor = _getPriorityColor(task.priority);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTaskId = task.id),
      onExit: (_) => setState(() => _hoveredTaskId = null),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFF2a3b57) : const Color(0xFF1c2a41),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHovered ? priorityColor : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Indicador de prioridad
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// La columna de un día en la línea de tiempo, completamente rediseñada.
  Widget _buildTimelineColumn(DateTime day, List<TaskModel> tasks) {
    final isToday = _formatDayHeader(day) == 'Hoy';

    return Container(
      width: 280, // Un poco más ancha para más contenido
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isToday
              ? [
                  const Color(0xFF1565c0),
                  const Color(0xFF0d47a1),
                ] // Gradiente azul para "Hoy"
              : [
                  const Color(0xFF37474f),
                  const Color(0xFF263238),
                ], // Gradiente gris oscuro
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? Colors.blue.shade300
              : Colors.white.withValues(alpha: 0.1),
          width: isToday ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _formatDayHeader(day),
              style: TextStyle(
                color: isToday ? Colors.white : Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(
            color: Colors.white24,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          // Lista de tareas
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text(
                      'Sin tareas este día',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: tasks.length,
                      itemBuilder: (ctx, i) {
                        return AnimationConfiguration.staggeredList(
                          position: i,
                          duration: const Duration(milliseconds: 300),
                          child: SlideAnimation(
                            verticalOffset: 20,
                            child: FadeInAnimation(
                              child: _buildTimelineTaskCard(tasks[i]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksByDay = widget.controller.timelineTasks;
    final sortedDays = tasksByDay.keys.toList()..sort();

    if (sortedDays.isEmpty) {
      return _buildEmptyView();
    }

    return AnimationLimiter(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(20),
        itemCount: sortedDays.length,
        itemBuilder: (context, index) {
          final day = sortedDays[index];
          final tasks = tasksByDay[day]!;
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(child: _buildTimelineColumn(day, tasks)),
            ),
          );
        },
      ),
    );
  }
}
