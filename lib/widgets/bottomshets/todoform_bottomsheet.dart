import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_trells/Utilities/helpers.dart';
import 'package:task_trells/Controllers/todo_controller.dart';
import 'package:task_trells/widgets/bottomshets/todoformConfig_model.dart';
import 'package:task_trells/widgets/priority.dart';

class TodoFormBottomSheet extends StatefulWidget {
  final TodoFormConfig config;

  const TodoFormBottomSheet({super.key, required this.config});

  @override
  _TodoFormBottomSheetState createState() => _TodoFormBottomSheetState();
}

class _TodoFormBottomSheetState extends State<TodoFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  // Declare controllers and focus nodes at the class level
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _descriptionFocusNode;

  late final TodoController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and focus nodes in initState
    _controller = Get.find<TodoController>();
    _titleController = TextEditingController(text: widget.config.initialTitle);
    _descriptionController = TextEditingController(
      text: widget.config.initialDescription,
    );
    _titleFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Dispose of all controllers and focus nodes
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.only(
              bottom: 70,
              left: 16,
              right: 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: Get.theme.canvasColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.config.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    focusNode: _titleFocusNode, // Attach focus node
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    focusNode: _descriptionFocusNode, // Attach focus node
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => SizedBox(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Priority: ${_controller.priority.value?.toString().split('.').last.capitalizeFirst ?? 'None'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PriorityDropdown(),
                          Expanded(
                            child: Text(
                              'Scheduled for: ${formatDate(_controller.scheduleAt.value)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // Unfocus text fields before opening the date picker
                              FocusScope.of(context).unfocus();
                              _controller.pickDateTime(context).then((_) {
                                // Refocus the title field after picking date/time
                                // FocusScope.of(context).requestFocus(_titleFocusNode);
                                _titleFocusNode.unfocus();
                                _descriptionFocusNode.unfocus();
                              });
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Schedule'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reminder: ${formatReminderDate(_controller.reminderTime.value)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (widget.config.showReminderCancelButton &&
                            _controller.reminderTime.value != null)
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            onPressed: () {
                              _controller.reminderTime.value = null;
                            },
                          ),
                        TextButton.icon(
                          onPressed: () {
                            // Unfocus text fields before showing reminder options
                            FocusScope.of(context).unfocus();
                            _controller
                                .showReminderOptions(
                                  context,
                                  initialDate: _controller.scheduleAt.value,
                                )
                                .then((_) {
                                  // Refocus the title field after setting reminder
                                  // FocusScope.of(context).requestFocus(_titleFocusNode);
                                  _titleFocusNode.unfocus();
                                  _descriptionFocusNode.unfocus();
                                });
                          },
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('Set Reminder'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Unfocus text fields and then navigate back
                          FocusScope.of(context).unfocus();
                          _controller.scheduleAt.value = null;
                          _controller.reminderTime.value = null;
                          Get.back();
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (_controller.reminderTime.value != null &&
                                _controller.reminderTime.value!.isBefore(
                                  DateTime.now(),
                                )) {
                              Get.snackbar(
                                'Action Blocked 🚫',
                                'Cannot save with a reminder time in the past.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            // Unfocus text fields and then save
                            FocusScope.of(context).unfocus();
                            widget.config.onSave(
                              _titleController.text,
                              _descriptionController.text,
                            );
                          }
                        },
                        child: Text(widget.config.saveButtonText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
