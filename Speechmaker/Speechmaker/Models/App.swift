//
//  App.swift
//  Speechmaker
//
//  Created by Ethan Diamond on 8/3/16.
//  Copyright © 2016 Bad Mouth LLC. All rights reserved.
//

import Foundation
import CoreData

class App: NSManagedObject {

    static func defaultApp() -> App {
        return App.mr_findFirst()!
    }
    
    static func defaultAppInContext(_ context: NSManagedObjectContext) -> App {
        return App.mr_findFirst(in: context)!
    }

}
