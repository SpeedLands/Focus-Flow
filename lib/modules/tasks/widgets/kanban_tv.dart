import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';
import 'package:getwidget/getwidget.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class KanbanViewTV extends StatefulWidget {
  final TaskController controller;
  const KanbanViewTV({super.key, required this.controller});

  @override
  KanbanViewTVState createState() => KanbanViewTVState();
}

class KanbanViewTVState extends State<KanbanViewTV> {
  // Para gestionar el estado de hover de las tarjetas individualmente
  String? _hoveredTaskId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn(
            'Pendientes',
            widget.controller.pendingTasks,
            false,
          ),
          const SizedBox(width: 20),
          _buildKanbanColumn(
            'Completadas',
            widget.controller.completedTasks,
            true,
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES PARA EL NUEVO DISEÑO ---

  /// Devuelve un color basado en la prioridad de la tarea.
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

  /// La nueva tarjeta de tarea, ahora interactiva y más informativa.
  Widget _buildTaskCardTV(BuildContext context, TaskModel task) {
    final isHovered = _hoveredTaskId == task.id;
    final priorityColor = _getPriorityColor(task.priority);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTaskId = task.id),
      onExit: (_) => setState(() => _hoveredTaskId = null),
      cursor: SystemMouseCursors.grab,
      child: AnimatedScale(
        scale: isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Card(
          elevation: isHovered ? 12 : 4,
          shadowColor: Colors.black.withValues(alpha: 0.6),
          color: const Color(0xFF1c2a41),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isHovered ? priorityColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Indicador de prioridad
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              // Contenido de la tarea
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white54,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              // Formatea la fecha como necesites
                              "Vence: ${task.dueDate!.toDate().toString().split(' ')[0]}",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// El widget que se muestra en una columna vacía.
  Widget _buildEmptyColumnContent(String title) {
    final bool isCompleted = title == 'Completadas';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_outline_rounded
                : Icons.add_task_rounded,
            size: 60,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isCompleted ? '¡Ninguna tarea completada!' : 'Arrastra tareas aquí',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// La columna Kanban rediseñada.
  Widget _buildKanbanColumn(
    String title,
    List<TaskModel> tasks,
    bool isCompletedColumn,
  ) {
    return Expanded(
      child: DragTarget<TaskModel>(
        onWillAcceptWithDetails: (details) {
          // Accedemos a la tarea a través de details.data
          final task = details.data;
          // La lógica de la condición es la misma
          return task.isCompleted != isCompletedColumn;
        },

        // Reemplazamos onAccept por onAcceptWithDetails
        onAcceptWithDetails: (details) {
          // Accedemos a la tarea a través de details.data y llamamos al controlador
          widget.controller.toggleTaskCompletion(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isHoveringTarget = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isHoveringTarget
                    ? [
                        const Color(0xFF005b4f),
                        const Color(0xFF004d40),
                      ] // Verde oscuro al arrastrar
                    : [
                        const Color(0xFF233048),
                        const Color(0xFF1a2436),
                      ], // Azul oscuro normal
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHoveringTarget
                    ? GFColors.SUCCESS
                    : Colors.white.withValues(alpha: 0.1),
                width: isHoveringTarget ? 3 : 1,
              ),
            ),
            child: Column(
              children: [
                // Encabezado de la columna
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Chip(
                        label: Text(
                          tasks.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                      ),
                    ],
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
                      ? _buildEmptyColumnContent(title)
                      : AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: tasks.length,
                            itemBuilder: (ctx, index) {
                              final task = tasks[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Draggable<TaskModel>(
                                      data: task,
                                      feedback: Transform.rotate(
                                        angle:
                                            -0.05, // Ligera rotación al arrastrar
                                        child: Material(
                                          elevation: 10.0,
                                          color: Colors.transparent,
                                          child: SizedBox(
                                            width: 350,
                                            child: _buildTaskCardTV(
                                              context,
                                              task,
                                            ),
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.8,
                                        child: DottedBorder(
                                          options:
                                              const RectDottedBorderOptions(
                                                color: Colors.white38,
                                                strokeWidth: 2,
                                                dashPattern: [8, 4],
                                              ),

                                          child: Container(
                                            height: 60,
                                          ), // Placeholder
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10.0,
                                        ),
                                        child: _buildTaskCardTV(context, task),
                                      ),
                                    ),
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
        },
      ),
    );
  }
}
