//
//  Project.swift
//  Project Manager
//
//  Created by Nathaniel Bates on 18/03/2024.
//

import Foundation
import SwiftUI

enum ProjectStatus: String, Codable {
    case ongoing
    case completed
}

struct Project: Codable, Identifiable {
    var id: UUID
    let name: String
    let dueDate: Date?
    var toDoTasks: [String]
    var inProgressTasks: [String]
    var doneTasks: [String]
    var status: ProjectStatus
    
    init(id: UUID = UUID(), name: String, dueDate: Date?, toDoTasks: [String] = [], inProgressTasks: [String] = [], doneTasks: [String] = [], status: ProjectStatus) {
        self.id = id
        self.name = name
        self.dueDate = dueDate
        self.toDoTasks = toDoTasks
        self.inProgressTasks = inProgressTasks
        self.doneTasks = doneTasks
        self.status = status
    }
    
    // Define custom coding keys to handle decoding
    enum CodingKeys: String, CodingKey {
        case id, name, dueDate, toDoTasks, inProgressTasks, doneTasks, status
    }
    
    func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(dueDate, forKey: .dueDate)
            try container.encode(toDoTasks, forKey: .toDoTasks)
            try container.encode(inProgressTasks, forKey: .inProgressTasks)
            try container.encode(doneTasks, forKey: .doneTasks)
            
            // Encode status as a string
            let statusString = status == .completed ? "completed" : "ongoing"
            try container.encode(statusString, forKey: .status)
        }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedId = try container.decodeIfPresent(UUID.self, forKey: .id)
        self.id = decodedId ?? UUID() // Assign decoded UUID if available, otherwise generate a new one
        self.name = try container.decode(String.self, forKey: .name)
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.toDoTasks = try container.decode([String].self, forKey: .toDoTasks)
        self.inProgressTasks = try container.decode([String].self, forKey: .inProgressTasks)
        self.doneTasks = try container.decode([String].self, forKey: .doneTasks)
        let statusString = try container.decode(String.self, forKey: .status)
        self.status = statusString == "completed" ? .completed : .ongoing
    }
}


class ProjectViewModel: ObservableObject {
    
    @Published var toDoTasks: [String]
    @Published var inProgressTasks: [String]
    @Published var doneTasks: [String]
    @Published var status: ProjectStatus
    
    @Published var isToDoTargeted = false
    @Published var isInProgressTargeted = false
    @Published var isDoneTargeted = false
    
    init(tasks: [TaskType: [String]], status: ProjectStatus) {
        self.toDoTasks = tasks[.todo] ?? []
        self.inProgressTasks = tasks[.inProgress] ?? []
        self.doneTasks = tasks[.done] ?? []
        self.status = status
    }
    
    func addNewTask(_ task: String, _ taskType: TaskType) {
            
        // Function to generate a unique task name
        func uniqueTaskName(for task: String, in tasks: [String]) -> String {
            var updatedTask = task
            var num = 1
            while tasks.contains(updatedTask) {
                updatedTask = "\(task) (\(num))"
                num += 1
            }
            return updatedTask
        }
        
        // Check if the task already exists in any list
        let allTasks = toDoTasks + inProgressTasks + doneTasks
        if allTasks.contains(task) {
            // If task exists, find a unique name
            let uniqueName = uniqueTaskName(for: task, in: allTasks)
            // Add the task to the appropriate list
            switch taskType {
            case .todo:
                toDoTasks.append(uniqueName)
            case .inProgress:
                inProgressTasks.append(uniqueName)
            case .done:
                doneTasks.append(uniqueName)
            }
        } else {
            // If the task does not exist, simply add it to the appropriate list
            switch taskType {
            case .todo:
                toDoTasks.append(task)
            case .inProgress:
                inProgressTasks.append(task)
            case .done:
                doneTasks.append(task)
            }
        }
    }
    
    func removeTask(_ task: String) {
        // Remove the task from any of the task lists if it exists
        toDoTasks.removeAll { $0 == task }
        inProgressTasks.removeAll { $0 == task }
        doneTasks.removeAll { $0 == task }
    }
    
