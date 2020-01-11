import 'package:calendar_manager_example/presentation/main_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MainViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: buildBody(),
      ),
    );
  }

  Widget buildLoading() {
    return Center(
        child: CircularProgressIndicator(
      key: Key("loading"),
    ));
  }

  Widget buildBody() {
    return Builder(
      builder: (context) {
        final MainViewModel viewModel = Provider.of(context);
        if (viewModel.isLoading) {
          return buildLoading();
        }
        return Center(
          child: Text(
            'Running on: ${viewModel.version}\n',
            key: Key("version"),
          ),
        );
      },
    );
  }
}
