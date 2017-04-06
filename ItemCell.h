//
//  ItemCell.h
//  HomePwner
//
//  Created by 钟立 on 2016/10/30.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *serialNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@property (nonatomic, copy) void (^actionBlock)(void);

@end
