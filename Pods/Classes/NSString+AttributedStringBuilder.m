//
//  NSString+AttributedStringBuilder.m
//  YPPAttrKit
//
//  Created by MAC on 2023/2/1.
//

#import "NSString+AttributedStringBuilder.h"

@implementation NSString (AttributedStringBuilder)
- (YPPAttributedStringBuilder *)builder {
    return [[YPPAttributedStringBuilder alloc] initWithDataSource:[self copy]];
}

@end
