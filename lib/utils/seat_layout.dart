import 'package:flutter/material.dart';

import '../models/member.dart';
import '../viewmodels/house_seating_viewmodel.dart' show HouseType;
import 'party_tokens.dart';

/// Computes normalized (0–1) seat positions for an authentic UK Parliament chamber layout.
///
/// Chamber geometry:
/// - Left: Speaker's Chair (Commons) / Woolsack & Throne (Lords), Clerk's Table & Mace.
/// - Top (Y = 0.08..0.40): Government Benches (Treasury Bench on front row).
/// - Bottom (Y = 0.60..0.92): Opposition Benches (Shadow Cabinet on front row).
/// - Middle (Y = 0.40..0.60): Central Floor / Aisle with red carpet lines.
/// - Right (X = 0.84..0.94): Crossbenches (in the House of Lords).
List<Offset> buildChamberLayout({
  required HouseType house,
  required List<Member> members,
}) {
  if (members.isEmpty) return const [];

  final positions = <int, Offset>{};

  // 1. Classify members
  final speakers = <Member>[];
  final governments = <Member>[];
  final crossbenchers = <Member>[];
  final oppositions = <Member>[];

  for (final m in members) {
    final token = canonicalPartyToken(
          m.partyAbbreviation.isNotEmpty ? m.partyAbbreviation : m.party,
        ) ??
        '';
    if (token == 'speaker') {
      speakers.add(m);
    } else if (token == 'labour') {
      governments.add(m);
    } else if (house == HouseType.lords && token == 'crossbench') {
      crossbenchers.add(m);
    } else {
      oppositions.add(m);
    }
  }

  // 2. Position Speaker / Lord Speaker
  if (speakers.isNotEmpty) {
    positions[speakers[0].id] = const Offset(0.08, 0.50);
    for (var i = 1; i < speakers.length; i++) {
      positions[speakers[i].id] = Offset(0.08, 0.50 + (i * 0.03));
    }
  }

  // 3. Position Government (Top Benches: Y = 0.10, 0.17, 0.24, 0.31, 0.38)
  const govRowsY = [0.38, 0.31, 0.24, 0.17, 0.10]; // Row 0 is Front Bench (Treasury)
  const double govXStartLeft = 0.22;
  final double govXEndLeft = house == HouseType.commons ? 0.54 : 0.48;
  final double govXStartRight = house == HouseType.commons ? 0.60 : 0.54;
  final double govXEndRight = house == HouseType.commons ? 0.92 : 0.80;

  final govRowCounts = _distributeSeats(governments.length, 5, [0, 1, 2, 3, 4]);
  var govIndex = 0;
  for (var r = 0; r < 5; r++) {
    final count = govRowCounts[r];
    final y = govRowsY[r];
    if (count <= 0) continue;

    final leftCount = (count / 2).ceil();
    final rightCount = count - leftCount;

    // Left block
    for (var i = 0; i < leftCount; i++) {
      final t = leftCount == 1 ? 0.5 : (i + 0.5) / leftCount;
      final x = govXStartLeft + (govXEndLeft - govXStartLeft) * t;
      if (govIndex < governments.length) {
        positions[governments[govIndex++].id] = Offset(x, y);
      }
    }
    // Right block
    for (var i = 0; i < rightCount; i++) {
      final t = rightCount == 1 ? 0.5 : (i + 0.5) / rightCount;
      final x = govXStartRight + (govXEndRight - govXStartRight) * t;
      if (govIndex < governments.length) {
        positions[governments[govIndex++].id] = Offset(x, y);
      }
    }
  }

  // 4. Position Opposition (Bottom Benches: Y = 0.62, 0.69, 0.76, 0.83, 0.90)
  const oppRowsY = [0.62, 0.69, 0.76, 0.83, 0.90]; // Row 0 is Front Bench (Shadow Cabinet)
  const double oppXStartLeft = 0.22;
  final double oppXEndLeft = house == HouseType.commons ? 0.54 : 0.48;
  final double oppXStartRight = house == HouseType.commons ? 0.60 : 0.54;
  final double oppXEndRight = house == HouseType.commons ? 0.92 : 0.80;

  final oppRowCounts = _distributeSeats(oppositions.length, 5, [0, 1, 2, 3, 4]);
  var oppIndex = 0;
  for (var r = 0; r < 5; r++) {
    final count = oppRowCounts[r];
    final y = oppRowsY[r];
    if (count <= 0) continue;

    final leftCount = (count / 2).ceil();
    final rightCount = count - leftCount;

    // Left block
    for (var i = 0; i < leftCount; i++) {
      final t = leftCount == 1 ? 0.5 : (i + 0.5) / leftCount;
      final x = oppXStartLeft + (oppXEndLeft - oppXStartLeft) * t;
      if (oppIndex < oppositions.length) {
        positions[oppositions[oppIndex++].id] = Offset(x, y);
      }
    }
    // Right block
    for (var i = 0; i < rightCount; i++) {
      final t = rightCount == 1 ? 0.5 : (i + 0.5) / rightCount;
      final x = oppXStartRight + (oppXEndRight - oppXStartRight) * t;
      if (oppIndex < oppositions.length) {
        positions[oppositions[oppIndex++].id] = Offset(x, y);
      }
    }
  }

  // 5. Position Crossbenchers (Lords only, Right Side perpendicular)
  if (house == HouseType.lords && crossbenchers.isNotEmpty) {
    final cbColsX = [0.83, 0.86, 0.89, 0.92];
    final cbColCounts = _distributeSeats(crossbenchers.length, 4, [0, 1, 2, 3]);
    var cbIndex = 0;
    for (var c = 0; c < 4; c++) {
      final count = cbColCounts[c];
      final x = cbColsX[c];
      if (count <= 0) continue;

      for (var i = 0; i < count; i++) {
        final t = count == 1 ? 0.5 : (i + 0.5) / count;
        final y = 0.22 + (0.78 - 0.22) * t;
        if (cbIndex < crossbenchers.length) {
          positions[crossbenchers[cbIndex++].id] = Offset(x, y);
        }
      }
    }
  }

  return [
    for (final m in members) positions[m.id] ?? const Offset(0.5, 0.5),
  ];
}

List<int> _distributeSeats(int total, int parts, List<int> preferredOrder) {
  final base = total ~/ parts;
  final counts = List<int>.filled(parts, base);
  final remainder = total % parts;
  for (var i = 0; i < remainder; i++) {
    counts[preferredOrder[i % preferredOrder.length]]++;
  }
  return counts;
}

/// Legacy hemicycle builder kept for backward compatibility.
List<Offset> buildHemicycleLayout(int seatCount) {
  if (seatCount <= 0) return const [];
  return List.generate(seatCount, (i) => const Offset(0.5, 0.5));
}