    func handleDrop(tasks droppedTasks: [String], location: CGPoint, taskType: TaskType) -> Bool {
        switch taskType {
        case .todo:
            for task in droppedTasks {
                inProgressTasks.removeAll { $0 == task }
                doneTasks.removeAll { $0 == task }
            }
            
            toDoTasks.removeAll { droppedTasks.contains($0) }
            let index = min(toDoTasks.count, max(0, Int(location.y / 44)))
            toDoTasks.insert(contentsOf: droppedTasks, at: index)
            return true // Indicate success of drop operation
            
        case .inProgress:
            for task in droppedTasks {
                toDoTasks.removeAll { $0 == task }
                doneTasks.removeAll { $0 == task }
            }
            
            inProgressTasks.removeAll { droppedTasks.contains($0) }
            let index = min(inProgressTasks.count, max(0, Int(location.y / 44)))
            inProgressTasks.insert(contentsOf: droppedTasks, at: index)
            return true // Indicate success of drop operation
            
        case .done:
            for task in droppedTasks {
                toDoTasks.removeAll { $0 == task }
                inProgressTasks.removeAll { $0 == task }
            }
            
            doneTasks.removeAll { droppedTasks.contains($0) }
            let index = min(doneTasks.count, max(0, Int(location.y / 44)))
            doneTasks.insert(contentsOf: droppedTasks, at: index)
            return true // Indicate success of drop operation
        }
    }

}

struct ProjectView: View {
    @ObservedObject var viewModel: ProjectViewModel
    @ObservedObject var projectManager: ProjectManager // Declare the variable
    @Environment(\.presentationMode) var presentationMode
    @Binding var project: Project
    @State private var showingConfirmation = false
    
    var onSave: () -> Void
    
    init(project: Binding<Project>, projectManager: ProjectManager, onSave: @escaping () -> Void) {
        self._project = project
        self.projectManager = projectManager
        
        // Create a dictionary containing tasks and status
        let tasksDict: [TaskType: [String]] = [
            .todo: project.wrappedValue.toDoTasks,
            .inProgress: project.wrappedValue.inProgressTasks,
            .done: project.wrappedValue.doneTasks
        ]
        self.viewModel = ProjectViewModel(tasks: tasksDict, status: project.wrappedValue.status)
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(project.name)
                    .font(.system(size: 35))
                    .padding(.vertical, 8)
                    .padding(.horizontal, -3)
                Spacer()
                
                Button(action: {
                    presentTaskAlert(taskType: .todo, viewModel: viewModel)
                }) {
                    Text("Add Task")
                        .padding()
                        .background(Color(hex: 0x2E8A6D))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 1, x: 1, y: 1)
                }
                .padding(.horizontal, 8)
                
                Button(action: {
                    showingConfirmation = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.red)
                        
                        Image(systemName: "trash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                    .contentShape(Rectangle())
                    .onDrop(of: ["public.text"], delegate: TrashDropDelegate(removeTask: viewModel.removeTask))
                }
            }
            
            TaskView(title: "To Do", tasks: viewModel.toDoTasks, isTargeted: viewModel.isToDoTargeted)
                .frame(maxWidth: .infinity)
                .dropDestination(for: String.self) { droppedTasks, location in
                    let result = viewModel.handleDrop(tasks: droppedTasks, location: location, taskType: .todo)
                    self.saveState() // Save state after handling drop
                    return result
                } isTargeted: { isTargeted in
                    viewModel.isToDoTargeted = isTargeted
                }

            TaskView(title: "In Progress", tasks: viewModel.inProgressTasks, isTargeted: viewModel.isInProgressTargeted)
                .dropDestination(for: String.self) { droppedTasks, location in
                    let result = viewModel.handleDrop(tasks: droppedTasks, location: location, taskType: .inProgress)
                    self.saveState() // Save state after handling drop
                    return result
                } isTargeted: { isTargeted in
                    viewModel.isInProgressTargeted = isTargeted
                }

