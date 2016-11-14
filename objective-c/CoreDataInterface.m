//
//  CoreDataInterface.m
//  CocoaFITS
//
//  Created by Demitri Muna on 9/5/14.
//
//

#import "CoreDataInterface.h"

@interface CoreDataInterface()
//@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, assign) NSManagedObjectContextConcurrencyType concurrencyType;
@property (nonatomic, copy) NSString *modelName;
@end

@implementation CoreDataInterface

- (instancetype)initWithModelName:(NSString*)modelName andConcurrencyModel:(NSManagedObjectContextConcurrencyType)type;
{
	if (self = [super init]) {
		self.concurrencyType = type;
		self.modelName = modelName;
		self.managedObjectContext = nil;
		self.managedObjectModel = nil;
		self.persistentStoreCoordinator = nil;
		self.persistentStoreFilename = @"Cache.storedata";
	}
	return self;
}

#pragma mark -
#pragma mark Core Data methods

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "org.???.???" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
	
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	
	return [appSupportURL URLByAppendingPathComponent:bundleID];
	
    //return [appSupportURL URLByAppendingPathComponent:@"Nightlight"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        DLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![[properties objectForKey:NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:self.persistentStoreFilename];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType
								   configuration:nil
											 URL:url
										 options:@{NSSQLitePragmasOption:@{@"journal_mode":@"WAL"}} // default on 10.9+
										   error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {

		NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
		if (!coordinator) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
			[dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
			NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
			[[NSApplication sharedApplication] presentError:error];
			return nil;
		}
		_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:self.concurrencyType];
		[_managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	
    return _managedObjectContext;
}

// Call this to delete the database; useful when debugging as the model is changing.
// Currently only allowed before the store coordinator has been created.
- (void)deletePersistentStore
{
	NSAssert(_persistentStoreCoordinator == nil, @"Trying to delete a store after the coordinater has been made!");
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
	NSError *error;

	for (NSString *ext in @[@"", @"-shm", @"-wal"]) {
		NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:[self.persistentStoreFilename stringByAppendingString:ext]];
		[fileManager removeItemAtURL:url error:&error];
		if (error == nil)
			return;
		else if (error.code == 4) // file not found
			return;
		else
			DLog(@"Error in trying to delete persistent store! %@", error);
	}
}

@end
