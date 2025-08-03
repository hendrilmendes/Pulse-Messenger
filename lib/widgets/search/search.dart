import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social/l10n/app_localizations.dart';

class SearchBarWidget extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const SearchBarWidget({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
    _controller.addListener(() {
      widget.onSearchChanged(_controller.text);
    });
  }

  void _clearText() {
    _controller.clear();
    widget.onSearchChanged('');
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              inputFormatters: [
                // Permite letras e espaços
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Capitaliza a primeira letra de cada palavra
                  final text = newValue.text;
                  final newText = text.isEmpty
                      ? ''
                      : text.split(' ').map((word) {
                          if (word.isNotEmpty) {
                            return word[0].toUpperCase() +
                                word.substring(1).toLowerCase();
                          }
                          return '';
                        }).join(' ');
                  return newValue.copyWith(text: newText);
                }),
              ],
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchFor,
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearText,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
