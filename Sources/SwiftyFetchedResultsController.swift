
import Foundation
import CoreData

public protocol ModelObject {
  associatedtype ManagedObjectType: NSManagedObject
  
  init(managedObject: ManagedObjectType)
}

public protocol SwiftyFetchedResultsControllerDelegate: class {
  associatedtype ObjectType: ModelObject
  func controller(controller: SwiftyFetchedResultsController<ObjectType, Self>,
                  didChangeSection sectionInfo: SwiftyFetchedResultsSectionInfo<ObjectType>,
                                   atIndex sectionIndex: Int,
                                           forChangeType type: NSFetchedResultsChangeType)
  func controller(controller: SwiftyFetchedResultsController<ObjectType, Self>,
                  didChangeObject anObject: ObjectType,
                                  atIndexPath indexPath: NSIndexPath?,
                                              forChangeType type: NSFetchedResultsChangeType,
                                                            newIndexPath: NSIndexPath?)
  func controllerWillChangeContent(controller: SwiftyFetchedResultsController<ObjectType, Self>)
  func controllerDidChangeContent(controller: SwiftyFetchedResultsController<ObjectType, Self>)
  func controller(controller: SwiftyFetchedResultsController<ObjectType, Self>, sectionIndexTitleForSectionName sectionName: String) -> String?
}

public class SwiftyFetchedResultsController<ObjectType: ModelObject, DelegateType: SwiftyFetchedResultsControllerDelegate where DelegateType.ObjectType == ObjectType>: NSObject, NSFetchedResultsControllerDelegate {
  private let fetchedResultsController: NSFetchedResultsController
  private let delegate: DelegateType
  
  public init(fetchedResultsController: NSFetchedResultsController,
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
  
  public var sections: [SwiftyFetchedResultsSectionInfo<ObjectType>]? {
    return fetchedResultsController.sections?.map {
      SwiftyFetchedResultsSectionInfo(sectionInfo: $0)
    }
  }
  
  
  //MARK: - NSFetchedResultsControllerDelegate
  @objc
  public func controller(controller: NSFetchedResultsController,
                         didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                                          atIndex sectionIndex: Int,
                                                  forChangeType type: NSFetchedResultsChangeType) {
    delegate.controller(self, didChangeSection: SwiftyFetchedResultsSectionInfo(sectionInfo: sectionInfo), atIndex: sectionIndex, forChangeType: type)
  }
  
  @objc
  public func controller(controller: NSFetchedResultsController,
                         didChangeObject anObject: AnyObject,
                                         atIndexPath indexPath: NSIndexPath?,
                                                     forChangeType type: NSFetchedResultsChangeType,
                                                                   newIndexPath: NSIndexPath?) {
    let managedObject = anObject as! ObjectType.ManagedObjectType
    let modelObject = ObjectType(managedObject: managedObject)
    delegate.controller(self, didChangeObject: modelObject, atIndexPath: indexPath, forChangeType: type, newIndexPath: newIndexPath)
  }
  
  @objc
  public func controllerWillChangeContent(controller: NSFetchedResultsController) {
    delegate.controllerWillChangeContent(self)
  }
  
  @objc
  public func controllerDidChangeContent(controller: NSFetchedResultsController) {
    delegate.controllerDidChangeContent(self)
  }
  
  @objc
  public func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
    return delegate.controller(self, sectionIndexTitleForSectionName: sectionName)
  }
}

public extension SwiftyFetchedResultsController {
  public func object(atIndexPath indexPath: NSIndexPath) -> ObjectType {
    let managedObject = fetchedResultsController.objectAtIndexPath(indexPath) as! ObjectType.ManagedObjectType
    return ObjectType(managedObject: managedObject)
  }
}

public final class SwiftyFetchedResultsSectionInfo<ObjectType: ModelObject> {
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