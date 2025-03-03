import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:mlperfbench/app_constants.dart';
import 'package:mlperfbench/benchmark/state.dart';
import 'package:mlperfbench/localizations/app_localizations.dart';
import 'package:mlperfbench/store.dart';
import 'package:mlperfbench/ui/confirm_dialog.dart';
import 'package:mlperfbench/ui/error_dialog.dart';
import 'package:mlperfbench/ui/icons.dart';
import 'package:mlperfbench/ui/run/app_bar.dart';
import 'package:mlperfbench/ui/run/list_of_benchmark_items.dart';
import 'package:mlperfbench/ui/run/progress_screen.dart';
import 'package:mlperfbench/ui/run/result_screen.dart';
import 'resource_error_screen.dart';

class MainKeys {
  // list of widget keys that need to be accessed in the test code
  static const String goButton = 'goButton';
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BenchmarkState>();
    final stringResources = AppLocalizations.of(context);

    if (state.taskConfigFailedToLoad) {
      return const ResourceErrorScreen();
    }

    PreferredSizeWidget? appBar;

    switch (state.state) {
      case BenchmarkStateEnum.downloading:
      case BenchmarkStateEnum.waiting:
        appBar = MainScreenAppBar.buildAppBar(
            stringResources.mainScreenTitle, context, true);
        break;
      case BenchmarkStateEnum.aborting:
        appBar = MainScreenAppBar.buildAppBar(
            stringResources.mainScreenTitle, context, false);
        break;
      case BenchmarkStateEnum.running:
        return const ProgressScreen();
      case BenchmarkStateEnum.done:
        return const ResultScreen();
    }

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(flex: 6, child: _getContainer(context, state.state)),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                stringResources.mainScreenMeasureTitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.darkText,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Align(
                  alignment: Alignment.topCenter,
                  child: createListOfBenchmarkItemsWidgets(context, state)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getContainer(BuildContext context, BenchmarkStateEnum state) {
    if (state == BenchmarkStateEnum.aborting) {
      return _waitContainer(context);
    }

    if (state == BenchmarkStateEnum.waiting) {
      return _goContainer(context);
    }

    return _downloadContainer(context);
  }

  Widget _waitContainer(BuildContext context) {
    final stringResources = AppLocalizations.of(context);

    return _circleContainerWithContent(
        context, AppIcons.waiting, stringResources.mainScreenWaitFinish);
  }

  Widget _goContainer(BuildContext context) {
    final state = context.watch<BenchmarkState>();
    final store = context.watch<Store>();
    final stringResources = AppLocalizations.of(context);

    return CustomPaint(
      painter: MyPaintBottom(),
      child: GoButtonGradient(() async {
        // TODO (anhappdev) Refactor the code here to avoid duplicated code.
        // The checks before calling state.runBenchmarks() in main_screen and result_screen are similar.
        final wrongPathError = await state.validator
            .validateExternalResourcesDirectory(
                stringResources.dialogContentMissingFiles);
        if (wrongPathError.isNotEmpty) {
          // Workaround for Dart linter bug. See https://github.com/dart-lang/linter/issues/4007
          // ignore: use_build_context_synchronously
          if (!context.mounted) return;
          await showErrorDialog(context, [wrongPathError]);
          return;
        }
        if (store.offlineMode) {
          final offlineError = await state.validator
              .validateOfflineMode(stringResources.dialogContentOfflineWarning);
          if (offlineError.isNotEmpty) {
            // Workaround for Dart linter bug. See https://github.com/dart-lang/linter/issues/4007
            // ignore: use_build_context_synchronously
            if (!context.mounted) return;
            switch (await showConfirmDialog(context, offlineError)) {
              case ConfirmDialogAction.ok:
                break;
              case ConfirmDialogAction.cancel:
                return;
              default:
                break;
            }
          }
        }
        try {
          await state.runBenchmarks();
        } catch (e, t) {
          print(t);
          // Workaround for Dart linter bug. See https://github.com/dart-lang/linter/issues/4007
          // ignore: use_build_context_synchronously
          if (!context.mounted) return;
          await showErrorDialog(
              context, ['${stringResources.runFail}:', e.toString()]);
          return;
        }
      }),
    );
  }

  Widget _downloadContainer(BuildContext context) {
    final stringResources = AppLocalizations.of(context);
    final textLabel = Text(context.watch<BenchmarkState>().downloadingProgress,
        style: const TextStyle(color: AppColors.lightText, fontSize: 40));

    return _circleContainerWithContent(
        context, textLabel, stringResources.mainScreenLoading);
  }
}

class MyPaintBottom extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomLeft,
        colors: AppColors.mainScreenGradient,
      ).createShader(rect);
    canvas.drawArc(rect, 0, pi, true, paint);
  } // paint

  @override
  bool shouldRepaint(MyPaintBottom oldDelegate) => false;
}

class GoButtonGradient extends StatelessWidget {
  final AsyncCallback onPressed;

  const GoButtonGradient(this.onPressed, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stringResources = AppLocalizations.of(context);

    var decoration = BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: AppColors.runBenchmarkCircleGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(15, 15),
          blurRadius: 10,
        )
      ],
    );

    return Container(
      decoration: decoration,
      width: MediaQuery.of(context).size.width * 0.35,
      child: MaterialButton(
        key: const Key(MainKeys.goButton),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        splashColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: onPressed,
        child: Text(
          stringResources.mainScreenGo,
          style: const TextStyle(
            color: AppColors.lightText,
            fontSize: 40,
          ),
        ),
      ),
    );
  }
}

Widget _circleContainerWithContent(
    BuildContext context, Widget contentInCircle, String label) {
  return CustomPaint(
    painter: MyPaintBottom(),
    child: Stack(alignment: Alignment.topCenter, children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.lightText, fontSize: 15),
        ),
      ),
      Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.35,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.progressCircle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(15, 15),
                  blurRadius: 10,
                )
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.35,
            alignment: Alignment.center,
            child: contentInCircle,
          )
        ],
      )
    ]),
  );
}
