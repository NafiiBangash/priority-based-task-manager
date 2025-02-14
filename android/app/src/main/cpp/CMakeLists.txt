cmake_minimum_required(VERSION 3.10.2)

project(task_manager)

# Add your C++ source file
add_library(task_manager SHARED task_manager.cpp)

# Link libraries needed for Android
find_library(log-lib log)

target_link_libraries(task_manager ${log-lib})
