import 'package:focus_flow/modules/auth/auth_binding.dart';
import 'package:focus_flow/modules/auth/auth_config.dart';
import 'package:focus_flow/modules/auth/login_page.dart';
import 'package:focus_flow/modules/auth/signup_page.dart';
import 'package:focus_flow/modules/home/home_binding.dart';
import 'package:focus_flow/modules/home/home_page.dart';
import 'package:focus_flow/modules/notifications/notifications_binding.dart';
import 'package:focus_flow/modules/notifications/notifications_page.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_ana/pomodoro_binidng.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_ana/pomodoro_page.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_form.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_page.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_binidng.dart';
import 'package:focus_flow/modules/pomodoro/pomodoro_timer.dart';
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
    GetPage<void>(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      bindings: [AuthBinding()],
    ),
    GetPage<void>(
      name: AppRoutes.REGISTER,
      page: () => const RegisterScreen(),
      binding: AuthBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.HOME,
      page: () => const HomeScreen(),
      bindings: [HomeBinding(), AuthBinding(), NotificationBinding()],
    ),
    GetPage<void>(
      name: AppRoutes.PROJECTS_LIST,
      page: () => const ProjectsScreen(),
      bindings: [AuthBinding(), ProjectBinding(), NotificationBinding()],
    ),
    GetPage<void>(
      name: AppRoutes.PROJECT_FORM,
      page: () => const ProjectFormScreen(),
      bindings: [AuthBinding(), ProjectBinding(), NotificationBinding()],
    ),
    GetPage<void>(
      name: AppRoutes.TASKS_LIST,
      page: () => const TasksListScreen(),
      bindings: [AuthBinding(), ProjectBinding(), TaskBinding()],
    ),
    GetPage<void>(
      name: AppRoutes.TASK_FORM,
      page: () => const TaskFormScreen(),
      bindings: [AuthBinding(), ProjectBinding(), TaskBinding()],
    ),
    GetPage<void>(
      name: AppRoutes.NOTIFICATIONS_LIST,
      page: () => const NotificationListScreen(),
      bindings: [
        NotificationBinding(),
        AuthBinding(),
        TaskBinding(),
        ProjectBinding(),
      ],
    ),
    GetPage<void>(
      name: AppRoutes.USER_SETTINGS,
      page: () => UserSettingsScreen(),
      bindings: [AuthBinding()],
    ),
    GetPage<void>(
      name: AppRoutes.POMODORO_LIST,
      page: () => const PomodoroConfigListView(),
      bindings: [AuthBinding(), PomodoroBinidng()],
    ),
    GetPage<void>(
      name: AppRoutes.POMODORO_FORM,
      page: () => const PomodoroConfigFormScreen(),
      bindings: [AuthBinding(), PomodoroBinidng()],
    ),
    GetPage<void>(
      name: AppRoutes.POMODORO_TIMER,
      page: () => const PomodoroTimerScreen(),
      bindings: [AuthBinding(), PomodoroBinidng()],
    ),
    GetPage<void>(
      name: AppRoutes.POMODORO_LIST_ANA,
      page: () => const PomodoroConfigListViewAna(),
      bindings: [AuthBinding(), PomodoroBinidngAna()],
    ),
  ];
}
