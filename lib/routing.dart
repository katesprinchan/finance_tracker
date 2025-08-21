import 'package:finance_tracker/core/domain/container/app_container.dart';
import 'package:finance_tracker/features/analytics/presentation/page/analytics_page.dart';
//import 'package:finance_tracker/features/aboutApp/presentation/about_application.dart';
import 'package:finance_tracker/features/auth/presentation/auth_page.dart';
import 'package:finance_tracker/features/auth/presentation/auth_vm.dart';
import 'package:finance_tracker/features/auth/presentation/email_address_verification.dart';
import 'package:finance_tracker/features/categories/presentation/page/categorie_page.dart';
import 'package:finance_tracker/features/categories/presentation/page/categorie_vm.dart';
import 'package:finance_tracker/features/categories/presentation/page/categoriesEditPageDetail.dart';
import 'package:finance_tracker/features/categories/presentation/page/editing_categorie_page.dart';
/*import 'package:finance_tracker/features/cities/presentation/add_comment_page.dart';
import 'package:finance_tracker/features/cities/presentation/add_comment_vm.dart';
import 'package:finance_tracker/features/cities/presentation/cities_detail_pade.dart';
import 'package:finance_tracker/features/cities/presentation/cities_list_page.dart';
import 'package:finance_tracker/features/cities/presentation/cities_list_vm.dart';
import 'package:finance_tracker/features/cities/presentation/detail_page.dart';
import 'package:finance_tracker/features/cities/presentation/list_page.dart';
import 'package:finance_tracker/features/cities/presentation/no_connection_page.dart';
import 'package:finance_tracker/features/cities/presentation/place_favorite_page.dart';
import 'package:finance_tracker/features/cities/presentation/place_favorite_vm.dart';
import 'package:finance_tracker/features/cities/provider/favorite_provider.dart';
import 'package:finance_tracker/features/currency/presentation/currency_page.dart';
import 'package:finance_tracker/features/history/presentation/history_page.dart';*/
import 'package:finance_tracker/features/home/presentation/home_page.dart';
import 'package:finance_tracker/features/init/presentation/init_page.dart';
import 'package:finance_tracker/features/init/presentation/init_vm.dart';
import 'package:finance_tracker/features/operations/presentation/page/operations_page.dart';
import 'package:finance_tracker/features/profile/presentation/page/editing_profile_page.dart';
import 'package:finance_tracker/features/profile/presentation/page/profile_page.dart';
import 'package:finance_tracker/features/profile/presentation/page/profile_vm.dart';
import 'package:finance_tracker/features/recovery/presentation/forgot_password.dart';
import 'package:finance_tracker/features/recovery/presentation/password_reset.dart';
import 'package:finance_tracker/features/recovery/presentation/recovery_vm.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
//import 'package:finance_tracker/features/travelAgencies/presentation/travel_agencies_page.dart';
//import 'package:finance_tracker/features/weather/presentation/weather_page.dart';

abstract class AppRouteList {
  static const init = '/init';

  static const auth = '/auth';

  static const _emailAddressVerificationPagePath =
      'emailAddressVerificationPage';
  static const emailAddressVerificationPage =
      '$auth/$_emailAddressVerificationPagePath';

  static const _forgotPasswordPath = 'forgotPassword';
  static const forgotPassword = '$auth/$_forgotPasswordPath';

  static const _passwordResetPagePath = 'passwordResetPage';
  static const passwordResetPage = '$auth/$_passwordResetPagePath';

  static const operationListPage = '/operationListPage';
  static const categoriePage = '/categoriePage';
  static const _editingCategoriePagePath = '/editingCategoriePage';
  static const editingCategoriePage = _editingCategoriePagePath;

  static const _categoriesDetailPagePath = 'editingCategoriDetailePage';
  static const categoriesDetailPage =
      '$_editingCategoriePagePath/$_categoriesDetailPagePath';
  static const analyticPage = '/analyticPage';

  static const profilePage = '/profilePage';

  static const _editingProfilePagePath = 'editingProfilePage';
  static const editingProfilePage = '$profilePage/$_editingProfilePagePath';
}

