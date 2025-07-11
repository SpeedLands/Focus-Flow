import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_ana/pomodoro_controller.dart';
import 'package:get/get.dart';

class PomodoroConfigFormScreen extends GetView<PomodoroControllerAna> {
  const PomodoroConfigFormScreen({super.key});

  Widget _buildMobilePomodoroScreen(BuildContext context) {
    final isEditing = controller.editingConfigId != null;
    final title = isEditing ? 'Editar Configuración' : 'Nueva Configuración';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Obx(() {
            if (controller.isSavingConfig.value) {
              return const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.save),
              onPressed: controller.saveConfig,
              tooltip: 'Guardar',
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextField(
                controller: controller.nameController,
                labelText: 'Nombre de la Configuración',
                hintText: 'Ej: Estudio Profundo',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildNumericField(
                controller: controller.workTimeController,
                labelText: 'Tiempo de Trabajo (minutos)',
                hintText: 'Ej: 25',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El tiempo de trabajo es obligatorio';
                  }
                  final intVal = int.tryParse(value);
                  if (intVal == null || intVal <= 0) {
                    return 'Debe ser un número mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildNumericField(
                controller: controller.shortBreakController,
                labelText: 'Descanso Corto (minutos)',
                hintText: 'Ej: 5',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El descanso corto es obligatorio';
                  }
                  final intVal = int.tryParse(value);
                  if (intVal == null || intVal <= 0) {
                    return 'Debe ser un número mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildNumericField(
                controller: controller.longBreakController,
                labelText: 'Descanso Largo (minutos, opcional)',
                hintText: 'Ej: 15',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final intVal = int.tryParse(value);
                    if (intVal == null || intVal < 0) {
                      return 'Debe ser un número válido (0 o más)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildNumericField(
                controller: controller.roundsController,
                labelText: 'Rondas antes de Descanso Largo',
                hintText: 'Ej: 4',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El número de rondas es obligatorio';
                  }
                  final intVal = int.tryParse(value);
                  if (intVal == null || intVal <= 0) {
                    return 'Debe ser un número mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: controller.goalController,
                labelText: 'Meta (opcional)',
                hintText: 'Ej: Terminar capítulo 3',
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              Obx(
                () => ElevatedButton.icon(
                  icon: controller.isSavingConfig.value
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    controller.isSavingConfig.value
                        ? 'Guardando...'
                        : 'Guardar Configuración',
                  ),
                  onPressed: controller.isSavingConfig.value
                      ? null
                      : controller.saveConfig,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchPomodoroScreen(BuildContext context) {
    final isEditing = controller.editingConfigId != null;
    final title = isEditing ? 'Editar' : 'Nueva';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.only(top: 10),
            children: [
              Center(
                child: Text(
                  '$title Config.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _simpleField(controller.nameController, 'Nombre', maxLen: 20),
              _numericField(controller.workTimeController, 'Trabajo'),
              _numericField(controller.shortBreakController, 'Desc. Corto'),
              _numericField(controller.longBreakController, 'Desc. Largo'),
              _numericField(controller.roundsController, 'Rondas'),
              _simpleField(controller.goalController, 'Meta', maxLines: 2),
              const SizedBox(height: 16),
              Obx(
                () => ElevatedButton.icon(
                  icon: controller.isSavingConfig.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    controller.isSavingConfig.value ? 'Guardando' : 'Guardar',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: controller.isSavingConfig.value
                      ? null
                      : controller.saveConfig,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTvPomodoroScreen(BuildContext context) {
    return const Scaffold();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final isTV = screenWidth > 800 && Get.height > 500;
    final isWatch = screenWidth < 300;

    if (isWatch) {
      return _buildWatchPomodoroScreen(context);
    } else if (isTV) {
      return _buildTvPomodoroScreen(context);
    } else {
      return _buildMobilePomodoroScreen(context);
    }
  }

  Widget _simpleField(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    int? maxLen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        maxLines: maxLines,
        maxLength: maxLen,
      ),
    );
  }

  Widget _numericField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      maxLines: maxLines,
      validator: validator,
      textInputAction: maxLines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }
}
