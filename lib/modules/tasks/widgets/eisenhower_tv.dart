import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class EisenhowerViewTV extends StatelessWidget {
  final TaskController controller;
  const EisenhowerViewTV({super.key, required this.controller});

  // --- MAPA DE CONFIGURACIÓN PARA LOS CUADRANTES ---
  // Esto centraliza la configuración y hace el código más limpio.
  static const Map<String, Map<String, dynamic>> _quadrantConfig = {
    'important_urgent': {
      'title': 'Hacer Ahora',
      'subtitle': 'Urgente e Importante',
      'color': Color(0xFFc62828), // Rojo oscuro
      'icon': Icons.flash_on_rounded,
    },
    'important_not_urgent': {
      'title': 'Planificar',
      'subtitle': 'Importante, No Urgente',
      'color': Color(0xFFfb8c00), // Naranja oscuro
      'icon': Icons.calendar_today_rounded,
    },
    'not_important_urgent': {
      'title': 'Delegar',
      'subtitle': 'Urgente, No Importante',
      'color': Color(0xFF1565c0), // Azul oscuro
      'icon': Icons.group_add_rounded,
    },
    'not_important_not_urgent': {
      'title': 'Descartar',
      'subtitle': 'Ni Urgente, Ni Importante',
      'color': Color(0xFF388e3c), // Verde oscuro
      'icon': Icons.delete_sweep_rounded,
    },
  };

  @override
  Widget build(BuildContext context) {
    final tasks = controller.eisenhowerTasks;
    // La clave es obtener las claves del mapa en el orden correcto
    final quadrantKeys = [
      'important_urgent',
      'important_not_urgent',
      'not_important_urgent',
      'not_important_not_urgent',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 16 / 10, // Un poco más alto para más contenido
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final key = quadrantKeys[index];
          final config = _quadrantConfig[key]!;
          return _buildEisenhowerQuadrant(
            config['title'] as String,
            config['subtitle'] as String,
            tasks[key]!,
            config['color'] as Color,
            config['icon'] as IconData,
          );
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES REDISEÑADOS ---

  /// La tarjeta de tarea pequeña, ahora más visual.
  Widget _buildMiniTaskTile(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.label_important_outline_rounded,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.name, // Asumiendo que task.name es el título
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// El widget que se muestra cuando un cuadrante está vacío.
  Widget _buildEmptyQuadrantContent(IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'No hay tareas aquí',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// El cuadrante de Eisenhower, completamente rediseñado.
  Widget _buildEisenhowerQuadrant(
    String title,
    String subtitle,
    List<TaskModel> tasks,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.3), Colors.blueGrey[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del cuadrante
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de tareas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: tasks.isEmpty
                  ? _buildEmptyQuadrantContent(icon, color)
                  : AnimationLimiter(
                      child: ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) =>
                            AnimationConfiguration.staggeredList(
                              position: i,
                              duration: const Duration(milliseconds: 300),
                              child: SlideAnimation(
                                verticalOffset: 20.0,
                                child: FadeInAnimation(
                                  child: _buildMiniTaskTile(tasks[i]),
                                ),
                              ),
                            ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
