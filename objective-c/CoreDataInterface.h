//
//  CoreDataInterface.h
//  CocoaFITS
//
//  Created by Demitri Muna on 9/5/14.
//
// Based on some ideas from here:
// http://red-glasses.com/index.php/tutorials/core-data-made-easy-some-code-practices-for-beginners-and-experts/

#import <Foundation/Foundation.h>

@interface CoreDataInterface : NSObject

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSString *persistentStoreFilename; // default value: "Cache.storedata"

- (instancetype)initWithModelName:(NSString*)modelName
			  andConcurrencyModel:(NSManagedObjectContextConcurrencyType)type;
- (void)deletePersistentStore;

@end
