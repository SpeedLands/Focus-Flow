import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:focus_flow/data/models/user_model.dart';
import 'package:focus_flow/data/providers/auth_app_provider.dart';
import 'package:focus_flow/modules/tasks/tasks_controller.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class SwimlanesViewTV extends StatefulWidget {
  final TaskController controller;
  const SwimlanesViewTV({super.key, required this.controller});

  @override
  SwimlanesViewTVState createState() => SwimlanesViewTVState();
}

class SwimlanesViewTVState extends State<SwimlanesViewTV> {
  // Mapa para cachear los futures de los datos de usuario
  final Map<String, Future<UserData?>> _userFutures = {};
  String? _hoveredTaskId;

  @override
  void initState() {
    super.initState();
    // Pre-cargamos los futures para cada miembro en el initState
    final memberIds = widget.controller.tasksByMember.keys;
    for (final memberId in memberIds) {
      if (!_userFutures.containsKey(memberId)) {
        _userFutures[memberId] = Get.find<AuthProviderApp>().getUserData(
          memberId,
        );
      }
    }
  }

  // --- WIDGETS AUXILIARES PARA EL NUEVO DISEÑO ---

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
            'No hay tareas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Asigna tus tareas para verlas aquí.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  /// Placeholder con Shimmer para el encabezado del carril mientras se carga.
  Widget _buildHeaderPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white),
          const SizedBox(width: 12),
          Container(height: 20, width: 150, color: Colors.white),
        ],
      ),
    );
  }

  /// Encabezado del carril una vez que los datos del usuario están disponibles.
  Widget _buildHeaderContent(UserData user) {
    return Row(
      children: [
        CircleAvatar(child: Text(user.name![0].toUpperCase())),
        const SizedBox(width: 12),
        Text(
          user.name!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// La nueva tarjeta de tarea, más compacta e informativa.
  Widget _buildSwimlaneTaskCard(TaskModel task) {
    final isHovered = _hoveredTaskId == task.id;
    final priorityColor = _getPriorityColor(task.priority);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTaskId = task.id),
      onExit: (_) => setState(() => _hoveredTaskId = null),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFF2a3b57) : const Color(0xFF1c2a41),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHovered
                ? priorityColor
                : Colors.white.withValues(alpha: 0.15),
            width: isHovered ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                task.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.priority.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta especial al final de la lista para añadir una nueva tarea.
  // Widget _buildAddTaskCard(String memberId) {
  //   return InkWell(
  //     onTap: () {
  //       // Lógica para abrir el diálogo/pantalla de creación de tarea,
  //       // pre-llenando el miembro asignado.
  //       print("Añadir tarea para el miembro: $memberId");
  //     },
  //     borderRadius: BorderRadius.circular(8),
  //     child: Container(
  //       width: 150,
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.white24, style: BorderStyle.solid),
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: const Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.add_circle_outline, color: Colors.white54, size: 32),
  //             SizedBox(height: 8),
  //             Text("Añadir Tarea", style: TextStyle(color: Colors.white54)),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  /// El carril o "Swimlane" rediseñado.
  Widget _buildSwimlane(String memberId, List<TaskModel> tasks) {
    return Container(
      height: 240, // Un poco más de altura para la nueva tarjeta
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con FutureBuilder que usa el Future cacheado
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: FutureBuilder<UserData?>(
              future: _userFutures[memberId],
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildHeaderPlaceholder();
                }
                if (!snapshot.hasData) {
                  return _buildHeaderContent(
                    UserData(uid: memberId, name: 'Desconocido', email: ''),
                  );
                }
                return _buildHeaderContent(snapshot.data!);
              },
            ),
          ),
          // Lista horizontal de tareas con animación
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 8),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  // Si es el último elemento, muestra la tarjeta de añadir.

                  final task = tasks[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 300),
                    child: SlideAnimation(
                      horizontalOffset: 30.0,
                      child: FadeInAnimation(
                        child: _buildSwimlaneTaskCard(task),
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
    final tasksByMember = widget.controller.tasksByMember;
    final memberIds = tasksByMember.keys.toList();

    if (memberIds.isEmpty) {
      return _buildEmptyView(); // Usa tu widget de estado vacío mejorado
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: memberIds.length,
        itemBuilder: (context, index) {
          final memberId = memberIds[index];
          final tasks = tasksByMember[memberId]!;
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: _buildSwimlane(memberId, tasks)),
            ),
          );
        },
      ),
    );
  }
}
