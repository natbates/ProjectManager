import SwiftUI
import Foundation

enum TaskType: String, Codable {
    case todo
    case inProgress
    case done
}

struct NewProjectView: View {
    @Binding var isPresented: Bool
    @Binding var projectName: String
    @Binding var selectedDate: Date
    var addProject: (String, Date?) -> Void
    
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Image("newprojectphoto")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                
                Text("App Made By Nathaniel Bates")
                                
                TextField("Project Name", text: $projectName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)

                
                DatePicker("Due Date", selection: $selectedDate, displayedComponents: .date)
                    .padding()
                
                Button(action: {
                    if projectName.isEmpty {
                        showAlert = true // Show the alert if the project name is empty
                    } else {
                        addProject(projectName, selectedDate)
                        projectName = ""
                        isPresented = false
                    }
                }) {
                    Text("Create Project")
                        .padding()
                        .foregroundColor(.white)
                        .frame(maxWidth: 380)
                        .background(Color(hex: 0x2E8A6D))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                        .padding()
                }
            }
            .navigationTitle("New Project")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Project Name Required"), message: Text("Please enter a project name."), dismissButton: .default(Text("OK")))
            }
        }
    }
}

class ProjectManager: ObservableObject {
    @Published var projects: [Project] = []
    
    init() {
        loadProjects()
    }
    
    func addProject(_ project: Project) {
        var projectName = project.name
        var num = 1
        
        // Check if the project name already exists
        while projects.contains(where: { $0.name == projectName }) {
            projectName = "\(project.name) (\(num))"
            num += 1
        }
        
        // Create a new project instance with the updated name
        let updatedProject = Project(id: project.id, name: projectName, dueDate: project.dueDate, toDoTasks: project.toDoTasks, inProgressTasks: project.inProgressTasks, doneTasks: project.doneTasks, status: ProjectStatus.ongoing)
        
        // Add the updated project to the list of projects
        projects.append(updatedProject)
        
        // Save the updated list of projects and categorize them
        saveProjects()
    }
    
    func saveProjects() {
        do {
            let encodedData = try JSONEncoder().encode(projects)
            UserDefaults.standard.set(encodedData, forKey: "projects")
            
        } catch {
            print("Error encoding projects: \(error.localizedDescription)")
        }
    }
    
    func loadProjects() {
        if let encodedData = UserDefaults.standard.data(forKey: "projects") {
            do {
                let decodedProjects = try JSONDecoder().decode([Project].self, from: encodedData)
                projects = decodedProjects
                
                // Categorize projects after loading
            } catch {
                print("Error decoding projects: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects.remove(at: index)
            saveProjects() // Save changes after deleting the project
        }
    }
    
}

struct ContentView: View {
    @StateObject var projectManager = ProjectManager()
    @State private var isAddingProject = false
    @State private var newProjectName = ""
    @State private var selectedDueDate: Date = Date()
    @State private var selectedProject: Project?
    
    var body: some View {
        
        NavigationView {
            VStack {
                List {
                    Section(header: Text("All Projects")) {
                        ForEach(projectManager.projects) { project in
                            NavigationLink(destination: ProjectView(project: .constant(project), projectManager: projectManager, onSave: projectManager.saveProjects)) {
                                Text(project.name)
                            }
                        }
                    }
                    .cornerRadius(15)
                }
                .cornerRadius(15)
                .navigationBarTitle("Projects", displayMode: .inline)
            
                Spacer()
                Button(action: {
                    isAddingProject = true
                }) {
                    Text("New Project")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Color(hex: 0x2E8A6D))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .padding(.vertical, 10)
                .sheet(isPresented: $isAddingProject) {
                    NewProjectView(isPresented: $isAddingProject, projectName: $newProjectName, selectedDate: $selectedDueDate) { name, date in
                        let project = Project(name: name, dueDate: date, status: .ongoing)
                        projectManager.addProject(project)
                    }
                }
            }

            .navigationBarTitle("Projects", displayMode: .inline)
            .background(Color.white)
            .onAppear {
                projectManager.projects = []
                projectManager.loadProjects()
            }
        }
        .background(Color.white)
        .frame(maxWidth: 600)
        .padding()
        .cornerRadius(8)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Color {
    init(hex: Int, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
