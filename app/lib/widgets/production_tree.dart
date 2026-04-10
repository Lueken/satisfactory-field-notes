import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Set<String> collapsedSections;
  final void Function(String itemClassName) onToggleSection;

  const ProductionTree({
    super.key,
    required this.root,
    this.beltRate = 0,
    this.onEditOverclock,
    this.collapsedSections = const {},
    required this.onToggleSection,
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
            expanded: !collapsedSections.contains(child.itemClassName),
            onToggle: () => onToggleSection(child.itemClassName),
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
    final colors = AppColors.of(context);
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
            border: Border(
              bottom: BorderSide(color: colors.borderSecondary, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_fmtCount(node.rate)} ${node.itemName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
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
                  style:
                      TextStyle(fontSize: 13, color: colors.textTertiary),
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
    const warnColor = Color(0xFFD97706);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: 12, color: warnColor),
          const SizedBox(width: 4),
          Text(
            'needs $beltsNeeded belts',
            style: const TextStyle(fontSize: 11, color: warnColor),
          ),
        ],
      ),
    );
  }
}

class _SubFactorySection extends StatelessWidget {
  final ProductionNode root;
  final int beltRate;
  final void Function(ProductionNode node)? onEditOverclock;
  final bool expanded;
  final VoidCallback onToggle;

  const _SubFactorySection({
    required this.root,
    this.beltRate = 0,
    this.onEditOverclock,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final node = root;
    final hasChildren = node.children.isNotEmpty;
    final chain = _flattenWithDepth(node, 0);
    final colors = AppColors.of(context);

    void toggle() {
      HapticFeedback.lightImpact();
      onToggle();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header: machine name (collapsible)
        GestureDetector(
          onTap: hasChildren ? toggle : null,
          onLongPress: onEditOverclock != null && !node.isRawResource
              ? () => onEditOverclock!(node)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.borderSecondary, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: hasChildren
                      ? Icon(
                          expanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 18,
                          color: colors.textTertiary,
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _MachineItemBlock(
                    node: node,
                    isSectionHeader: true,
                    beltRate: beltRate,
                  ),
                ),
                if (onEditOverclock != null && !node.isRawResource)
                  IconButton(
                    icon: Icon(Icons.tune, size: 16,
                        color: node.overclock != 100
                            ? ficsitAmber
                            : colors.textTertiary),
                    tooltip: 'Overclock',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => onEditOverclock!(node),
                  ),
              ],
            ),
          ),
        ),

        // Flattened children
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeInOut,
          crossFadeState:
              expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in chain.skip(1))
                GestureDetector(
                  onLongPress: onEditOverclock != null &&
                          !entry.node.isRawResource
                      ? () => onEditOverclock!(entry.node)
                      : null,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 40 + (entry.depth * 16.0),
                      right: 16,
                      top: 6,
                      bottom: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.rowAltBg,
                      border: Border(
                        bottom: BorderSide(
                            color: colors.rowAltBorder, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MachineItemBlock(
                            node: entry.node,
                            isSectionHeader: false,
                            beltRate: beltRate,
                          ),
                        ),
                        if (onEditOverclock != null &&
                            !entry.node.isRawResource &&
                            !entry.node.isSupplied)
                          IconButton(
                            icon: Icon(Icons.tune,
                                size: 14,
                                color: entry.node.overclock != 100
                                    ? ficsitAmber
                                    : colors.textTertiary),
                            tooltip: 'Overclock',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            onPressed: () => onEditOverclock!(entry.node),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
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
    final colors = AppColors.of(context);

    if (node.isSupplied) {
      const suppliedColor = Color(0xFF3B82F6);
      const warnColor = Color(0xFFD97706);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.input, size: 12, color: suppliedColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  node.itemName,
                  style: TextStyle(
                    fontSize: isSectionHeader ? 14 : 13,
                    color: suppliedColor,
                    fontWeight: isSectionHeader
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                'needs ${_fmtRate(node.rate)}/min',
                style:
                    TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Text(
              'supplied ${_fmtRate(node.suppliedAmount)}/min',
              style:
                  TextStyle(fontSize: 11, color: colors.textTertiary),
            ),
          ),
          if (node.shortfall > 0)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      size: 12, color: warnColor),
                  const SizedBox(width: 4),
                  Text(
                    'shortfall: ${_fmtRate(node.shortfall)}/min',
                    style: const TextStyle(
                        fontSize: 11, color: warnColor),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    if (node.isRawResource) {
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
              color: colors.textTertiary,
            ),
          ),
        ],
      );
    }

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
                      ? colors.textPrimary
                      : colors.textSecondary,
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
            color: colors.textTertiary,
          ),
        ),
        if (beltRate > 0)
          _BeltWarning(rate: node.rate, beltRate: beltRate),
      ],
    );
  }
}
