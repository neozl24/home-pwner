//
//  ImageTransformer.m
//  HomePwner
//
//  Created by 钟立 on 2016/11/11.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import "ImageTransformer.h"

@implementation ImageTransformer

+ (Class)transformedValueClass {
    return [NSData class];
}

- (id)transformedValue:(id)value {
    if (!value) {
        return nil;
    }
    if ([value isKindOfClass:[NSData class]]) {
        return value;
    }
    return UIImagePNGRepresentation(value);
}

- (id)reverseTransformedValue:(id)value {
    return [UIImage imageWithData:value];
}

@end
