import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'package:mlperfbench/benchmark/benchmark.dart';
import 'package:mlperfbench/benchmark/state.dart';
import 'package:mlperfbench/localizations/app_localizations.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({Key? key}) : super(key: key);

  @override
  State<ConfigScreen> createState() => _ConfigScreen();
}

class _ConfigScreen extends State<ConfigScreen> {
  late BenchmarkState state;
  late double pictureEdgeSize;

  @override
  void dispose() {
    state.saveTaskSelection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    state = context.watch<BenchmarkState>();
    pictureEdgeSize = 0.1 * MediaQuery.of(context).size.width;
    final stringResources = AppLocalizations.of(context);
    final childrenList = <Widget>[];

    for (var benchmark in state.benchmarks) {
      childrenList.add(_listTile(benchmark));
      childrenList.add(const Divider(height: 20));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          stringResources.benchConfigTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),
        children: childrenList,
      ),
    );
  }

  Widget _listTile(Benchmark benchmark) {
    return ListTile(
      leading: SizedBox(
          width: pictureEdgeSize,
          height: pictureEdgeSize,
          child: benchmark.info.icon),
      title: _name(benchmark),
      subtitle: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _description(benchmark),
          _delegateChoice(benchmark),
          _customModel(benchmark),
          _customImageHeight(benchmark),
          _customImageWidth(benchmark),
        ],
      ),
      trailing: _activeToggle(benchmark),
    );
  }

  Widget _name(Benchmark benchmark) {
    return Text(benchmark.info.taskName);
  }

  Widget _description(Benchmark benchmark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(benchmark.backendRequestDescription),
    );
  }

  Widget _activeToggle(Benchmark benchmark) {
    return Switch(
      value: benchmark.isActive,
      onChanged: (flag) {
        setState(() {
          benchmark.isActive = flag;
        });
      },
    );
  }

  Widget _delegateChoice(Benchmark benchmark) {
    final selected = benchmark.benchmarkSettings.delegateSelected;
    final choices = benchmark.benchmarkSettings.delegateChoice
        .map((e) => e.delegateName)
        .toList();
    if (choices.isEmpty) {
      return const SizedBox();
    }
    if (choices.length == 1 && choices.first.isEmpty) {
      return const SizedBox();
    }
    if (!choices.contains(selected)) {
      throw 'delegate_selected=$selected must be one of delegate_choice=$choices';
    }
    final dropDownButton = DropdownButton<String>(
        underline: const SizedBox(),
        value: selected,
        items: choices
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: (value) => setState(() {
              benchmark.benchmarkSettings.delegateSelected = value!;
            }));
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text('Delegate:'),
        const SizedBox(width: 4),
        dropDownButton,
      ],
    );
  }

  Widget _customModel(Benchmark benchmark) {
    final index = benchmark.benchmarkSettings.delegateChoice.indexWhere(
              (e) => e.delegateName == benchmark.benchmarkSettings.delegateSelected);


    final pickModel = () async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        // initialDirectory: ,
        lockParentWindow: true,
      );
      if (result == null) {
        return;
      }
      else{
      setState(() {
        benchmark.benchmarkSettings.delegateChoice[
          index].modelPath = result.files.single.path.toString();
      });
      }
    };

  return Row(
    children: [
      Expanded(
        child: Text(benchmark.benchmarkSettings.delegateChoice[index].modelPath),
      ),
      ElevatedButton(
        onPressed: pickModel,
        child: const Icon(Icons.folder),
      )
    ],
  );
  }

  Widget _customImageHeight(Benchmark benchmark) {
    final height = benchmark.taskConfig.model.imageHeight;

    return TextField(
              decoration: new InputDecoration(labelText: "Image Height: "+height.toString()),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
      ], // Only numbers can be entered
      onSubmitted: (String value) async { setState(() {
          benchmark.taskConfig.model.imageHeight = int.parse(value);
        });
      }
    );
  }

  Widget _customImageWidth(Benchmark benchmark) {
    final width = benchmark.taskConfig.model.imageWidth;

    return TextField(
      decoration: new InputDecoration(labelText: "Image Width: "+width.toString()),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly
      ], // Only numbers can be entered
      onSubmitted: (String value) async { setState(() {
          benchmark.taskConfig.model.imageWidth = int.parse(value);
        });
      }
    );
  }
    
}