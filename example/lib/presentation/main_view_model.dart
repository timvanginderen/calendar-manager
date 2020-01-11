import 'package:calendar_manager_example/services/calendar_service.dart';
import 'package:flutter/material.dart';

class ViewModel extends ChangeNotifier {}

abstract class MainViewModel implements ViewModel {
  bool get isLoading;
  String get version;

  factory MainViewModel() => MainViewModelImpl(CalendarService());
}

class MainViewModelImpl extends ViewModel implements MainViewModel {
  @override
  String version;
  @override
  bool isLoading;

  final CalendarService calendarService;

  MainViewModelImpl(this.calendarService) {
    load();
  }

  load() async {
    isLoading = true;
    notifyListeners();
    version = await calendarService.fetchVersion();
    isLoading = false;
    notifyListeners();
  }
}
