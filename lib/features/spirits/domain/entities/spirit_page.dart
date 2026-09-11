import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:equatable/equatable.dart';

/// One page of the catalogue, and where the next one starts.
///
/// [nextOffset] counts catalogue *entries consumed*, not [items] returned. The
/// two differ whenever an entry fails to resolve upstream, and paging on the
/// returned count would re-request the same failing entry forever.
class SpiritPage extends Equatable {
  const SpiritPage({
    required this.items,
    required this.nextOffset,
    required this.total,
  });

  final List<Spirit> items;
  final int nextOffset;

  /// Size of the whole catalogue, known before any page is fetched.
  final int total;

  bool get hasMore => nextOffset < total;

  @override
  List<Object?> get props => <Object?>[items, nextOffset, total];
}
