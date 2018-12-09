//
//  Note+CoreDataClass.swift
//
//
//  Created by Ash Zade on 2017-12-31.
//
//

import UIKit
import CoreData

public class Note {

    // Properties
    var noteTitle: String
    var groupItems = [[String]]()
    var groups = [String]()
    var updatedDate = Date()

    init?(noteTitle: String, groupItems: [[String]], groups: [String], date: Date) {

        if groups.isEmpty || groupItems.isEmpty {
            return nil
        }

        self.noteTitle = noteTitle
        self.groupItems = groupItems
        self.groups = groups
        self.updatedDate = date
    }
    
    func addGroup(groupName: String) {
        groups.append(groupName)
    }
}

class Item {
    var value: String
    var children: [Item] = []
    weak var parent: Item?
    
    init(value: String) {
        self.value = value
    }
    
    func add(child: Item) {
        children.append(child)
        child.parent = self
    }
}

struct DisplayGroup {
    var indentationLevel: Int
    var item: Item?
    var hasChildren: Bool
}
