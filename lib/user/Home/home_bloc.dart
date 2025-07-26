import 'package:flutter_bloc/flutter_bloc.dart';

/// EVENTS
abstract class HomeEvent {}

class LoadPosts extends HomeEvent {}

/// STATE
class HomeState {
  final List<Map<String, String>> posts;
  HomeState(this.posts);
}

/// BLOC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeState([])) {
    on<LoadPosts>((event, emit) {
      emit(HomeState([
        {
          'name': 'John Player',
          'time': '2h',
          'content': 'Practicing hard for the next tournament!',
          'image': 'https://via.placeholder.com/400'
        },
        {
          'name': 'Coach Mike',
          'time': '5h',
          'content': 'Training sessions available for U-14 players.',
          'image': 'https://via.placeholder.com/400'
        },
      ]));
    });
  }
}
