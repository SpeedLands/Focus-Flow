import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/user_model.dart';
import 'package:focus_flow/data/providers/auth_app_provider.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

class RecentActivityFeedTv extends StatefulWidget {
  final ProjectController controller;

  const RecentActivityFeedTv({super.key, required this.controller});

  @override
  RecentActivityFeedTvState createState() => RecentActivityFeedTvState();
}

class RecentActivityFeedTvState extends State<RecentActivityFeedTv> {
  int? _hoveredIndex;

  final Map<String, Future<UserData?>> _userFutures = {};

  // --- WIDGETS AUXILIARES PARA MAYOR CLARIDAD ---

  /// Devuelve un icono y color basado en el tipo de actividad.
  /// ¡DEBES ADAPTAR ESTA LÓGICA A TUS DATOS REALES!
  Widget _getIconForActivity(String activityType) {
    IconData icon;
    Color color;

    switch (activityType) {
      case 'task_completed':
        icon = Icons.check_circle;
        color = GFColors.SUCCESS;
        break;
      case 'comment_added':
        icon = Icons.chat_bubble_rounded;
        color = GFColors.INFO;
        break;
      case 'file_uploaded':
        icon = Icons.attach_file_rounded;
        color = GFColors.WARNING;
        break;
      default:
        icon = Icons.notifications_active_rounded;
        color = GFColors.PRIMARY;
    }

    return GFAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  /// Widget para el estado cuando no hay actividad.
  Widget _buildEmptyState(BuildContext context) {
    final project = widget.controller.selectedProjectForTv.value;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 24),
          Text(
            'Aún no hay actividad en este proyecto',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Las acciones importantes aparecerán aquí.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GFButton(
            onPressed: () {
              widget.controller.setCurrentProjectRole(project!);
              Get.toNamed<Object>(
                AppRoutes.TASKS_LIST,
                arguments: {
                  'projectId': project.id,
                  'projectName': project.name,
                },
              );
            },
            text: 'Ir a las Tareas del Proyecto',
            shape: GFButtonShape.pills,
            size: GFSize.LARGE,
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            position: GFPosition.end,
            color: GFColors.INFO,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSubtitle() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[700]!,
      highlightColor: Colors.grey[600]!,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 120, height: 12, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildUserSubtitle(UserData? user, Map<String, dynamic> activity) {
    final timestamp = activity['time'] as Timestamp?;
    final timeAgo = (timestamp != null)
        ? timeago.format(timestamp.toDate(), locale: 'es')
        : 'hace un momento'; // Valor por defecto si el tiempo es nulo

    final userName = user?.name ?? 'Usuario Desconocido';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar del usuario
        if (user != null)
          CircleAvatar(
            radius: 12,
            backgroundColor: GFColors.SECONDARY,
            // Aquí deberías añadir la lógica para la imagen de perfil si la tienes
            // backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: Text(
              userName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (user == null)
          const Icon(
            Icons.person_off_outlined,
            size: 20,
            color: Colors.white38,
          ),

        const SizedBox(width: 8),

        // Nombre y tiempo
        Expanded(
          child: Text(
            '$userName • $timeAgo',
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Widget que construye cada elemento (tile) de la lista.
  Widget _buildActivityTile(Map<String, dynamic> activity, int index) {
    final isHovered = _hoveredIndex == index;
    final userId = (activity['user'] as String?) ?? '';

    // <-- 7. LÓGICA DE CACHÉ "LAZY"
    // Busca el Future en el caché. Si no existe, lo crea y lo guarda.
    final userFuture = userId.isNotEmpty
        ? _userFutures.putIfAbsent(
            userId,
            () => Get.find<AuthProviderApp>().getUserData(userId),
          )
        : Future<UserData?>.value(null);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          elevation: isHovered ? 12 : 4,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          color: const Color(0xFF1c2a41),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isHovered ? GFColors.INFO : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: FutureBuilder<UserData?>(
            future: userFuture,
            builder: (context, snapshot) {
              final activityType = (activity['type'] as String?) ?? 'default';
              final activityText =
                  (activity['text'] as String?) ?? 'Actividad sin descripción';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                leading: _getIconForActivity(activityType),
                title: Text(
                  activityText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                  ), // Aumentamos un poco el padding
                  child: (snapshot.connectionState == ConnectionState.waiting)
                      ? _buildLoadingSubtitle() // Muestra el shimmer mientras carga
                      : _buildUserSubtitle(
                          snapshot.data,
                          activity,
                        ), // Muestra los datos del usuario
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.controller.selectedProjectForTv.value;

    return Obx(() {
      if (widget.controller.recentActivity.isEmpty) {
        return _buildEmptyState(context);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Actividad Reciente',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            // Animaciones para la lista
            child: AnimationLimiter(
              child: ListView.builder(
                itemCount: widget.controller.recentActivity.length,
                itemBuilder: (context, index) {
                  final activity = widget.controller.recentActivity[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildActivityTile(activity, index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // El botón de "Ver Tareas" ahora está al final, como un CTA claro
          const SizedBox(height: 24),
          Center(
            child: GFButton(
              onPressed: () {
                widget.controller.setCurrentProjectRole(project!);
                Get.toNamed<Object>(
                  AppRoutes.TASKS_LIST,
                  arguments: {
                    'projectId': project.id,
                    'projectName': project.name,
                  },
                );
              },
              text: 'Ver Todas las Tareas',
              shape: GFButtonShape.pills,
              size: GFSize.LARGE,
              icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
              blockButton: true,
              color: GFColors.SECONDARY,
            ),
          ),
        ],
      );
    });
  }
}