abstract class AppRouterConfig {
  String name = '';
  static final instance = GoRouter(
    initialLocation: AppRouteList.init,
    routes: [
      GoRoute(
        path: AppRouteList.init,
        builder: (context, state) => const InitPage(
          vm: InitViewModel(),
        ),
      ),
      GoRoute(
        path: AppRouteList.auth,
        builder: (context, state) {
          return AuthPage(
            vm: AuthViewModel(
              settingService: AppContainer().serviceScope.settingsService,
            ),
          );
        },
        routes: [
          GoRoute(
            path: AppRouteList._emailAddressVerificationPagePath,
            builder: (context, state) => EmailAddressVerificationPage(
              vm: AuthViewModel(
                settingService: AppContainer().serviceScope.settingsService,
              ),
            ),
          ),
          GoRoute(
            path: AppRouteList._forgotPasswordPath,
            builder: (context, state) {
              return ForgotPasswordPage(
                vm: RecoveryViewModel(
                  authRepository: AppContainer().repositoryScope.authRepository,
                  settingService: AppContainer().serviceScope.settingsService,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRouteList._passwordResetPagePath,
            builder: (context, state) {
              return PasswordResetPage(
                vm: RecoveryViewModel(
                  authRepository: AppContainer().repositoryScope.authRepository,
                  settingService: AppContainer().serviceScope.settingsService,
                ),
              );
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomePage(
            vm: CategoryViewModel(
              settingService: AppContainer().serviceScope.settingsService,
            ),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            initialLocation: AppRouteList.categoriePage,
            routes: [
              GoRoute(
                path: AppRouteList.categoriePage,
                builder: (context, state) {
                  final vm = CategoryViewModel(
                    settingService: AppContainer().serviceScope.settingsService,
                  );

                  return ChangeNotifierProvider<CategoryViewModel>.value(
                    value: vm,
                    child: CategoriePage(
                      vm: vm,
                      settingsService:
                          AppContainer().serviceScope.settingsService,
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRouteList.operationListPage,
            routes: [
              GoRoute(
                  path: AppRouteList.operationListPage,
                  builder: (context, state) => OperationsPage(
                        vm: CategorieViewModel(
                          settingService:
                              AppContainer().serviceScope.settingsService,
                        ),
                      ),
                  routes: const []
                  /*
                  GoRoute(
                    path: AppRouteList._aboutApplicationPath,
                    builder: (context, state) => const AboutApplicationPage(),
                  ),
                  GoRoute(
                    path: AppRouteList._currencyPagePath,
                    builder: (context, state) => const CurrencyWebView(),
                  ),
                  GoRoute(
                    path: AppRouteList._historyPagePath,
                    builder: (context, state) => const HistoryPage(),
                  ),
                  GoRoute(
                    path: AppRouteList._travelAgenciesPagePath,
                    builder: (context, state) => const TravelAgenciesPage(),
                  ),
                  GoRoute(
                      path: AppRouteList._citiesDetailPagePath,
                      builder: (context, state) => CitiesDetailPage(
                            settingsService:
                                AppContainer().serviceScope.settingsService,
                          ),
                      routes: [
                        GoRoute(
                          path: AppRouteList._weatherPath,
                          builder: (context, state) => WeatherPage(
                            settingsService:
                                AppContainer().serviceScope.settingsService,
                          ),
                        ),
                        GoRoute(
                            path: AppRouteList._listPagePath,
                            builder: (context, state) => ChangeNotifierProvider(
                                  create: (context) => FavoriteProvider(),
                                  child: ListPage(
                                      settingsService: AppContainer()
                                          .serviceScope
                                          .settingsService),
                                ),
                            routes: [
                              GoRoute(
                                  path: AppRouteList._detailPagePath,
                                  builder: (context, state) => DetailPage(
                                      settingsService: AppContainer()
                                          .serviceScope
                                          .settingsService),
                                  routes: [
                                    GoRoute(
                                      path: AppRouteList._addCommentPagePath,
                                      builder: (context, state) =>
                                          AddCommentPage(
                                        vm: AddCommentViewModel(
                                          settingService: AppContainer()
                                              .serviceScope
                                              .settingsService,
                                        ),
                                      ),
                                    ),
                                  ]),
                            ]),
                      ]),
                ],*/
                  ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRouteList.analyticPage,
            routes: [
              GoRoute(
                path: AppRouteList.analyticPage,
                builder: (context, state) => AnalyticsPage(
                  vm: CategorieViewModel(
                    settingService: AppContainer().serviceScope.settingsService,
                  ),
                ),
                /* routes: [
                    GoRoute(
                        path: AppRouteList._detailPageFavoritePath,
                        builder: (context, state) => DetailPage(
                            settingsService:
                                AppContainer().serviceScope.settingsService),
                        routes: [
                          GoRoute(
                            path: AppRouteList._addCommentPageFavoritePath,
                            builder: (context, state) => AddCommentPage(
                              vm: AddCommentViewModel(
                                settingService:
                                    AppContainer().serviceScope.settingsService,
                              ),
                            ),
                          ),
                        ]),
                  ]),
                  */
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRouteList.profilePage,
            routes: [
              GoRoute(
                path: AppRouteList.profilePage,
                builder: (context, state) => ProfilePage(
                  vm: CategorieViewModel(
                    settingService: AppContainer().serviceScope.settingsService,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: AppRouteList._editingProfilePagePath,
                    builder: (context, state) => EditProfilePage(
                      vm: CategorieViewModel(
                        settingService:
                            AppContainer().serviceScope.settingsService,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRouteList._editingCategoriePagePath,
        builder: (context, state) {
          final vm = CategoryViewModel(
            settingService: AppContainer().serviceScope.settingsService,
          );
          return ChangeNotifierProvider.value(
            value: vm,
            child: CategoriesEditPage(
              vm: vm,
              settingsService: AppContainer().serviceScope.settingsService,
            ),
          );
        },
        routes: [
          GoRoute(
            path: AppRouteList._categoriesDetailPagePath,
            builder: (context, state) {
              return CategoriesEditPageDetail(
                vm: CategoryViewModel(
                  settingService: AppContainer().serviceScope.settingsService,
                ),
                settingsService: AppContainer().serviceScope.settingsService,
              );
            },
          ),
        ],
      ),
    ],
  );
}
