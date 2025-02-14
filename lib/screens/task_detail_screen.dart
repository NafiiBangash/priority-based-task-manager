import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_manager/ffi/task_manager_service.dart';
import 'package:task_manager/widgets/gradient_background.dart';
import '../utils/size_config.dart';
import 'add_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String name;
  final String description;
  final int priority;

  const TaskDetailScreen({super.key,
    required this.taskId,
    required this.name,
    required this.description,
    required this.priority,
  });

  @override
  // ignore: library_private_types_in_public_api
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskManagerService _taskService = TaskManagerService();

  @override
  Widget build(BuildContext context) {
    void deleteTask(String taskId) async {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return; //Prevent deletion if no user is logged in

      DocumentSnapshot taskDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .get();

      if (taskDoc.exists) {
        int id = taskDoc['id']; // Get the task’s numeric ID

        _taskService.removeTask(id); // Call C++ function via FFI
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(taskId)
            .delete();

        debugPrint("✅ Task deleted: Firestore ID = $taskId, Numeric ID = $id");
      } else {
        debugPrint("❌ Task not found in Firestore: $taskId");
      }
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
    void updateTask() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTaskScreen(
            taskId: widget.taskId,
            existingName: widget.name,
            existingDescription: widget.description,
            existingPriority: widget.priority,
          ),
        ),
      );
    }
    MySize().init(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(Icons.arrow_back,color: Colors.white,)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Task Details", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold,color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const GradientBackground(),

          //Task Details Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Task Title Section
                  Text(
                    "Task Title",
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const[
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        widget.name,
                        style: TextStyle(fontSize: MySize.size22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Task Description Section
                  Text(
                    "Task Description",
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const[
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        widget.description,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔥 Priority Indicator
                  Row(
                    children: [
                      Icon(Icons.flag, color: _getPriorityColor(widget.priority), size: 30),
                      const SizedBox(width: 10),
                      Text(
                        "Priority: ${widget.priority}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),

                   SizedBox(height: MySize.size30),

                  //Edit & Delete Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Edit Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text("Edit"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        onPressed: ()=> updateTask(),
                      ),

                      // 🗑 Delete Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        onPressed: () => deleteTask(widget.taskId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Priority Colors
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green; // Low Priority
      case 2:
        return Colors.orange; // Medium Priority
      case 3:
        return Colors.red; // High Priority
      default:
        return Colors.blue;
    }
  }
}
