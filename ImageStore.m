//
//  ImageStore.m
//  HomePwner
//
//  Created by 钟立 on 16/10/26.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import "ImageStore.h"

@interface ImageStore ()

@property (nonatomic, strong) NSMutableDictionary *dictionary;

- (NSString *)imagePathForKey:(NSString *)key;

@end

@implementation ImageStore

+ (instancetype)sharedStore {
    static ImageStore *sharedStore = nil;
    
//    if (!sharedStore) {
//        sharedStore = [[self alloc] initPrivate];
//    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore = [[self alloc] initPrivate];
    });
    return sharedStore;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton" reason:@"Use + [ImageStore sharedStore]" userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _dictionary = [[NSMutableDictionary alloc] init];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(clearCache:)
                   name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key {
//    [_dictionary setObject:image forKey:key];
    self.dictionary[key] = image;
    
    NSString *imagePath = [self imagePathForKey:key];
    NSData *data = UIImageJPEGRepresentation(image, 0.5);
    [data writeToFile:imagePath atomically:YES];
}

- (UIImage *)imageForKey:(NSString *)key {
//    return [_dictionary objectForKey:key];
    UIImage *result = self.dictionary[key];
    
    if (!result) {
        NSString *imagePath = [self imagePathForKey:key];
        result = [UIImage imageWithContentsOfFile:imagePath];
        
        if (result) {
            self.dictionary[key] = result;
        } else {
            NSLog(@"Error: unable to find %@", [self imagePathForKey:key]);
        }
    }
    
    return result;
}

- (void)deleteImageForKey:(NSString *)key {
    if (!key) {
        return;
    }
    [_dictionary removeObjectForKey:key];
    
    NSString *imagePath = [self imagePathForKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
}

- (NSString *)imagePathForKey:(NSString *)key {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories firstObject];
    
    return [documentDirectory stringByAppendingPathComponent:key];
}

- (void)clearCache:(NSNotification *)note {
    NSLog(@"flushing %ld images out of the cache", (unsigned long)[self.dictionary count]);
    [self.dictionary removeAllObjects];
}

@end
