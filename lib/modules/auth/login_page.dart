import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = Get.width;
    final screenHeight = Get.height;
    final isTV = screenWidth > 800 && screenHeight > 500;
    final isWatch = screenWidth < 320;
    final isTablet = Get.mediaQuery.size.shortestSide >= 600 && !isTV;

    if (isWatch) {
      return _buildWatchLoginScreen(context);
    }

    return Scaffold(
      backgroundColor: isTV
          ? Colors.blueGrey[900]
          : Get.theme.scaffoldBackgroundColor,
      body: _buildFormBody(context, isTV, isTablet),
    );
  }

  Widget _buildFormBody(BuildContext context, bool isTV, bool isTablet) {
    final colorScheme = Get.theme.colorScheme;
    double logoSize = isTablet ? 150.0 : 120.0;
    EdgeInsetsGeometry padding = EdgeInsets.symmetric(
      horizontal: isTablet ? 40.0 : 24.0,
      vertical: isTablet ? 24.0 : 16.0,
    );
    TextStyle? titleStyle = isTablet
        ? Get.textTheme.headlineLarge
        : Get.textTheme.headlineMedium;
    double spacing = isTablet ? 25.0 : 20.0;
    double maxWidth = isTablet ? 500 : 400;

    if (isTV) {
      logoSize = 180.0;
      padding = const EdgeInsets.symmetric(horizontal: 80.0, vertical: 50.0);
      titleStyle = Get.textTheme.displaySmall?.copyWith(color: Colors.white);
      spacing = 30.0;
      maxWidth = 600;
    }

    final emailFocusNode = FocusNode();
    final passwordFocusNode = FocusNode();
    final loginButtonFocusNode = FocusNode();

    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Form(
            key: controller.loginFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.task_alt,
                  size: logoSize,
                  color: isTV ? Colors.white70 : GFColors.PRIMARY,
                ),
                SizedBox(height: spacing * 1.5),

                Text(
                  "Iniciar Sesión",
                  textAlign: TextAlign.center,
                  style: titleStyle?.copyWith(
                    color: isTV ? Colors.white : titleStyle.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing),

                _buildFormField(
                  controller: controller.loginEmailController,
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
                      return 'Correo requerido.';
                    }
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'Correo no válido.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: spacing * 0.75),

                Obx(
                  () => _buildFormField(
                    controller: controller.loginPasswordController,
                    focusNode: passwordFocusNode,
                    nextFocusNode: isTV ? loginButtonFocusNode : null,
                    labelText: "Contraseña",
                    hintText: "Tu contraseña",
                    prefixIcon: Icons.lock_outline,
                    obscureText: !controller.loginPasswordVisible.value,
                    textInputAction: isTV
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: isTV
                        ? null
                        : (_) => controller.loginWithFormValidation(),
                    isTV: isTV,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.loginPasswordVisible.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isTV ? Colors.white70 : Colors.grey,
                      ),
                      onPressed: controller.toggleLoginPasswordVisibility,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Contraseña requerida.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: spacing * 0.5),

                Align(
                  alignment: isTV ? Alignment.center : Alignment.centerRight,
                  child: GFButton(
                    onPressed: () => _showForgotPasswordDialog(
                      context,
                      controller,
                      isTV: isTV,
                    ),
                    text: "Olvidé mi contraseña",
                    type: GFButtonType.transparent,
                    textColor: isTV ? Colors.white70 : colorScheme.primary,
                    size: isTV ? GFSize.LARGE : GFSize.MEDIUM,
                    padding: isTV
                        ? const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          )
                        : const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                  ),
                ),
                SizedBox(height: spacing),

                Obx(
                  () => GFButton(
                    focusNode: isTV ? loginButtonFocusNode : null,
                    onPressed: controller.isLoginLoading.value
                        ? null
                        : controller.loginWithFormValidation,
                    text: controller.isLoginLoading.value
                        ? "Ingresando..."
                        : "INGRESAR",
                    icon: controller.isLoginLoading.value
                        ? GFLoader(
                            type: GFLoaderType.ios,
                            size: GFSize.SMALL,
                            loaderColorOne: Colors.white,
                          )
                        : const Icon(Icons.login, color: Colors.white),
                    fullWidthButton: true,
                    size: GFSize.LARGE,
                    type: GFButtonType.solid,
                    shape: GFButtonShape.pills,
                    color: isTV ? colorScheme.primary : GFColors.PRIMARY,
                    textColor: isTV
                        ? (Get.isDarkMode ? Colors.black : Colors.white)
                        : Colors.white,
                    buttonBoxShadow: isTV,
                    focusColor: isTV
                        ? colorScheme.primary.withValues(alpha: 0.4)
                        : null,
                  ),
                ),
                SizedBox(height: spacing * 1.5),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿No tienes una cuenta?",
                      style: TextStyle(
                        color: isTV ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    GFButton(
                      onPressed: () {
                        controller.clearLoginFields();
                        Get.toNamed(AppRoutes.REGISTER);
                      },
                      text: "REGÍSTRATE",
                      type: GFButtonType.transparent,
                      textColor: isTV
                          ? colorScheme.secondary
                          : GFColors.SUCCESS,
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

  Widget _buildWatchLoginScreen(BuildContext context) {
    final emailFocusNode = FocusNode();
    final passwordFocusNode = FocusNode();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.loginFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  size: 50,
                  color: GFColors.PRIMARY.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 10),
                const Text(
                  "FocusFlow",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  controller: controller.loginEmailController,
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
                      return 'Requerido.';
                    }
                    if (!GetUtils.isEmail(value.trim())) return 'No válido.';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Obx(
                  () => _buildFormField(
                    controller: controller.loginPasswordController,
                    focusNode: passwordFocusNode,
                    labelText: "Contraseña",
                    hintText: "Contraseña",
                    prefixIcon: null,
                    obscureText: !controller.loginPasswordVisible.value,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) =>
                        controller.loginWithFormValidation(),
                    isTV: false,
                    isWatch: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerida.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Obx(
                  () => GFButton(
                    onPressed: controller.isLoginLoading.value
                        ? null
                        : controller.loginWithFormValidation,
                    text: controller.isLoginLoading.value ? "..." : "INGRESAR",
                    size: GFSize.MEDIUM,
                    type: GFButtonType.solid,
                    shape: GFButtonShape.pills,
                    color: GFColors.PRIMARY,
                  ),
                ),
                const SizedBox(height: 10),
                GFButton(
                  onPressed: () {
                    controller.clearLoginFields();
                    Get.toNamed(AppRoutes.REGISTER);
                  },
                  text: "Crear cuenta",
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
    Color focusColor = isTV
        ? colorScheme.primary
        : (isWatch ? GFColors.PRIMARY : colorScheme.primary);

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
          borderSide: BorderSide(color: focusColor, width: 2),
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
          borderSide: BorderSide(color: focusColor, width: 1.5),
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
          borderSide: BorderSide(color: focusColor, width: 2),
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
      cursorColor: focusColor,
      onFieldSubmitted:
          onFieldSubmitted ??
          (nextFocusNode != null
              ? (_) => FocusScope.of(Get.context!).requestFocus(nextFocusNode)
              : null),
      validator: validator,
    );
  }

  void _showForgotPasswordDialog(
    BuildContext context,
    AuthController controller, {
    required bool isTV,
  }) {
    final TextEditingController resetEmailController = TextEditingController(
      text: controller.loginEmailController.text,
    );
    final FocusNode resetEmailFocusNode = FocusNode();
    final colorScheme = Get.theme.colorScheme;

    Get.defaultDialog(
      title: "Restablecer Contraseña",
      titleStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isTV ? Colors.white : null,
      ),
      backgroundColor: isTV ? Colors.blueGrey[800] : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Ingresa tu correo para enviarte un enlace de restablecimiento.",
            style: TextStyle(color: isTV ? Colors.white70 : null),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildFormField(
            controller: resetEmailController,
            focusNode: resetEmailFocusNode,
            labelText: "Correo Electrónico",
            hintText: "tu.correo@ejemplo.com",
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            isTV: isTV,
            onFieldSubmitted: (_) {
              controller.resetPassword(resetEmailController.text.trim());
              if (Get.isDialogOpen ?? false) Get.back();
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Correo requerido.';
              }
              if (!GetUtils.isEmail(value.trim())) return 'Correo no válido.';
              return null;
            },
          ),
        ],
      ),
      confirm: GFButton(
        onPressed: () {
          if (GetUtils.isEmail(resetEmailController.text.trim())) {
            controller.resetPassword(resetEmailController.text.trim());
            Get.back();
          } else {
            Get.snackbar(
              "Error",
              "Por favor, ingresa un correo válido.",
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
              snackPosition: isTV ? SnackPosition.TOP : SnackPosition.BOTTOM,
            );
          }
        },
        text: "ENVIAR ENLACE",
        fullWidthButton: true,
        color: isTV ? colorScheme.primary : GFColors.PRIMARY,
        textColor: isTV
            ? (Get.isDarkMode ? Colors.black : Colors.white)
            : Colors.white,
      ),
      cancel: GFButton(
        onPressed: () => Get.back(),
        text: "CANCELAR",
        type: GFButtonType.outline,
        fullWidthButton: true,
        textColor: isTV ? Colors.white70 : null,
        buttonBoxShadow: false,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (resetEmailFocusNode.canRequestFocus) {
        FocusScope.of(context).requestFocus(resetEmailFocusNode);
      }
    });
  }
}
