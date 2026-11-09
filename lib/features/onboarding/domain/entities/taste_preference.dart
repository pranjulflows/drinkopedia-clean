import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:equatable/equatable.dart';

/// What the taste intro collected, and whether it has been through.
///
/// [categories] may be empty even when [completed] is true — skipping is a
/// legitimate answer, and it must be distinguishable from "not asked yet" or
/// the intro would reappear on every launch.
class TastePreference extends Equatable {
  const TastePreference({
    required this.completed,
    this.categories = const <SpiritCategory>{},
  });

  const TastePreference.untouched()
    : completed = false,
      categories = const <SpiritCategory>{};

  final bool completed;
  final Set<SpiritCategory> categories;

  @override
  List<Object?> get props => <Object?>[completed, categories];
}
