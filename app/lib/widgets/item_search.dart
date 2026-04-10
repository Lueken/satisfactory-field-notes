import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../theme/app_theme.dart';

class ItemSearch extends StatefulWidget {
  final List<GameItem> items;
  final ValueChanged<GameItem> onSelected;
  final String? initialValue;

  const ItemSearch({
    super.key,
    required this.items,
    required this.onSelected,
    this.initialValue,
  });

  @override
  State<ItemSearch> createState() => _ItemSearchState();
}

class _ItemSearchState extends State<ItemSearch> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<GameItem> _filtered = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  void _onChanged(String query) {
    if (query.length < 2) {
      setState(() => _showResults = false);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _filtered = widget.items
          .where((item) => item.name.toLowerCase().contains(lower))
          .take(8)
          .toList();
      _showResults = _filtered.isNotEmpty;
    });
  }

  void _select(GameItem item) {
    _controller.text = item.name;
    _focusNode.unfocus();
    setState(() => _showResults = false);
    widget.onSelected(item);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          style: TextStyle(fontSize: 16, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search items...',
            hintStyle: TextStyle(color: colors.textTertiary),
            prefixIcon: Icon(Icons.search, color: colors.textTertiary),
          ),
        ),
        if (_showResults)
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSecondary, width: 0.5),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final item = _filtered[i];
                return InkWell(
                  onTap: () => _select(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.liquid ? ficsitAmber : colors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
