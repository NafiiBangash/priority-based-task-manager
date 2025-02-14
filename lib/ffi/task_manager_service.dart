import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

typedef AddTaskC = Void Function(Int32 id, Pointer<Utf8> name, Pointer<Utf8> description, Int32 priority);
typedef RemoveTaskC = Void Function(Int32 id);
typedef UpdateTaskC = Void Function(Int32 id, Pointer<Utf8> name, Pointer<Utf8> description, Int32 priority);
typedef GetTasksC = Pointer<Utf8> Function();

class TaskManagerService {
  static final TaskManagerService _instance = TaskManagerService._internal();
  late DynamicLibrary _lib;

  factory TaskManagerService() {
    return _instance;
  }

  TaskManagerService._internal() {
    _loadLibrary();
  }

  void _loadLibrary() {
    if (Platform.isAndroid) {
      try {
        _lib = DynamicLibrary.open("libtask_manager.so");
        debugPrint("Library loaded successfully: libtask_manager.so");
      } catch (e) {
        debugPrint("Failed to load shared library: $e");
      }
    } else {
      throw Exception("Unsupported platform: Only Android is supported.");
    }
  }
  void addTask(int id, String name, String description, int priority) {
    final addTask = _lib.lookupFunction<AddTaskC, void Function(int, Pointer<Utf8>, Pointer<Utf8>, int)>('addTask');

    final namePtr = name.toNativeUtf8();
    final descPtr = description.toNativeUtf8();

    addTask(id, namePtr, descPtr, priority);

    malloc.free(namePtr);
    malloc.free(descPtr);

    String? userId = FirebaseAuth.instance.currentUser?.uid; // Get current user ID
    if (userId == null) return; //Prevent adding tasks if no user is logged in

    FirebaseFirestore.instance
        .collection('users') // ✅ Store tasks inside `users/{userId}/tasks`
        .doc(userId)
        .collection('tasks')
        .doc(id.toString())
        .set({
      'id': id,
      'userId': userId, // ✅ Associate task with user
      'name': name,
      'description': description,
      'priority': priority,
      'timestamp': FieldValue.serverTimestamp(),
    });

    debugPrint("Task Added to Firestore: $id");
  }


  void removeTask(int id) {
    final removeTask = _lib.lookupFunction<RemoveTaskC, void Function(int)>('removeTask');
    removeTask(id);

    // Remove from Firestore
    FirebaseFirestore.instance.collection('tasks').doc(id.toString()).delete();

    debugPrint("Task Removed: $id");
  }


  void updateTask(int id, String name, String description, int priority) {
    final updateTask = _lib.lookupFunction<UpdateTaskC, void Function(int, Pointer<Utf8>, Pointer<Utf8>, int)>('updateTask');

    final namePtr = name.toNativeUtf8();
    final descPtr = description.toNativeUtf8();

    updateTask(id, namePtr, descPtr, priority);

    // Update Firestore
    FirebaseFirestore.instance.collection('tasks').doc(id.toString()).update({
      'name': name,
      'description': description,
      'priority': priority,
      'timestamp': FieldValue.serverTimestamp(),
    });

    debugPrint("Task Updated: $id");
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return []; //  Return empty list if no user is logged in

    QuerySnapshot<Map<String, dynamic>> snapshot =
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('priority', descending: false) // ✅ Get only the user's tasks
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

}
