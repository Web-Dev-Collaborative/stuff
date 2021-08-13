//
//  TRCTraceRecording.m
//  Tracer
//
//  Created by Ben Guo on 2/22/19.
//  Copyright © 2019 tracer. All rights reserved.
//

#import "TRCTrace+Private.h"
#import "TRCCall.h"
#import "NSDate+Tracer.h"
#import "NSDictionary+Tracer.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRCTrace ()

@property (atomic, strong, readwrite) NSDate *start;
@property (atomic, strong, readwrite) NSString *protocol;
@property (atomic, strong, readwrite) NSMutableArray<TRCCall*>*calls;

@end

@implementation TRCTrace

+ (nullable instancetype)loadFromJsonFile:(NSString *)filename bundle:(nonnull NSBundle *)bundle {
    NSData *data = [self dataFromJSONFile:filename bundle:bundle];
    NSDictionary *json;
    if (data != nil) {
        json = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)kNilOptions error:nil];
    }
    if (json != nil) {
        return [self decodedObjectFromJson:json];
    }
    return nil;
}

+ (nullable instancetype)decodedObjectFromJson:(nullable NSDictionary *)json {
    // precheck
    if (!json) {
        return nil;
    }
    NSDictionary *dict = [json trc_dictionaryByRemovingNulls];
    NSString *object = [dict trc_stringForKey:@"trace_object"];
    if (![object isEqualToString:@"trace"]) {
        return nil;
    }

    // props
    NSString *protocol = [dict trc_stringForKey:@"protocol"];
    NSNumber *startMs = [dict trc_numberForKey:@"start_ms"];
    NSArray *rawCalls = [dict trc_arrayForKey:@"calls"];
    if (!protocol || !startMs || !rawCalls) {
        return nil;
    }

    NSMutableArray *calls = [NSMutableArray new];
    for (NSDictionary *rawCall in rawCalls) {
        TRCCall *call = [TRCCall decodedObjectFromJson:rawCall];
        if (call != nil) {
            [calls addObject:call];
        }
    }

    // assemble
    TRCTrace *decoded = [TRCTrace new];
    decoded.protocol = protocol;
    decoded.start = [NSDate dateWithTimeIntervalSince1970:[startMs unsignedIntegerValue]];
    decoded.calls = [calls copy];
    return decoded;
}

- (instancetype)initWithProtocol:(Protocol *)protocol {
    self = [super init];
    if (self) {
        _start = [NSDate date];
        _protocol = NSStringFromProtocol(protocol);
        _calls = [NSMutableArray new];
    }
    return self;
}

- (void)addCall:(TRCCall *)call {
    [self.calls addObject:call];
}

- (NSUInteger)startMillis {
    return [self.start trc_millisSince1970];
}

- (NSString *)internalId {
    return [NSString stringWithFormat:@"%@_%lu", self.protocol, [self startMillis]];
}

- (NSObject *)jsonObject {
    NSMutableDictionary *json = [NSMutableDictionary new];
    json[@"trace_object"] = @"trace";
    json[@"protocol"] = self.protocol;
    json[@"start_ms"] = @([self startMillis]);
    NSMutableArray *calls = [NSMutableArray new];
    for (TRCCall *call in self.calls) {
        [calls addObject:[call jsonObject]];
    }
    json[@"calls"] = [calls copy];
    return [json copy];
}

+ (nullable NSData *)dataFromJSONFile:(NSString *)name bundle:(NSBundle *)bundle {
    NSString *path = [bundle pathForResource:name ofType:@"json"];
    if (!path) {
        return nil;
    }

    NSError *error = nil;
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!jsonString) {
        return nil;
    }

    // Strip all lines that begin with `//`
    NSMutableArray *jsonLines = [[NSMutableArray alloc] init];

    for (NSString *line in [jsonString componentsSeparatedByString:@"\n"]) {
        if (![line hasPrefix:@"//"]) {
            [jsonLines addObject:line];
        }
    }

    return [[jsonLines componentsJoinedByString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Details (alphabetical)
                       [NSString stringWithFormat:@"jsonObject = %@", [self jsonObject]],
                       ];
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

@end

NS_ASSUME_NONNULL_END
