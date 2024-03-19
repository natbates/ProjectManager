//
//  Task.swift
//  Project Manager
//
//  Created by Nathaniel Bates on 18/03/2024.
//

import Foundation
import SwiftUI


struct TaskView: View {
    let title: String
    let tasks: [String]
    let isTargeted: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.footnote.bold())
                Text("(\(tasks.count))")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(isTargeted ? Color(hex: 0x2E8A6D).opacity(0.15) : Color(.secondarySystemFill))

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading) {
                        ForEach(tasks, id: \.self) { task in
                            Text(task)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(8)
                                .draggable(task)
                                .shadow(radius: 1, x: 1, y: 1)
                        }
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
    }
}


class TrashDropDelegate: DropDelegate {
    
    let removeTask: (String) -> Void
    
    init(removeTask: @escaping (String) -> Void) {
        self.removeTask = removeTask
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // Handle dropping the task into the trash/bin area
        if let item = info.itemProviders(for: ["public.text"]).first {
            item.loadObject(ofClass: String.self) { string, error in
                if let task = string {
                    _ = error
                    DispatchQueue.main.async {
                        self.removeTask(task)
                    }
                }
            }
            return true
        }
        return false
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: ["public.text"])
    }
}
