import 'package:focus_flow/modules/auth/auth_binding.dart';
import 'package:focus_flow/modules/auth/login_page.dart';
import 'package:focus_flow/modules/auth/signup_page.dart';
import 'package:focus_flow/modules/home/home_binding.dart';
import 'package:focus_flow/modules/home/home_page.dart';
import 'package:focus_flow/modules/notifications/notifications_binding.dart';
import 'package:focus_flow/modules/notifications/notifications_page.dart';
import 'package:focus_flow/modules/projects/project_binding.dart';
import 'package:focus_flow/modules/projects/project_form_page.dart';
import 'package:focus_flow/modules/projects/project_page.dart';
import 'package:focus_flow/modules/tasks/task_binding.dart';
import 'package:focus_flow/modules/tasks/task_form_page.dart';
import 'package:focus_flow/modules/tasks/task_list_page.dart';

import 'app_routes.dart';
import 'package:get/get.dart';

class AppPages {
  static const INITIAL = AppRoutes.SPLASH;

  static final routes = [
    // GetPage(
    //   name: Routes.SPLASH,
    //   page: () => SplashScreen(),
    //   binding: InitialBinding(),
    // ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => RegisterScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => HomeScreen(),
      bindings: [HomeBinding(), AuthBinding(), NotificationBinding()],
    ),
    GetPage(
      name: AppRoutes.PROJECTS_LIST,
      page: () => ProjectsScreen(),
      bindings: [
        AuthBinding(),
        ProjectBinding(),
        NotificationBinding(),
      ], // Aseguramos que HomeBinding esté presente
    ),
    GetPage(
      name: AppRoutes.PROJECT_FORM,
      page: () => ProjectFormScreen(),
      bindings: [
        AuthBinding(),
        ProjectBinding(),
      ], // Aseguramos que HomeBinding esté presente
    ),
    GetPage(
      name: AppRoutes.TASKS_LIST,
      page: () => TasksListScreen(),
      bindings: [
        AuthBinding(),
        ProjectBinding(),
        TaskBinding(), // Aseguramos que HomeBinding esté presente
      ],
    ),
    GetPage(
      name: AppRoutes.TASK_FORM,
      page: () => TaskFormScreen(),
      bindings: [
        AuthBinding(),
        ProjectBinding(),
        TaskBinding(), // Aseguramos que HomeBinding esté presente
      ],
    ),
    GetPage(
      name: AppRoutes.NOTIFICATIONS_LIST,
      page: () => const NotificationListScreen(),
      bindings: [
        NotificationBinding(),
        AuthBinding(),
        TaskBinding(),
        ProjectBinding(),
      ], // Crear este binding
    ),
  ];
}
