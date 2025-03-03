import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mlperfbench/app_constants.dart';
import 'package:mlperfbench/benchmark/state.dart';
import 'package:mlperfbench/firebase/firebase_manager.dart';
import 'package:mlperfbench/localizations/app_localizations.dart';

enum _ShareDestination { local, cloud }

class ShareButton extends StatefulWidget {
  const ShareButton({Key? key}) : super(key: key);

  @override
  State<ShareButton> createState() => _ShareButton();
}

class _ShareButton extends State<ShareButton> {
  late BenchmarkState state;
  late AppLocalizations l10n;
  bool _isSharing = false;
  String _shareStatus = '';

  @override
  Widget build(BuildContext context) {
    state = context.watch<BenchmarkState>();
    l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildShareButton(context),
          const SizedBox(height: 16.0),
          _isSharing ? _buildProgressIndicator() : Container(),
          const SizedBox(height: 16.0),
          Text(_shareStatus),
        ],
      ),
    );
  }

  void _handleSharing(_ShareDestination destination) async {
    final resultManager = state.resourceManager.resultManager;
    switch (destination) {
      case _ShareDestination.local:
        final filePath = resultManager.getSubmissionFile().path;
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: l10n.shareButtonOtherSubject,
        );
        break;
      case _ShareDestination.cloud:
        setState(() {
          _isSharing = true;
        });
        final result = resultManager.getLastResult();
        await FirebaseManager.instance.uploadResult(result);
        setState(() {
          _isSharing = false;
          _shareStatus = l10n.uploadSuccess;
        });
        break;
      default:
        throw Exception('Unknown destination: $destination');
    }
  }

  Widget _buildShareButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleSharing(_ShareDestination.local);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.share),
                        const SizedBox(width: 20),
                        Text(
                          l10n.shareButtonOther,
                          style: TextStyle(
                            color: AppColors.shareTextButton,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: !FirebaseManager.enabled
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            _handleSharing(_ShareDestination.cloud);
                          },
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_upload),
                        const SizedBox(width: 20),
                        Text(
                          l10n.shareButtonMLCommons,
                          style: TextStyle(
                            color: AppColors.shareTextButton,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Text(
        l10n.resultsButtonShare,
        style: TextStyle(
          color: AppColors.shareTextButton,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
    );
  }
}
