import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:focus_flow/modules/auth/auth_controller.dart';
import 'package:focus_flow/routes/app_routes.dart';

enum DeviceType { watch, phone, tablet, tv }

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  DeviceType get deviceType {
    final width = Get.width;
    final height = Get.height;
    if (width < 320) return DeviceType.watch;
    if (width > 800 && height > 500) return DeviceType.tv;
    if (Get.mediaQuery.size.shortestSide >= 600) return DeviceType.tablet;
    return DeviceType.phone;
  }

  @override
  Widget build(BuildContext context) {
    switch (deviceType) {
      case DeviceType.watch:
        return _buildWatchLoginScreen(context);
      default:
        return Scaffold(
          backgroundColor: deviceType == DeviceType.tv
              ? Colors.blueGrey[900]
              : Get.theme.scaffoldBackgroundColor,
          body: _buildFormBody(context),
        );
    }
  }

  Widget _buildFormBody(BuildContext context) {
    final colorScheme = Get.theme.colorScheme;
    final textTheme = Get.textTheme;
    final emailFocusNode = FocusNode();
    final passwordFocusNode = FocusNode();
    final loginButtonFocusNode = FocusNode();

    final config = _LayoutConfig.fromDevice(deviceType, colorScheme, textTheme);

    return Center(
      child: SingleChildScrollView(
        padding: config.padding ?? EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: config.maxWidth),
          child: Form(
            key: controller.loginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.task_alt,
                  size: config.logoSize,
                  color: config.iconColor ?? GFColors.PRIMARY,
                ),
                _gap(config.spacing * 1.5),
                Text(
                  "Iniciar Sesión",
                  textAlign: TextAlign.center,
                  style: config.titleStyle ?? const TextStyle(fontSize: 20),
                ),
                _gap(config.spacing),

                _buildFormField(
                  controller: controller.loginEmailController,
                  focusNode: emailFocusNode,
                  nextFocusNode: passwordFocusNode,
                  labelText: "Correo Electrónico",
                  hintText: "tu.correo@ejemplo.com",
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),

                _gap(config.spacing * 0.75),

                Obx(
                  () => _buildFormField(
                    controller: controller.loginPasswordController,
                    focusNode: passwordFocusNode,
                    nextFocusNode: deviceType == DeviceType.tv
                        ? loginButtonFocusNode
                        : null,
                    labelText: "Contraseña",
                    hintText: "Tu contraseña",
                    prefixIcon: Icons.lock_outline,
                    obscureText: !controller.loginPasswordVisible.value,
                    textInputAction: deviceType == DeviceType.tv
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: deviceType == DeviceType.tv
                        ? null
                        : (_) => controller.loginWithFormValidation(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.loginPasswordVisible.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: config.iconColor ?? Colors.grey,
                      ),
                      onPressed: controller.toggleLoginPasswordVisibility,
                    ),
                    validator: _validatePassword,
                  ),
                ),

                _gap(config.spacing * 0.5),

                Align(
                  child: GFButton(
                    onPressed: () => _showForgotPasswordDialog(context, config),
                    text: "Olvidé mi contraseña",
                    type: GFButtonType.transparent,
                    textColor: config.textColor ?? Colors.black,
                    size: GFSize.MEDIUM,
                  ),
                ),

                _gap(config.spacing),

                Obx(
                  () => GFButton(
                    onPressed: controller.isLoginLoading.value
                        ? null
                        : controller.loginWithFormValidation,
                    text: controller.isLoginLoading.value
                        ? "Ingresando..."
                        : "INGRESAR",
                    icon: controller.isLoginLoading.value
                        ? GFLoader(type: GFLoaderType.ios, size: GFSize.SMALL)
                        : const Icon(Icons.login, color: Colors.white),
                    fullWidthButton: true,
                    size: GFSize.LARGE,
                    type: GFButtonType.solid,
                    shape: GFButtonShape.pills,
                    color: config.buttonColor ?? Colors.blue,
                    textColor: config.buttonTextColor ?? Colors.white,
                  ),
                ),

                _gap(config.spacing * 1.5),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿No tienes una cuenta?",
                      style:
                          config.captionStyle ??
                          const TextStyle(color: Colors.grey),
                    ),
                    GFButton(
                      onPressed: () {
                        controller.clearLoginFields();
                        Get.toNamed(AppRoutes.REGISTER);
                      },
                      text: "REGÍSTRATE",
                      type: GFButtonType.transparent,
                      textColor: config.linkColor ?? Colors.green,
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Watch login form (reducido)",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _gap(double h) => SizedBox(height: h);

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
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey)
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted:
          onFieldSubmitted ??
          (nextFocusNode != null
              ? (_) => FocusScope.of(Get.context!).requestFocus(nextFocusNode)
              : null),
      validator: validator,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Correo requerido.';
    if (!GetUtils.isEmail(value.trim())) return 'Correo no válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Contraseña requerida.';
    return null;
  }

  void _showForgotPasswordDialog(BuildContext context, _LayoutConfig config) {
    final email = controller.loginEmailController.text.trim();
    final TextEditingController resetEmailController = TextEditingController(
      text: email,
    );
    final resetFocus = FocusNode();

    Get.defaultDialog(
      title: "Restablecer Contraseña",
      titleStyle: TextStyle(fontWeight: FontWeight.bold),
      content: Column(
        children: [
          Text("Ingresa tu correo para enviarte un enlace."),
          _gap(10),
          _buildFormField(
            controller: resetEmailController,
            focusNode: resetFocus,
            labelText: "Correo Electrónico",
            hintText: "ejemplo@email.com",
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: _validateEmail,
            onFieldSubmitted: (_) {
              controller.resetPassword(resetEmailController.text.trim());
              if (Get.isDialogOpen ?? false) Get.back();
            },
          ),
        ],
      ),
      confirm: GFButton(
        onPressed: () {
          if (GetUtils.isEmail(resetEmailController.text.trim())) {
            controller.resetPassword(resetEmailController.text.trim());
            Get.back();
          }
        },
        text: "ENVIAR",
      ),
      cancel: GFButton(
        onPressed: () => Get.back(),
        text: "CANCELAR",
        type: GFButtonType.outline,
      ),
    );
  }
}

