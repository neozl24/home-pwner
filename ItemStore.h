//
//  ItemStore.h
//  HomePwner
//
//  Created by 钟立 on 16/10/24.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Item;

@interface ItemStore : NSObject

@property (nonatomic, readonly) NSArray *allItems;

+ (instancetype)sharedStore;
- (Item *)createItem;
- (void)removeItem:(Item *)item;
- (void)moveItemAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (BOOL)saveChanges;
- (NSArray *)allAssetTypes;

@end
