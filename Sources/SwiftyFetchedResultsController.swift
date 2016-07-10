
import Foundation
import CoreData

public protocol ModelObject {
  associatedtype ManagedObjectType: NSManagedObject
  
  init(managedObject: ManagedObjectType)
}

@available(OSX 10.12, *)
public protocol PlainObjectFetchedResultsControllerDelegate: class {
  associatedtype ObjectType: ModelObject
  
  func controller(_ controller: PlainObjectFetchedResultsController<ObjectType, Self>,
                  didChangeSection sectionInfo: PlainObjectFetchedResultsSectionInfo<ObjectType>,
                  atIndex sectionIndex: Int,
                  forChangeType type: NSFetchedResultsChangeType)
  
  func controller(_ controller: PlainObjectFetchedResultsController<ObjectType, Self>,
                  didChange anObject: ObjectType,
                  at indexPath: IndexPath?,
                  for type: NSFetchedResultsChangeType,
                  newIndexPath: IndexPath?)
  
  func controllerWillChangeContent(_ controller: PlainObjectFetchedResultsController<ObjectType, Self>)
  
  func controllerDidChangeContent(_ controller: PlainObjectFetchedResultsController<ObjectType, Self>)
  
  func controller(_ controller: PlainObjectFetchedResultsController<ObjectType, Self>,
                  sectionIndexTitleForSectionName sectionName: String) -> String?
}

@available(OSX 10.12, *)
public class PlainObjectFetchedResultsController<ObjectType: ModelObject, DelegateType: PlainObjectFetchedResultsControllerDelegate where DelegateType.ObjectType == ObjectType>: NSObject, NSFetchedResultsControllerDelegate {
  
  public typealias FetchedResultsController = NSFetchedResultsController<ObjectType.ManagedObjectType>
  
  private let fetchedResultsController: FetchedResultsController
  
  private let delegate: DelegateType
  
  public init(fetchedResultsController: FetchedResultsController,
              delegate: DelegateType) {
    self.fetchedResultsController = fetchedResultsController
    self.delegate = delegate
    super.init()
    self.fetchedResultsController.delegate = self
  }
  
  //MARK: Convenience methods
  public func performFetch() throws {
    try fetchedResultsController.performFetch()
  }
  
  public var sections: [PlainObjectFetchedResultsSectionInfo<ObjectType>]? {
    return fetchedResultsController.sections?.map {
      PlainObjectFetchedResultsSectionInfo(sectionInfo: $0)
    }
  }
  
  
  //MARK: - NSFetchedResultsControllerDelegate
  @objc
  public func controller(controller: NSFetchedResultsController<ObjectType.ManagedObjectType>,
                         didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                         atIndex sectionIndex: Int,
                         forChangeType type: NSFetchedResultsChangeType) {
    delegate.controller(self, didChangeSection: PlainObjectFetchedResultsSectionInfo(sectionInfo: sectionInfo), atIndex: sectionIndex, forChangeType: type)
  }
  
  public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                         didChange anObject: AnyObject,
                         at indexPath: IndexPath?,
                         for type: NSFetchedResultsChangeType,
                         newIndexPath: IndexPath?) {
    let managedObject = anObject as! ObjectType.ManagedObjectType
    let modelObject = ObjectType(managedObject: managedObject)
    delegate.controller(self, didChange: modelObject, at: indexPath, for: type, newIndexPath: newIndexPath)
  }
  
  @objc
  public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    delegate.controllerWillChangeContent(self)
  }
  
  @objc
  public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    delegate.controllerDidChangeContent(self)
  }
  
  @objc
  public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                         sectionIndexTitleForSectionName sectionName: String) -> String? {
    return delegate.controller(self, sectionIndexTitleForSectionName: sectionName)
  }
}

@available(OSX 10.12, *)
public extension PlainObjectFetchedResultsController {
  public func object(at indexPath: IndexPath) -> ObjectType {
    let managedObject = fetchedResultsController.object(at: indexPath)
    return ObjectType(managedObject: managedObject)
  }
}

public final class PlainObjectFetchedResultsSectionInfo<ObjectType: ModelObject> {
  private let sectionInfo: NSFetchedResultsSectionInfo
  
  public init(sectionInfo: NSFetchedResultsSectionInfo) {
    self.sectionInfo = sectionInfo
  }
  
  /// Name of the section
  var name: String {
    return sectionInfo.name
  }
  
  /// Title of the section (used when displaying the index)
  var indexTitle: String? {
    return sectionInfo.indexTitle
  }
  
  ///Number of objects in section
  var numberOfObjects: Int {
    return sectionInfo.numberOfObjects
  }
  
  /// Returns the array of objects in the section.
  /// - complexity: traverse all managed objects and convert them to ObjectType. Can be expensive if there are many managed objects in section.
  var modelObjects: [ObjectType]? {
    return sectionInfo.objects?.map { ObjectType(managedObject: $0 as! ObjectType.ManagedObjectType) }
  }
}
