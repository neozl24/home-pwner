//
//  DetailViewController.h
//  HomePwner
//
//  Created by 钟立 on 16/10/25.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Item;

@interface DetailViewController : UIViewController <UIViewControllerRestoration>

- (instancetype)initForNewItem:(BOOL)isNew;

@property (nonatomic, copy) void (^dismissBlock)(void);
@property (nonatomic, strong) Item *item;

@end
