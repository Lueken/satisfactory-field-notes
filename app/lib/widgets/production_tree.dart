import 'package:flutter/material.dart';
import '../models/production_node.dart';
import '../theme/app_theme.dart';

String _fmtRate(double rate) =>
    rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : rate.toStringAsFixed(1);

String _fmtCount(double count) =>
    count == count.roundToDouble() ? count.toStringAsFixed(0) : count.toStringAsFixed(2);

/// Flatten a node and all descendants into a list of (node, depth) pairs.
List<({ProductionNode node, int depth})> _flattenWithDepth(
    ProductionNode node, int depth) {
  final list = <({ProductionNode node, int depth})>[];
  list.add((node: node, depth: depth));
  for (final child in node.children) {
    list.addAll(_flattenWithDepth(child, depth + 1));
  }
  return list;
}

class ProductionTree extends StatelessWidget {
  final ProductionNode root;
  final int beltRate;
  final void Function(ProductionNode node)? onEditOverclock;

  const ProductionTree({
    super.key,
    required this.root,
    this.beltRate = 0,
    this.onEditOverclock,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _RootHeader(node: root, beltRate: beltRate, onEdit: onEditOverclock),
        for (final child in root.children)
          _SubFactorySection(
            root: child,
            beltRate: beltRate,
            onEditOverclock: onEditOverclock,
          ),
      ],
    );
  }
}

class _RootHeader extends StatelessWidget {
  final ProductionNode node;
  final int beltRate;
  final void Function(ProductionNode node)? onEdit;
  const _RootHeader({required this.node, this.beltRate = 0, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit != null && !node.isRawResource
            ? () => onEdit!(node)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ficsitAmber.withValues(alpha: 0.08),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_fmtCount(node.rate)} ${node.itemName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (node.machineName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${node.machineName} (x${_fmtCount(node.machineCount)})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ficsitAmber,
                      ),
                    ),
                    if (node.overclock != 100) ...[
                      const SizedBox(width: 8),
                      _ClockBadge(clock: node.overclock),
                    ],
                  ],
                ),
                Text(
                  '${node.itemName} (${_fmtRate(node.rate)}/min)',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ],
              if (beltRate > 0) _BeltWarning(rate: node.rate, beltRate: beltRate),
              if (node.totalTreePower > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 14, color: ficsitAmber),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmtRate(node.totalTreePower)} MW total',
                      style: const TextStyle(fontSize: 13, color: ficsitAmber),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockBadge extends StatelessWidget {
  final double clock;
  const _ClockBadge({required this.clock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ficsitAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${clock.toStringAsFixed(0)}%',
        style: const TextStyle(fontSize: 11, color: ficsitAmber),
      ),
    );
  }
}

class _BeltWarning extends StatelessWidget {
  final double rate;
  final int beltRate;
  const _BeltWarning({required this.rate, required this.beltRate});

  @override
  Widget build(BuildContext context) {
    if (rate <= beltRate) return const SizedBox.shrink();
    final beltsNeeded = (rate / beltRate).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: 12, color: Color(0xFFD97706)),
          const SizedBox(width: 4),
          Text(
            'needs $beltsNeeded belts',
            style: const TextStyle(fontSize: 11, color: Color(0xFFD97706)),
          ),
        ],
      ),
    );
  }
}

class _SubFactorySection extends StatefulWidget {
  final ProductionNode root;
  final int beltRate;
  final void Function(ProductionNode node)? onEditOverclock;

  const _SubFactorySection({
    required this.root,
    this.beltRate = 0,
    this.onEditOverclock,
  });

  @override
  State<_SubFactorySection> createState() => _SubFactorySectionState();
}

class _SubFactorySectionState extends State<_SubFactorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final node = widget.root;
    final hasChildren = node.children.isNotEmpty;
    final chain = _flattenWithDepth(node, 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header: machine name (collapsible, long-press to edit)
        GestureDetector(
          onTap: hasChildren
              ? () => setState(() => _expanded = !_expanded)
              : null,
          onLongPress: widget.onEditOverclock != null && !node.isRawResource
              ? () => widget.onEditOverclock!(node)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: hasChildren
                      ? Icon(
                          _expanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 18,
                          color: const Color(0xFF9CA3AF),
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _MachineItemBlock(
                    node: node,
                    isSectionHeader: true,
                    beltRate: widget.beltRate,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Flattened children
        if (_expanded)
          for (final entry in chain.skip(1))
            GestureDetector(
              onLongPress: widget.onEditOverclock != null &&
                      !entry.node.isRawResource
                  ? () => widget.onEditOverclock!(entry.node)
                  : null,
              child: Container(
                padding: EdgeInsets.only(
                  left: 40 + (entry.depth * 16.0),
                  right: 16,
                  top: 6,
                  bottom: 6,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAF9),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF0EFED), width: 0.5),
                  ),
                ),
                child: _MachineItemBlock(
                  node: entry.node,
                  isSectionHeader: false,
                  beltRate: widget.beltRate,
                ),
              ),
            ),
      ],
    );
  }
}

/// Displays a node as: Machine (xN) on top, then item name + rate below.
/// Raw resources show just the item name in amber (no machine).
class _MachineItemBlock extends StatelessWidget {
  final ProductionNode node;
  final bool isSectionHeader;
  final int beltRate;

  const _MachineItemBlock({
    required this.node,
    required this.isSectionHeader,
    this.beltRate = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (node.isRawResource) {
      // Raw resource: just item name + rate
      return Row(
        children: [
          Expanded(
            child: Text(
              node.itemName,
              style: TextStyle(
                fontSize: isSectionHeader ? 14 : 13,
                color: ficsitAmber,
                fontWeight:
                    isSectionHeader ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${_fmtRate(node.rate)}/min',
            style: TextStyle(
              fontSize: isSectionHeader ? 13 : 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      );
    }

    // Machine + item
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '${node.machineName ?? "?"} (x${_fmtCount(node.machineCount)})',
                style: TextStyle(
                  fontSize: isSectionHeader ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: isSectionHeader
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
            if (node.overclock != 100) ...[
              const SizedBox(width: 6),
              _ClockBadge(clock: node.overclock),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${node.itemName} (${_fmtRate(node.rate)}/min)',
          style: TextStyle(
            fontSize: isSectionHeader ? 13 : 12,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        if (beltRate > 0)
          _BeltWarning(rate: node.rate, beltRate: beltRate),
      ],
    );
  }
}