class _LayoutConfig {
  final double logoSize;
  final EdgeInsetsGeometry? padding;
  final TextStyle? titleStyle;
  final double spacing;
  final double maxWidth;
  final Color? iconColor;
  final Color? textColor;
  final Color? buttonColor;
  final Color? buttonTextColor;
  final Color? linkColor;
  final TextStyle? captionStyle;
  final EdgeInsets? buttonPadding;

  _LayoutConfig({
    required this.logoSize,
    required this.padding,
    required this.titleStyle,
    required this.spacing,
    required this.maxWidth,
    this.iconColor,
    this.textColor,
    this.buttonColor,
    this.buttonTextColor,
    this.linkColor,
    this.captionStyle,
    this.buttonPadding,
  });

  factory _LayoutConfig.fromDevice(
    DeviceType type,
    ColorScheme cs,
    TextTheme ts,
  ) {
    switch (type) {
      case DeviceType.tv:
        return _LayoutConfig(
          logoSize: 180,
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 50),
          titleStyle: ts.displaySmall?.copyWith(color: Colors.white),
          spacing: 30,
          maxWidth: 600,
          iconColor: Colors.white70,
          textColor: Colors.white70,
          buttonColor: cs.primary,
          buttonTextColor: Colors.black,
          linkColor: cs.secondary,
          captionStyle: const TextStyle(color: Colors.white70),
          buttonPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        );
      case DeviceType.tablet:
        return _LayoutConfig(
          logoSize: 150,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          titleStyle: ts.headlineLarge,
          spacing: 25,
          maxWidth: 500,
        );
      default:
        return _LayoutConfig(
          logoSize: 120,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          titleStyle: ts.headlineMedium,
          spacing: 20,
          maxWidth: 400,
        );
    }
  }
}
