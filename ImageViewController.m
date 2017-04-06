//
//  ImageViewController.m
//  HomePwner
//
//  Created by 钟立 on 2016/10/31.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController () 

@end

@implementation ImageViewController

- (void)loadView {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.view = imageView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //强制转换后才能向view发送setImage消息
    UIImageView *imageView = (UIImageView *)self.view;
    imageView.image = self.image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
