//
//  YPPAsyncAttributedStringBuilder.m
//  YPPAttrKit
//
//  Created by MAC on 2023/2/1.
//
#import "YPPAttributedStringBuilder.h"
@interface YPPAttributedStringBuilder()
@property (nonatomic, strong) NSMutableArray <YPPAttributedStringProperty *> *buildPropertys;
@property (nonatomic, copy) NSString *dataSource;
@property (nonatomic, strong) NSAttributedString *attrDataSource;

@end


@implementation YPPAttributedStringBuilder


- (instancetype)initWithDataSource:(NSString *)dataSource {
    if (self = [super init]) {
        self.dataSource = dataSource;
        self.buildPropertys = @[].mutableCopy;
    }
    return self;
}

- (instancetype)initWithAttrDataSource:(NSAttributedString *)attrDataSource {
    if (self = [super init]) {
        self.attrDataSource = attrDataSource;
        self.buildPropertys = @[].mutableCopy;
    }
    return self;
}

- (void)add:(YPPAttributedStringProperty *)property {
    if (![property isKindOfClass:YPPAttributedStringProperty.class]) return;
    [self.buildPropertys addObject:property];
}

- (YPPAddAttributedBuildBlock)add {
    __weak typeof(self)ws = self;
    YPPAddAttributedBuildBlock attrBuildBlock =
    ^YPPAttributedStringBuilder *(YPPStaticAttributedStringPropertyBuildBlock propertyBuidBlock) {
        __strong typeof(ws)self = ws;
        if (propertyBuidBlock) {
            YPPStaticAttributedStringProperty *p = [YPPStaticAttributedStringProperty new];
            p.builder = self;
            propertyBuidBlock(p);
            [self.buildPropertys addObject:p];
        }
        return self;
    };
    return attrBuildBlock;
}

- (id(^)(NSAttributedStringKey))any {
    return ^id(NSAttributedStringKey key) {
        for (int i = (int)self.buildPropertys.count - 1; i >= 0; i --) {
            YPPStaticAttributedStringProperty *prop = (YPPStaticAttributedStringProperty *)self.buildPropertys[i];
            if (![prop isKindOfClass:[YPPStaticAttributedStringProperty class]]) continue;
            if (![prop.key isEqualToString:key]) continue;
            return prop.value;
        }
        return nil;
    };
}

- (YPPReplaceAttributedBuildBlock)every {
    __weak typeof(self)ws = self;
    YPPReplaceAttributedBuildBlock attBuildBlock =
    ^YPPAttributedStringBuilder *(YPPDynamicAttributedStringPropertyBuildBlock propertyBuidBlock) {
        __strong typeof(ws)self = ws;
        if (propertyBuidBlock) {
            YPPDynamicAttributedStringProperty *p = [YPPDynamicAttributedStringProperty new];
            p.builder = self;
            propertyBuidBlock(p);
            [self.buildPropertys addObject:p];
        }
        return self;
    };
    return attBuildBlock;
}


- (YPPAttributedStringBuilder *(^)(NSAttributedString *))append {
    __weak typeof(self)ws = self;
    return ^YPPAttributedStringBuilder *(NSAttributedString *attr) {
        __strong typeof(ws)self = ws;
        NSMutableAttributedString *mAttr = [self build].mutableCopy;
        [mAttr appendAttributedString:attr];
        return [[YPPAttributedStringBuilder alloc] initWithAttrDataSource:mAttr.copy];
    };
}



