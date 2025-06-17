import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';

class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final screenHeight = Get.height;
    final isTV = screenWidth > 800 && screenHeight > 500;
    final isWatch = screenWidth < 320;
    final isTablet = Get.mediaQuery.size.shortestSide >= 600 && !isTV;

    if (isWatch) {
      return _buildWatchRegisterScreen(context);
    }

    return Scaffold(
      backgroundColor: isTV
          ? Colors.blueGrey[900]
          : Get.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Crear Cuenta',
          style: TextStyle(color: isTV ? Colors.white : null),
        ),
        backgroundColor: isTV
            ? Colors.blueGrey[800]
            : Get.theme.appBarTheme.backgroundColor,
        elevation: 4.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isTV ? Colors.white : null),
          onPressed: () {
            controller.clearRegisterFields();
            Get.back();
          },
        ),
      ),
      body: _buildFormBody(context, isTV, isTablet),
    );
  }

  Widget _buildFormBody(BuildContext context, bool isTV, bool isTablet) {
    final colorScheme = Get.theme.colorScheme;
    double logoSize = isTablet ? 120.0 : 100.0;
    EdgeInsetsGeometry padding = EdgeInsets.symmetric(
      horizontal: isTablet ? 40.0 : 24.0,
      vertical: isTablet ? 24.0 : 16.0,
    );
    double spacing = isTablet ? 22.0 : 18.0;
    double maxWidth = isTablet ? 500 : 400;

    if (isTV) {
      logoSize = 0;
      padding = const EdgeInsets.symmetric(horizontal: 80.0, vertical: 40.0);
      spacing = 25.0;
      maxWidth = 600;
    }

    final nameFocusNode = FocusNode();
    final emailFocusNode = FocusNode();
    final passwordFocusNode = FocusNode();
    final confirmPasswordFocusNode = FocusNode();

    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Form(
            key: controller.registerFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!isTV && logoSize > 0)
                  Icon(
                    Icons.person_add_alt_1,
                    size: logoSize,
                    color: GFColors.SUCCESS,
                  ),
                if (!isTV && logoSize > 0) SizedBox(height: spacing * 1.5),

                _buildFormField(
                  controller: controller.registerNameController,
                  focusNode: nameFocusNode,
                  nextFocusNode: emailFocusNode,
                  labelText: "Nombre Completo",
                  hintText: "Tu nombre",
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  isTV: isTV,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido.';
                    }
                    if (value.trim().length < 3) return 'Mínimo 3 caracteres.';
                    return null;
                  },
                ),
                SizedBox(height: spacing),

                _buildFormField(
                  controller: controller.registerEmailController,
                  focusNode: emailFocusNode,
                  nextFocusNode: passwordFocusNode,
                  labelText: "Correo Electrónico",
                  hintText: "tu.correo@ejemplo.com",
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  isTV: isTV,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El correo es requerido.';
                    }
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'Correo no válido.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: spacing),

                Obx(
                  () => _buildFormField(
                    controller: controller.registerPasswordController,
                    focusNode: passwordFocusNode,
                    nextFocusNode: confirmPasswordFocusNode,
                    labelText: "Contraseña",
                    hintText: "Crea una contraseña",
                    prefixIcon: Icons.lock_outline,
                    obscureText: !controller.registerPasswordVisible.value,
                    textInputAction: TextInputAction.next,
                    isTV: isTV,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.registerPasswordVisible.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isTV ? Colors.white70 : Colors.grey,
                      ),
                      onPressed: controller.toggleRegisterPasswordVisibility,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña es requerida.';
                      }
                      if (value.length < 6) return 'Mínimo 6 caracteres.';
                      return null;
                    },
                  ),
                ),
                SizedBox(height: spacing),

                Obx(
                  () => _buildFormField(
                    controller: controller.registerConfirmPasswordController,
                    focusNode: confirmPasswordFocusNode,
                    labelText: "Confirmar Contraseña",
                    hintText: "Vuelve a escribirla",
                    prefixIcon: Icons.lock_outline,
                    obscureText:
                        !controller.registerConfirmPasswordVisible.value,
                    textInputAction: TextInputAction.done,
                    isTV: isTV,
                    onFieldSubmitted: (_) => controller.register(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.registerConfirmPasswordVisible.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isTV ? Colors.white70 : Colors.grey,
                      ),
                      onPressed:
                          controller.toggleRegisterConfirmPasswordVisibility,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma la contraseña.';
                      }
                      if (value != controller.registerPasswordController.text) {
                        return 'Las contraseñas no coinciden.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: spacing * 1.5),

                Obx(
                  () => GFButton(
                    onPressed: controller.isRegisterLoading.value
                        ? null
                        : controller.registerWithFormValidation,
                    text: controller.isRegisterLoading.value
                        ? "Registrando..."
                        : "REGISTRARME",
                    icon: controller.isRegisterLoading.value
                        ? GFLoader(
                            type: GFLoaderType.ios,
                            size: GFSize.SMALL,
                            loaderColorOne: Colors.white,
                          )
                        : const Icon(Icons.person_add, color: Colors.white),
                    fullWidthButton: true,
                    size: GFSize.LARGE,
                    type: GFButtonType.solid,
                    shape: GFButtonShape.pills,
                    color: isTV ? colorScheme.secondary : GFColors.SUCCESS,
                    textColor: isTV
                        ? (Get.isDarkMode ? Colors.black : Colors.white)
                        : Colors.white,
                    buttonBoxShadow: isTV,
                    focusColor: isTV
                        ? colorScheme.secondary.withValues(alpha: 0.4)
                        : null,
                  ),
                ),
                SizedBox(height: spacing),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Ya tienes una cuenta?",
                      style: TextStyle(
                        color: isTV ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    GFButton(
                      onPressed: () {
                        controller.clearRegisterFields();
                        Get.offNamed(AppRoutes.LOGIN);
                      },
                      text: "INICIA SESIÓN",
                      type: GFButtonType.transparent,
                      textColor: isTV
                          ? colorScheme.secondary
                          : GFColors.PRIMARY,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchRegisterScreen(BuildContext context) {
    final emailFocusNode = FocusNode();
    final passwordFocusNode = FocusNode();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.registerFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Crear Cuenta",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildFormField(
                  controller: controller.registerEmailController,
                  focusNode: emailFocusNode,
                  nextFocusNode: passwordFocusNode,
                  labelText: "Email",
                  hintText: "tu@correo.com",
                  prefixIcon: null,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  isTV: false,
                  isWatch: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Correo requerido.';
                    }
                    if (!GetUtils.isEmail(value.trim())) return 'No válido.';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Obx(
                  () => _buildFormField(
                    controller: controller.registerPasswordController,
                    focusNode: passwordFocusNode,
                    labelText: "Contraseña",
                    hintText: "Mín. 6 car.",
                    prefixIcon: null,
                    obscureText: !controller.registerPasswordVisible.value,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) =>
                        controller.registerWithFormValidation(),
                    isTV: false,
                    isWatch: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerida.';
                      if (value.length < 6) return 'Mín. 6.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Obx(
                  () => GFButton(
                    onPressed: controller.isRegisterLoading.value
                        ? null
                        : controller.registerWithFormValidation,
                    text: controller.isRegisterLoading.value
                        ? "..."
                        : "REGISTRAR",
                    size: GFSize.MEDIUM,
                    type: GFButtonType.solid,
                    shape: GFButtonShape.pills,
                    color: GFColors.SUCCESS,
                  ),
                ),
                const SizedBox(height: 10),
                GFButton(
                  onPressed: () {
                    controller.clearRegisterFields();
                    Get.offNamed(AppRoutes.LOGIN);
                  },
                  text: "Ya tengo cuenta",
                  type: GFButtonType.outline,
                  size: GFSize.SMALL,
                  textColor: Colors.white70,
                  color: Colors.white38,
                  shape: GFButtonShape.pills,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    required bool isTV,
    bool isWatch = false,
  }) {
    final colorScheme = Get.theme.colorScheme;
    final textTheme = Get.textTheme;

    InputDecoration decoration;
    TextStyle? style;
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    );

    if (isTV) {
      style = textTheme.titleMedium?.copyWith(color: Colors.white);
      contentPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 22);
      decoration = InputDecoration(
        labelText: labelText,
        labelStyle: textTheme.titleMedium?.copyWith(color: Colors.white70),
        hintText: hintText,
        hintStyle: textTheme.titleMedium?.copyWith(color: Colors.white54),
        filled: true,
        fillColor: Colors.blueGrey[800],
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.white70)
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blueGrey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blueGrey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.secondary, width: 2),
        ),
        contentPadding: contentPadding,
      );
    } else if (isWatch) {
      style = const TextStyle(color: Colors.white, fontSize: 14);
      contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
      decoration = InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.grey[800],
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.white70, size: 18)
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: GFColors.SUCCESS, width: 1.5),
        ),
        contentPadding: contentPadding,
        isDense: true,
      );
    } else {
      style = textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface);
      decoration = InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: colorScheme.onSurfaceVariant)
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: GFColors.SUCCESS, width: 2),
        ),
        contentPadding: contentPadding,
      );
    }

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      style: style,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      cursorColor: isTV
          ? colorScheme.secondary
          : (isWatch ? GFColors.SUCCESS : colorScheme.primary),
      onFieldSubmitted:
          onFieldSubmitted ??
          (nextFocusNode != null
              ? (_) => FocusScope.of(Get.context!).requestFocus(nextFocusNode)
              : null),
      validator: validator,
    );
  }
}
