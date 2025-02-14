import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:task_manager/screens/sign_in_screen.dart';
import 'package:task_manager/utils/utils.dart';
import 'package:task_manager/widgets/gradient_background.dart';
import '../ffi/task_manager_service.dart';
import '../utils/size_config.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<bool> _showExitDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // ❌ Stay in app
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // ✅ Allow exit
            child: const Text("Exit"),
          ),
        ],
      ),
    ) ??
        false; // If dialog is dismissed, return false
  }
  final TaskManagerService _taskService = TaskManagerService();
  void deleteTask(String taskId) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // Prevent deletion if no user is logged in

    DocumentSnapshot taskDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .get();

    if (taskDoc.exists) {
      int id = taskDoc['id']; //Get the task’s numeric ID

      _taskService.removeTask(id); //Call C++ function via FFI
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
  }


  void _editTask(BuildContext context, String taskId, String name, String description, int priority) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          taskId: taskId,
          existingName: name,
          existingDescription: description,
          existingPriority: priority,
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseAuth.instance.signOut().then((_) {
        if (user != null) {
          Utils().showSuccessToast("Logged out: ${user.email}");
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
      }).onError((error, stackTrace) {
        Utils().showErrorToast("Logout failed: $error");
      });
    } catch (e) {
      Utils().showErrorToast("Error during logout: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    MySize().init(context);
    return PopScope(
      canPop: false, // ✅ Prevent default back button behavior
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) async {
        if (didPop) return;

        bool exitApp = await _showExitDialog();
        if (exitApp) {
          exit(0); // ✅ Close the app
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 🎨 Gradient Background
            const GradientBackground(),
      
            // Real-Time Task List via Firestore
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: MySize.size50, left: 20,right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your Tasks",
                        style: GoogleFonts.montserrat(
                          fontSize: MySize.size28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(onPressed: (){
                        _logout(context);
                      }, icon: Icon(Icons.logout,color: Colors.white,size: MySize.size40,))
                    ],
                  ),
                ),
      
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid) // ✅ Get tasks for logged-in user
                        .collection('tasks')
                        .orderBy('priority')
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text(
                          "No tasks found",
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: MySize.size24
                          ),
                        ),);
                      }
      
                      final tasks = snapshot.data!.docs;
      
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          var task = tasks[index];
      
                          return AnimatedContainer(
                            key: ValueKey(task.id), // Unique key for animation
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Slidable(
                              startActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    label: 'Edit',
                                    icon: Icons.edit,
                                    backgroundColor: Colors.orangeAccent,
                                    onPressed: (context) {
                                      _editTask(context, task.id, task['name'], task['description'], task['priority']);
                                    },
                                  ),
                                ],
                              ),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    label: 'Delete',
                                    icon: Icons.delete,
                                    backgroundColor: Colors.red,
                                    onPressed: (context) {
                                      deleteTask(task.id);
                                    },
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskDetailScreen(
                                        taskId: task.id.toString(),
                                        name: task['name'],
                                        description: task['description'],
                                        priority: task['priority'],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
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
                                  child: ListTile(
                                    title: Text(
                                      task['name'],
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      task['description'],
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                                    ),
                                    trailing: Text(
                                      "Priority: ${task['priority']}",
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
      
              ],
            ),
          ],
        ),
      
        // ➕ Floating Add Button
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTaskScreen())),
          backgroundColor: Colors.blueAccent,
          elevation: 10,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
