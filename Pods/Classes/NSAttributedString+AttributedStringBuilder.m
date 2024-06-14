//
//  NSAttributedString+AttributedStringBuilder.m
//  YPPAttrKit
//
//  Created by MAC on 2023/2/1.
//

#import "NSAttributedString+AttributedStringBuilder.h"

@implementation NSAttributedString (AttributedStringBuilder)
- (YPPAttributedStringBuilder *)builder {
    return [[YPPAttributedStringBuilder alloc] initWithAttrDataSource:[self copy]];
}

@end
