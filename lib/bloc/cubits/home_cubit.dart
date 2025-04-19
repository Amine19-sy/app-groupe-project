import 'package:bloc/bloc.dart';
import 'package:smart_box/bloc/box_model.dart';
import 'package:smart_box/bloc/states/home_states.dart';
import 'package:smart_box/backend/Item_Box.dart';

class HomeCubit extends Cubit<HomeState> {
  final String userId;
  final ItemBoxService boxService;

  HomeCubit({
    required this.userId,
    required this.boxService,
  }) : super(const HomeInitial());

  Future<void> fetchUserBoxes() async {
    emit(const HomeLoading());
    try {
      // Récupère tous les boxes
      final allBoxes = await boxService.getAllBoxes();

      // Filtre ceux de l'utilisateur
      final userBoxes = allBoxes
          .where((box) => box["user_id"].toString() == userId)
          .map((box) => Box.fromJson(box))
          .toList();

      if (userBoxes.isEmpty) {
        emit(const HomeEmpty());
      } else {
        emit(HomeLoaded(boxes: userBoxes));
      }
    } catch (e) {
      emit(HomeError(message: 'Failed to fetch boxes: $e'));
    }
  }
}
