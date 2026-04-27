import 'package:flutter/material.dart';

class DynamicListField extends StatelessWidget {
  final String title;
  final List<TextEditingController> controllers;
  final String hintText;
  final String addLabel;
  final bool required;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const DynamicListField({
    super.key,
    required this.title,
    required this.controllers,
    required this.hintText,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[index],
                    validator: (value) {
                      if (required && controllers.length == 1) {
                        if (value == null || value.trim().isEmpty) {
                          return '$title is required';
                        }
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: controllers.length == 1 ? null : () => onRemove(index),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(addLabel),
        ),
      ],
    );
  }
}
