//
//  ItemStore.m
//  HomePwner
//
//  Created by 钟立 on 16/10/24.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import "ItemStore.h"
#import "Item.h"    
#import "ImageStore.h"
#import "AppDelegate.h"

@import CoreData;

@interface ItemStore ()

@property (nonatomic) NSMutableArray *privateItems;

@property (nonatomic, strong) NSMutableArray *allAssetTypes;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSManagedObjectModel *model;

@end

@implementation ItemStore

+ (instancetype)sharedStore {
    static ItemStore *sharedStore;
    
    if (!sharedStore) {
        sharedStore = [[self alloc] initPrivate];
    }
    
    return sharedStore;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
//        NSString *path = [self itemArchivePath];
//        _privateItems = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
//        if (!_privateItems) {
//            _privateItems = [[NSMutableArray alloc] init];
//        }
        
        _model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        NSString *path = self.itemArchivePath;
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        
        NSError *error = nil;
        
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            @throw [NSException exceptionWithName:@"OpenFailure" reason:error.localizedDescription userInfo:nil];
        }
        
        _context = [[NSManagedObjectContext alloc] init];
        _context.persistentStoreCoordinator = psc;
        
        [self loadAllItems];
    }
    return self;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton" reason:@"Use + [ItemStore sharedStore]" userInfo:nil];
    return nil;
}

- (NSArray *)allItems {
    return self.privateItems;
}

- (Item *)createItem {
//    Item *item = [[Item alloc] init];
    double order;
    if (self.allItems.count == 0) {
        order = 1.0;
    } else {
        order = [[self.privateItems lastObject] orderingValue] + 1.0;
    }
    NSLog(@"Adding after %lu items, order = %.2f", (unsigned long)self.privateItems.count, order);
    
    Item *item = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:self.context];
    item.orderingValue = order;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    item.valueInDollars = (int)[defaults integerForKey:NextItemValuePrefsKey];
    item.itemName = [defaults objectForKey:NextItemNamePrefsKey];
    
    NSLog(@"defaults = %@", [defaults dictionaryRepresentation]);
    
    [self.privateItems addObject:item];
    return item;
}

- (void)removeItem:(Item *)item {
    NSString *key = item.itemKey;
    [[ImageStore sharedStore] deleteImageForKey:key];
    
    [self.context deleteObject:item];
    [self.privateItems removeObjectIdenticalTo:item];
}

- (void)moveItemAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    if (fromIndex == toIndex) {
        return;
    }
    
    Item *item = self.privateItems[fromIndex];
    [self.privateItems removeObjectAtIndex:fromIndex];
    [self.privateItems insertObject:item atIndex:toIndex];
    
    double lowerBound = 0.0;
    
    if (toIndex > 0) {
        lowerBound = [self.privateItems[(toIndex-1)] orderingValue];
    } else {
        lowerBound = [self.privateItems[1] orderingValue] - 2.0;
    }
    
    double upperBound = 0.0;
    
    if (toIndex < self.privateItems.count - 1) {
        upperBound = [self.privateItems[toIndex + 1] orderingValue];
    } else {
        upperBound = [self.privateItems[(toIndex - 1)] orderingValue] + 2.0;
    }
    
    double newOrderValue = (lowerBound + upperBound) / 2.0;
    
    NSLog(@"moving to order %f", newOrderValue);
    item.orderingValue = newOrderValue;
}

- (NSString *)itemArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories firstObject];
    
    return [documentDirectory stringByAppendingPathComponent:@"store.data"];
}

//saveChanges会在应用进入后台时被调用
- (BOOL)saveChanges {
//    NSString *path = [self itemArchivePath];
//    return [NSKeyedArchiver archiveRootObject:self.privateItems toFile:path];
    
    NSError *error;
    BOOL successful = [self.context save:&error];
    if (!successful) {
        NSLog(@"Error saving: %@", [error localizedDescription]);
    }
    return successful;
}

- (void)loadAllItems {
    if (!self.privateItems) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *ed = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.context];
        request.entity = ed;
        
        NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"orderingValue" ascending:YES];
        request.sortDescriptors = @[sd];
        
        NSError *error;
        NSArray *result = [self.context executeFetchRequest:request error:&error];
        
        if (!result) {
            [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]];
        }
        self.privateItems = [[NSMutableArray alloc] initWithArray:result];
    }
}

- (NSArray *)allAssetTypes {
    if (!_allAssetTypes) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *ed = [NSEntityDescription entityForName:@"AssetType" inManagedObjectContext:self.context];
        request.entity = ed;
        
        NSError *error = nil;
        NSArray *result = [self.context executeFetchRequest:request error:&error];
        
        if (!result) {
            [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]];
        }
        _allAssetTypes = [result mutableCopy];
    }
    
    if (_allAssetTypes.count == 0) {
        NSManagedObject *type;
        type = [NSEntityDescription insertNewObjectForEntityForName:@"AssetType" inManagedObjectContext:self.context];
        [type setValue:@"Furniture" forKey:@"label"];
        [_allAssetTypes addObject:type];
        
        type = [NSEntityDescription insertNewObjectForEntityForName:@"AssetType" inManagedObjectContext:self.context];
        [type setValue:@"Jewelry" forKey:@"label"];
        [_allAssetTypes addObject:type];
        
        type = [NSEntityDescription insertNewObjectForEntityForName:@"AssetType" inManagedObjectContext:self.context];
        [type setValue:@"Electronics" forKey:@"label"];
        [_allAssetTypes addObject:type];
    }
    
    return  _allAssetTypes;
}

@end









