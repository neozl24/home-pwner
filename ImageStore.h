//
//  ImageStore.h
//  HomePwner
//
//  Created by 钟立 on 16/10/26.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageStore : NSObject

+ (instancetype)sharedStore;

- (void)setImage:(UIImage *)image forKey:(NSString *)key;
- (UIImage *)imageForKey:(NSString *)key;
- (void)deleteImageForKey:(NSString *)key;

@end
