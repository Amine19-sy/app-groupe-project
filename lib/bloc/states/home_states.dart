import 'package:equatable/equatable.dart';
import 'package:smart_box/services/box_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeEmpty extends HomeState {
  const HomeEmpty();
}

class HomeLoaded extends HomeState {
  final List<Box> boxes;

  const HomeLoaded({required this.boxes});

  @override
  List<Object?> get props => [boxes];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}
