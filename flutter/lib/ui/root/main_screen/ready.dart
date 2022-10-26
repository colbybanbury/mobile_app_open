import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:mlperfbench/app_constants.dart';
import 'package:mlperfbench/benchmark/state.dart';
import 'package:mlperfbench/localizations/app_localizations.dart';
import 'package:mlperfbench/store.dart';
import 'package:mlperfbench/ui/confirm_dialog.dart';
import 'package:mlperfbench/ui/error_dialog.dart';
import 'package:mlperfbench/ui/root/main_screen/utils.dart';
import 'package:mlperfbench/ui/run/app_bar.dart';

class MainScreenReadyKeys {
  // list of widget keys that need to be accessed in the test code
  static const String goButton = 'goButton';
}

class MainScreenReady extends StatelessWidget {
  const MainScreenReady({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BenchmarkState>();

    final utils = MainScreenUtils();

    final appBar = MyAppBar.buildAppBar(l10n.mainScreenTitle, context, true);
    final circle = _goContainer(context);

    return utils.wrapCircle(l10n, appBar, circle, context, state);
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
          // TODO (anhappdev): Uncomment the if line and remove the ignore line, when updated to Flutter v3.4.
          // See https://github.com/flutter/flutter/issues/111488
          // if (!context.mounted) return;
          // ignore: use_build_context_synchronously
          await showErrorDialog(context, [wrongPathError]);
          return;
        }
        if (store.offlineMode) {
          final offlineError = await state.validator
              .validateOfflineMode(stringResources.dialogContentOfflineWarning);
          if (offlineError.isNotEmpty) {
            // TODO (anhappdev): Uncomment the if line and remove the ignore line, when updated to Flutter v3.4.
            // See https://github.com/flutter/flutter/issues/111488
            // if (!context.mounted) return;
            // ignore: use_build_context_synchronously
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
          // TODO (anhappdev): Uncomment the if line and remove the ignore line, when updated to Flutter v3.4.
          // See https://github.com/flutter/flutter/issues/111488
          // if (!context.mounted) return;
          // ignore: use_build_context_synchronously
          await showErrorDialog(
              context, ['${stringResources.runFail}:', e.toString()]);
          return;
        }
      }),
    );
  }
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
        key: const Key(MainScreenReadyKeys.goButton),
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
