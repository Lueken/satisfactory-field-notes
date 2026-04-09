import 'package:flutter/material.dart';
import '../models/production_node.dart';
import '../theme/app_theme.dart';

String _fmtRate(double rate) =>
    rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : rate.toStringAsFixed(1);

/// Flatten a node's entire chain into a list (pre-order, the node itself first).
List<ProductionNode> _flatten(ProductionNode node) {
  final list = [node];
  for (final child in node.children) {
    list.addAll(_flatten(child));
  }
  return list;
}

class ProductionTree extends StatelessWidget {
  final ProductionNode root;

  const ProductionTree({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Root item header
        _RootHeader(node: root),
        // Each direct child is a collapsible sub-factory chain
        for (final child in root.children) _SubFactorySection(root: child),
      ],
    );
  }
}

/// The top-level target item.
class _RootHeader extends StatelessWidget {
  final ProductionNode node;
  const _RootHeader({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ficsitAmber.withValues(alpha: 0.08),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (node.machineName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ficsitAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${node.machineName} x${node.machineCountCeil}',
                style: const TextStyle(fontSize: 11, color: ficsitAmber),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              node.itemName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Text(
            '${_fmtRate(node.rate)}/min',
            style: const TextStyle(fontSize: 14, color: ficsitAmber),
          ),
        ],
      ),
    );
  }
}

/// A collapsible section for one input chain.
/// The header is the direct child (e.g. "Iron Plate").
/// The body is the flattened chain underneath it.
class _SubFactorySection extends StatefulWidget {
  final ProductionNode root;
  const _SubFactorySection({required this.root});

  @override
  State<_SubFactorySection> createState() => _SubFactorySectionState();
}

class _SubFactorySectionState extends State<_SubFactorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final node = widget.root;
    final hasChildren = node.children.isNotEmpty;
    // Flatten the chain below this node (not including the node itself)
    final chain = <ProductionNode>[];
    for (final child in node.children) {
      chain.addAll(_flatten(child));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (the direct input item)
        GestureDetector(
          onTap: hasChildren ? () => setState(() => _expanded = !_expanded) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          _expanded ? Icons.expand_more : Icons.chevron_right,
                          size: 18,
                          color: const Color(0xFF9CA3AF),
                        )
                      : Icon(
                          Icons.circle,
                          size: 6,
                          color: node.isRawResource
                              ? ficsitAmber.withValues(alpha: 0.5)
                              : const Color(0xFFD6D3D1),
                        ),
                ),
                const SizedBox(width: 6),
                if (!node.isRawResource && node.machineName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${node.machineName} x${node.machineCountCeil}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    node.itemName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasChildren ? FontWeight.w500 : FontWeight.normal,
                      color: node.isRawResource ? ficsitAmber : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Text(
                  '${_fmtRate(node.rate)}/min',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),

        // Flattened chain items (shown when expanded)
        if (_expanded)
          for (final item in chain)
            Container(
              padding: const EdgeInsets.only(left: 42, right: 16, top: 8, bottom: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAF9),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF0EFED), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  if (!item.isRawResource && item.machineName != null) ...[
                    Text(
                      '${item.machineName} x${item.machineCountCeil}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 13,
                        color: item.isRawResource ? ficsitAmber : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  Text(
                    '${_fmtRate(item.rate)}/min',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
