import 'package:drinkopedia/features/onboarding/domain/entities/taste_preference.dart';
import 'package:drinkopedia/features/onboarding/domain/repositories/taste_repository.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:flutter/foundation.dart';

/// Drives the taste intro, and holds the answer for the rest of the app.
///
/// App-scoped: the catalogue reads [categories] to decide what to show first,
/// so this outlives the intro screen itself.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({required this.repository});

  final TasteRepository repository;

  /// Total steps in the intro. Only the middle one collects anything.
  static const int stepCount = 3;

  TastePreference _preference = const TastePreference.untouched();
  bool get isComplete => _preference.completed;
  Set<SpiritCategory> get categories => _preference.categories;

  /// Whether the stored preference has actually been read yet.
  ///
  /// Distinct from [isComplete]: before [load] runs, "not answered" and "not
  /// yet known" look identical, and a router guard that conflates them sends a
  /// returning user through the intro again.
  bool _isResolved = false;
  bool get isResolved => _isResolved;

  int _step = 0;
  int get step => _step;
  bool get isLastStep => _step == stepCount - 1;

  final Set<SpiritCategory> _selection = <SpiritCategory>{};
  Set<SpiritCategory> get selection =>
      Set<SpiritCategory>.unmodifiable(_selection);
  bool isSelected(SpiritCategory category) => _selection.contains(category);

  Future<void> load() async {
    _preference = await repository.load();
    _isResolved = true;
    _selection
      ..clear()
      ..addAll(_preference.categories);
    notifyListeners();
  }

  void toggle(SpiritCategory category) {
    if (!_selection.add(category)) _selection.remove(category);
    notifyListeners();
  }

  void next() {
    if (isLastStep) return;
    _step++;
    notifyListeners();
  }

  void back() {
    if (_step == 0) return;
    _step--;
    notifyListeners();
  }

  /// Ends the intro, keeping whatever was picked.
  ///
  /// Skipping lands here too, with an empty selection: "asked and answered
  /// nothing" has to be distinguishable from "not asked", or the intro
  /// reappears on the next launch.
  Future<void> finish({bool skipped = false}) async {
    _preference = TastePreference(
      completed: true,
      categories: skipped
          ? const <SpiritCategory>{}
          : Set<SpiritCategory>.from(_selection),
    );
    notifyListeners();
    await repository.save(_preference);
  }
}
