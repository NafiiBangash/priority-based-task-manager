import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_manager/screens/home_screen.dart';
import 'package:task_manager/ffi/task_manager_service.dart';
import 'package:task_manager/utils/utils.dart';
import 'package:task_manager/widgets/gradient_background.dart';
import 'package:task_manager/widgets/text_field_widget.dart';
import '../utils/size_config.dart';

class AddTaskScreen extends StatefulWidget {
  final String? taskId;
  final String? existingName;
  final String? existingDescription;
  final int? existingPriority;

  const AddTaskScreen(
      {super.key,
      this.taskId,
      this.existingName,
      this.existingDescription,
      this.existingPriority});

  @override
  // ignore: library_private_types_in_public_api
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priorityController;
  final TaskManagerService _taskService = TaskManagerService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingName ?? "");
    _descriptionController =
        TextEditingController(text: widget.existingDescription ?? "");
    _priorityController =
        TextEditingController(text: widget.existingPriority?.toString() ?? "");
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      String? userId =
          FirebaseAuth.instance.currentUser?.uid; //Get logged-in user ID
      if (userId == null) return; //Prevent saving task if no user is logged in

      String name = _nameController.text.trim();
      String description = _descriptionController.text.trim();
      int priority = int.tryParse(_priorityController.text.trim()) ?? 0;

      if (widget.taskId == null) {
        //Adding a new task
        int id =
            DateTime.now().millisecondsSinceEpoch; //Generate unique numeric ID
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(id.toString()) //Store task under user ID
            .set({
          'id': id,
          'name': name,
          'description': description,
          'priority': priority,
          'timestamp': FieldValue.serverTimestamp(),
        });

        //Call C++ backend via FFI (TaskManagerService)
        _taskService.addTask(id, name, description, priority);
        Utils().showSuccessToast("Task Successfully Added!");
      } else {
        //Updating an existing task
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(widget.taskId)
            .update({
          'name': name,
          'description': description,
          'priority': priority,
        });

        //Call C++ backend via FFI for update (if needed)
        int taskId = int.tryParse(widget.taskId!) ?? 0;
        _taskService.updateTask(taskId, name, description, priority);
        Utils().showSuccessToast("Task Updated Successfully!");
      }

      //Navigate back to `HomeScreen` after saving
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    MySize().init(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MySize.screenHeight,
          child: Stack(
            children: [
              // Gradient Background
              const GradientBackground(),
              Align(
                alignment: Alignment.center,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Glass effect
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.taskId == null ? "Add Task" : "Edit Task",
                            style: GoogleFonts.montserrat(
                              fontSize: MySize.size28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 📌 Task Name Input
                          TextFormFieldWidget(
                            label: 'Task Name',
                            controller: _nameController,
                            iconData: Icons.title,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Task Name is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // Description Input
                          TextFormFieldWidget(label: 'Description', controller: _descriptionController,
                              iconData: Icons.description,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Description is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // Priority Input
                          TextFormFieldWidget(label: 'Priority (1-10)', controller: _priorityController,
                              iconData: Icons.priority_high,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Priority is required";
                              }
                              int? priority = int.tryParse(value);
                              if (priority == null ||
                                  priority < 1 ||
                                  priority > 10) {
                                return "Priority must be between 1 and 5";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Animated Save Button
                          ElevatedButton(
                            onPressed: _saveTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                            child: Text(
                              widget.taskId == null ? "Add Task" : "Update Task",
                              style: GoogleFonts.montserrat(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ❌ Cancel Button
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