- (NSAttributedString *)build {
    if (self.dataSource && ![self.dataSource isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    if (self.attrDataSource && ![self.attrDataSource isKindOfClass:[NSAttributedString class]]) {
        return nil;
    }
    
    __block NSAttributedString *originalAttributedString = self.attrDataSource ?: [[NSAttributedString alloc] initWithString:self.dataSource];
    [self.buildPropertys enumerateObjectsUsingBlock:^(YPPAttributedStringProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            if ([obj isKindOfClass:[YPPStaticAttributedStringProperty class]]) {
                originalAttributedString = [self buildStaticAttributedStringFromAttributedString:originalAttributedString
                                                                    withAttributedStringProperty:(YPPStaticAttributedStringProperty *)obj];
            } else if ([obj isKindOfClass:[YPPDynamicAttributedStringProperty class]]) {
                originalAttributedString = [self buildDynamicAttributedStringFromAttributedString:originalAttributedString
                                                                     withAttributedStringProperty:(YPPDynamicAttributedStringProperty *)obj];
            }
        }
    }];
    
    NSAttributedString *finalAttributedString = originalAttributedString.copy;
    return finalAttributedString;
}

- (NSAttributedString *)buildStaticAttributedStringFromAttributedString:(NSAttributedString *)originalAttributeString
                                     withAttributedStringProperty:(YPPStaticAttributedStringProperty *)buildProperty {
    if (![originalAttributeString isKindOfClass:[NSAttributedString class]]) {
        return nil;
    }
    if (![buildProperty isKindOfClass:[YPPStaticAttributedStringProperty class]]) {
        return originalAttributeString;
    }
    
    YPPStaticAttributedStringProperty *prop = buildProperty;
    NSMutableAttributedString *mattr = [[NSMutableAttributedString alloc] initWithAttributedString:originalAttributeString];
    NSRange fullRange = NSMakeRange(0, mattr.length);
    if ((prop.value && prop.key) || prop.attributes) {
        NSDictionary *attributes = prop.attributes.copy ?: @{prop.key: prop.value};
        if (NSMaxRange(prop.range) > 0) {
            [mattr addAttributes:attributes range:prop.range];
        } else {
            [mattr addAttributes:attributes range:fullRange];
        }
    }
    
    NSAttributedString *attr = mattr.copy;
    return attr;
}

- (NSAttributedString *)buildDynamicAttributedStringFromAttributedString:(NSAttributedString *)originalAttributeString
                                     withAttributedStringProperty:(YPPDynamicAttributedStringProperty *)buildProperty {
    if (![originalAttributeString isKindOfClass:[NSAttributedString class]]) {
        return nil;
    }
    if (![buildProperty isKindOfClass:[YPPDynamicAttributedStringProperty class]]) {
        return originalAttributeString;
    }
    
    NSMutableAttributedString *mattr = [[NSMutableAttributedString alloc] initWithAttributedString:originalAttributeString];
    YPPDynamicAttributedStringProperty *prop = buildProperty;
    NSRegularExpression *regexp = prop.regexp;
    if (regexp) {
        NSRange effectRange = ((NSMaxRange(prop.range)) && NSMaxRange(prop.range) <= mattr.length) ? prop.range : NSMakeRange(0, mattr.length);
        NSArray <NSTextCheckingResult *> *results = [regexp matchesInString:mattr.string
                                                                    options:0
                                                                      range:effectRange];
        [results enumerateObjectsWithOptions:NSEnumerationReverse
                                  usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (prop.replace) {
                NSAttributedString *propAttr = prop.replace(obj, idx, mattr.string);
                if (propAttr) {
                    [mattr replaceCharactersInRange:obj.range withAttributedString:propAttr];
                }
            }
        }];
    }
  
    NSAttributedString *finalAttr = [mattr copy];
    return finalAttr;
}

@end

@implementation YPPAttributedStringProperty


@end

@implementation YPPStaticAttributedStringProperty
@end

@interface YPPDynamicAttributedStringProperty()
@property (nonatomic, strong) NSRegularExpression *regexp;
@end
@implementation YPPDynamicAttributedStringProperty

- (NSRegularExpression *)regexp {
    if (!self.regex) {
        return nil;
    }
    return _regexp ?: ({
        NSRegularExpressionOptions op = NSRegularExpressionCaseInsensitive;
        NSError *err = nil;
        NSString *unicode = self.regex;
        NSRegularExpression *regexp = [[NSRegularExpression alloc] initWithPattern:unicode options:op error:&err];
        if (err) {
            NSString *errDescription = [err description];
            NSAssert(nil, errDescription);
        }
        _regexp = regexp;
        regexp;
    });
}

@end
