//
//  YPPAsyncAttributedStringBuilder.h
//  YPPul_New
//
//  Created by Sam on 2020/9/17.
//  Copyright © 2020 YPPul. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifndef YPPAttr
#define YPPAttr(...) [[NSAttributedString alloc] initWithString:__VA_ARGS__]
#endif

@class YPPAttributedStringBuilder;
@class YPPStaticAttributedStringProperty;
@class YPPDynamicAttributedStringProperty;

typedef YPPAttributedStringBuilder YPPAB;
typedef YPPStaticAttributedStringProperty YPPSP;
typedef YPPDynamicAttributedStringProperty YPPDP;

typedef void (^YPPStaticAttributedStringPropertyBuildBlock)(YPPSP *p);
typedef void (^YPPDynamicAttributedStringPropertyBuildBlock)(YPPDP *p);
typedef YPPAB *_Nullable(^YPPAddAttributedBuildBlock)(YPPStaticAttributedStringPropertyBuildBlock propertyBuidBlock);
typedef YPPAB *_Nullable(^YPPReplaceAttributedBuildBlock)(YPPDynamicAttributedStringPropertyBuildBlock propertyBuidBlock);


@interface YPPAttributedStringProperty : NSObject
@property (nonatomic, weak) YPPAttributedStringBuilder *builder;
@property (nonatomic, assign) NSRange range;
@end

@interface YPPStaticAttributedStringProperty : YPPAttributedStringProperty
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) id value;
@property (nonatomic, strong) NSDictionary *attributes;

@end

@interface YPPDynamicAttributedStringProperty : YPPAttributedStringProperty
@property (nonatomic, copy) NSString *regex;
@property (nonatomic, readonly) NSRegularExpression *regexp;
@property (nonatomic, copy) NSAttributedString *(^replace)(NSTextCheckingResult *result, NSInteger index, NSString *processingString);
@end



@interface YPPAttributedStringBuilder : NSObject
- (instancetype)initWithDataSource:(NSString *)dataSource;
- (instancetype)initWithAttrDataSource:(NSAttributedString *)attrDataSource;
@property (nonatomic, readonly) NSString *dataSource;
@property (nonatomic, readonly) NSAttributedString *attrDataSource;

- (YPPAddAttributedBuildBlock)add;
- (YPPReplaceAttributedBuildBlock)every;
- (YPPAttributedStringBuilder *(^)(NSAttributedString *attr))append;
- (id _Nullable(^)(NSAttributedStringKey *key))any;

- (void)add:(YPPAttributedStringProperty *)property;
- ( NSAttributedString * _Nullable)build;
@end

