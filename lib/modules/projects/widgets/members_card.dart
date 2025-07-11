import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/user_model.dart';
import 'package:focus_flow/data/providers/auth_app_provider.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart'; // <-- 1. Dependencia nueva para efecto de carga

class MemberStatusGridTv extends StatefulWidget {
  final ProjectController controller;

  const MemberStatusGridTv({super.key, required this.controller});

  @override
  MemberStatusGridTvState createState() => MemberStatusGridTvState();
}

class MemberStatusGridTvState extends State<MemberStatusGridTv> {
  int? _hoveredIndex;

  late Map<String, Future<UserData?>> _userFutures;

  @override
  void initState() {
    super.initState();
    // <-- PASO 2: Inicializar los Futures en initState.
    // Esto se ejecuta UNA SOLA VEZ.
    _userFutures = {}; // Inicializamos el mapa.
    final project = widget.controller.selectedProjectForTv.value!;
    final members = project.userRoles
        .map((role) => role.split(':').first)
        .toSet();

    // Por cada miembro, llamamos a la función y guardamos el Future en nuestro mapa.
    for (final userId in members) {
      _userFutures[userId] = Get.find<AuthProviderApp>().getUserData(userId);
    }
  }

  /// Widget de carga (placeholder) que se muestra mientras se obtienen los datos del usuario.
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Widget para la insignia de "Admin".
  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GFColors.PRIMARY.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GFColors.PRIMARY, width: 1),
      ),
      child: const Text(
        'Admin',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Construye la tarjeta de un miembro una vez que sus datos se han cargado.
  Widget _buildMemberCard(UserData user, bool isAdmin, int index) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1e2c4b), Color(0xFF1a2436)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isHovered
                  ? GFColors.INFO
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              if (isHovered)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: GFColors.SECONDARY,
                  child: Text(
                    user.name!.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) const SizedBox(width: 8),
                          if (isAdmin) _buildAdminBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email, // Mostrar el email es más útil que el ID
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.controller.selectedProjectForTv.value!;
    final members = project.userRoles
        .map((role) => role.split(':').first)
        .toSet()
        .toList();

    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 350, // Ligeramente más pequeño para mejor ajuste
          childAspectRatio: 3 / 1.5, // Ajustado para el nuevo diseño de tarjeta
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: members.length,
        itemBuilder: (ctx, index) {
          final userId = members[index];
          final bool isAdmin = project.adminUserId == userId;

          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: (MediaQuery.of(context).size.width / 350).floor(),
            duration: const Duration(milliseconds: 400),
            child: ScaleAnimation(
              child: FadeInAnimation(
                // Usamos FutureBuilder para obtener los datos del usuario de forma asíncrona
                child: FutureBuilder<UserData?>(
                  future: _userFutures[userId],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerPlaceholder(); // Muestra un efecto de carga
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      // Manejo de error: muestra la tarjeta con datos limitados
                      return _buildMemberCard(
                        UserData(
                          uid: userId,
                          name: 'Usuario Desconocido',
                          email: userId,
                        ),
                        isAdmin,
                        index,
                      );
                    }

                    final user = snapshot.data!;
                    return _buildMemberCard(user, isAdmin, index);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
