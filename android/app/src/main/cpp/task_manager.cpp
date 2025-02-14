#include <iostream>
#include <string>
#include <vector>
#include <cstring>

struct Task {
    int id;
    std::string name;
    std::string description;
    int priority;
};

// Simulated task storage
std::vector<Task> tasks;

extern "C" {

// Function to add a task
const char* addTask(int id, const char* name, const char* description, int priority) {
    tasks.push_back({id, name, description, priority});
    std::string response = "Task Added: ID=" + std::to_string(id) + ", Name=" + name;

    char* result = new char[response.length() + 1];
    std::strcpy(result, response.c_str());
    return result;
}

// Function to remove a task by ID
const char* removeTask(int id) {
    for (auto it = tasks.begin(); it != tasks.end(); ++it) {
        if (it->id == id) {
            tasks.erase(it);
            std::string response = "Task Removed: ID=" + std::to_string(id);
            char* result = new char[response.length() + 1];
            std::strcpy(result, response.c_str());
            return result;
        }
    }
    return "Task Not Found";
}

// Function to update a task
const char* updateTask(int id, const char* name, const char* description, int priority) {
    for (auto &task : tasks) {
        if (task.id == id) {
            task.name = name;
            task.description = description;
            task.priority = priority;
            return "Task Updated";
        }
    }
    return "Task Not Found";
}

// Function to retrieve all tasks as a JSON string
const char* getTasks() {
    std::string json = "[";
    for (size_t i = 0; i < tasks.size(); i++) {
        json += "{ \"id\": " + std::to_string(tasks[i].id) +
                ", \"name\": \"" + tasks[i].name +
                "\", \"description\": \"" + tasks[i].description +
                "\", \"priority\": " + std::to_string(tasks[i].priority) + " }";
        if (i != tasks.size() - 1) json += ",";
    }
    json += "]";

    char* result = new char[json.length() + 1];
    std::strcpy(result, json.c_str());
    return result;
}

}