            TaskView(title: "Done", tasks: viewModel.doneTasks, isTargeted: viewModel.isDoneTargeted)
                .dropDestination(for: String.self) { droppedTasks, location in
                    let result = viewModel.handleDrop(tasks: droppedTasks, location: location, taskType: .done)
                    self.saveState() // Save state after handling drop
                    return result
                } isTargeted: { isTargeted in
                    viewModel.isDoneTargeted = isTargeted
                }

            HStack{
                Spacer()
                Text(daysLeftText)
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 15)
        .alert(isPresented: $showingConfirmation) {
            Alert(
                title: Text("Are you sure you want to delete this project?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteProject()
                    
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            print(viewModel.toDoTasks, viewModel.inProgressTasks, viewModel.doneTasks) // WHY ARE THESE EMPTY???
            loadState()
            
        }
        .onDisappear {
            print("dick head")
        }
    }
    
    private var daysLeftText: String {
        guard let dueDate = project.dueDate else {
            return "No due date"
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        let daysLeft = calendar.dateComponents([.day], from: currentDate, to: dueDate).day ?? 0
        
        if daysLeft > 0 {
            return "\(daysLeft) day\(daysLeft == 1 ? "" : "s") left"
        } else if daysLeft < 0 {
            return "\(abs(daysLeft)) day\(abs(daysLeft) == 1 ? "" : "s") overdue"
        } else {
            return "Due today"
        }
    }
    
    func deleteProject() {
        projectManager.deleteProject(project)
        presentationMode.wrappedValue.dismiss() // Dismiss the current view, navigating back to the main menu
        projectManager.loadProjects()
    }
    
    func saveState() {
        
        print("X")
                
        UserDefaults.standard.set(try? JSONEncoder().encode(viewModel.toDoTasks), forKey: "toDoTasks_\(project.id)")
        UserDefaults.standard.set(try? JSONEncoder().encode(viewModel.inProgressTasks), forKey: "inProgressTasks_\(project.id)")
        UserDefaults.standard.set(try? JSONEncoder().encode(viewModel.doneTasks), forKey: "doneTasks_\(project.id)")
        
        let numTasksToDo = viewModel.toDoTasks.count
        let numTasksInProgress = viewModel.inProgressTasks.count
        let numTasksDone = viewModel.doneTasks.count
        
        // Update the project status based on the number of tasks
        if numTasksToDo == 0 && numTasksInProgress == 0 && numTasksDone >= 1 {
            $project.wrappedValue.status = .completed
        } else {
            $project.wrappedValue.status = .ongoing
        }
        
        UserDefaults.standard.set(try? JSONEncoder().encode(viewModel.status), forKey: "status_\($project.status)")
        
        projectManager.saveProjects()
    }
    
    func loadState() {
        func loadContainers(forKey key: String) -> [String] {
            if let data = UserDefaults.standard.data(forKey: key),
               let loadedContainers = try? JSONDecoder().decode([String].self, from: data) {
                return loadedContainers
            }
            return []
        }
                
        viewModel.toDoTasks = loadContainers(forKey: "toDoTasks_\(project.id)")
        viewModel.inProgressTasks = loadContainers(forKey: "inProgressTasks_\(project.id)")
        viewModel.doneTasks = loadContainers(forKey: "doneTasks_\(project.id)")
        
        if let data = UserDefaults.standard.data(forKey: "status_\(project.id)"),
           let loadedStatus = try? JSONDecoder().decode(ProjectStatus.self, from: data) {
            viewModel.status = loadedStatus
        }
    }
    
    func presentTaskAlert(taskType: TaskType, viewModel: ProjectViewModel) {
        var taskName = ""
        
        let alertController = UIAlertController(title: "Add Task", message: "Enter task name", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Task name"
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            if let textField = alertController.textFields?.first, let text = textField.text {
                taskName = text
                viewModel.addNewTask(taskName, taskType)
                saveState()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        // Retrieve the key window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let window = windowScene.windows.first {
                // Present the alert on the key window's root view controller
                window.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
}




