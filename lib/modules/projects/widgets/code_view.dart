import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para el portapapeles
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/modules/projects/project_controller.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:dotted_border/dotted_border.dart'; // Paquete opcional

class AccessCodeViewTv extends StatefulWidget {
  final ProjectController controller;

  const AccessCodeViewTv({super.key, required this.controller});

  @override
  AccessCodeViewTvState createState() => AccessCodeViewTvState();
}

class AccessCodeViewTvState extends State<AccessCodeViewTv> {
  bool _isCopied = false;

  /// Vista elegante para usuarios que no son administradores.
  Widget _buildNonAdminView(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32.0),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: GFColors.WARNING,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Acceso Restringido',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Solo los administradores del proyecto pueden ver y generar nuevos códigos de acceso.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Vista interactiva y premium para el administrador.
  Widget _buildAdminView(BuildContext context, ProjectModel project) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vpn_key_rounded, color: Colors.white70, size: 40),
          const SizedBox(height: 16),
          Text(
            'Código de Acceso al Proyecto',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          // La tarjeta que contiene el código
          _buildCodeCard(project),
          const SizedBox(height: 40),
          // Botones de acción
          _buildActionButtons(project),
        ],
      ),
    );
  }

  Widget _buildCodeCard(ProjectModel project) {
    return DottedBorder(
      options: const RectDottedBorderOptions(
        color: Colors.white24,
        strokeWidth: 2,
        dashPattern: [10, 6],
        strokeCap: StrokeCap.round,
      ),
      child: Container(
        width: 450,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Obx(() {
          final code = widget.controller.generatedAccessCode.value;
          // Animación para el cambio de código
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: SelectableText(
              // Usamos un Key para que AnimatedSwitcher sepa que el contenido cambió
              key: ValueKey<String>(code),
              code.isEmpty ? '------' : code,
              style: TextStyle(
                fontFamily: 'monospace', // Ideal para códigos
                color: code.isEmpty ? Colors.white38 : Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionButtons(ProjectModel project) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón de Generar Código
        GFButton(
          onPressed: () =>
              widget.controller.performGenerateAccessCode(project.id!),
          text: 'Generar Nuevo Código',
          icon: const Icon(Icons.refresh, color: Colors.white),
          size: GFSize.LARGE,
          shape: GFButtonShape.pills,
          type: GFButtonType.outline2x,
          color: Colors.white,
          hoverColor: project.projectColor.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 20),
        // Botón de Copiar Código
        Obx(() {
          final code = widget.controller.generatedAccessCode.value;
          if (code.isEmpty) {
            return const SizedBox.shrink(); // No mostrar si no hay código
          }

          return GFButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              setState(() => _isCopied = true);
              Get.snackbar(
                '¡Código copiado al portapapeles!',
                '',
                backgroundColor: GFColors.SUCCESS,
              );
              await Future<void>.delayed(const Duration(seconds: 2));
              if (mounted) {
                setState(() => _isCopied = false);
              }
            },
            text: _isCopied ? 'Copiado' : 'Copiar',
            icon: Icon(
              _isCopied
                  ? Icons.check_circle_outline_rounded
                  : Icons.content_copy_rounded,
              color: _isCopied ? GFColors.SUCCESS : Colors.white,
            ),
            size: GFSize.LARGE,
            shape: GFButtonShape.pills,
            color: _isCopied
                ? GFColors.SUCCESS.withValues(alpha: 0.2)
                : GFColors.INFO,
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.controller.selectedProjectForTv.value!;
    final bool isAdmin = widget.controller.isCurrentUserAdmin(project);

    // Elige qué vista mostrar basado en el rol del usuario
    return isAdmin
        ? _buildAdminView(context, project)
        : _buildNonAdminView(context);
  }
}
